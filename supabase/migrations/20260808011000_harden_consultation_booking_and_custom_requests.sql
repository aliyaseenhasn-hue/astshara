-- Production hardening for consultation booking and custom requests.

CREATE OR REPLACE FUNCTION public.create_booking(
  p_lawyer_id uuid,
  p_scheduled_at timestamptz,
  p_package_name text,
  p_consultation_type text,
  p_description text DEFAULT NULL,
  p_document_url text DEFAULT NULL,
  p_client_whatsapp text DEFAULT NULL
)
RETURNS public.bookings
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
  v_user_id uuid;
  v_package jsonb;
  v_booking public.bookings;
  v_price numeric;
  v_duration integer;
  v_description text;
  v_methods jsonb;
  v_slot_id uuid;
  v_lawyer_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول أولاً'; END IF;
  SELECT id INTO v_user_id FROM public.profiles WHERE auth_id = auth.uid();
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'ملف المستخدم غير مكتمل'; END IF;

  SELECT profile_id INTO v_lawyer_id FROM public.lawyer_profiles
  WHERE profile_id = p_lawyer_id FOR UPDATE;
  IF v_lawyer_id IS NULL THEN RAISE EXCEPTION 'المهني غير موجود'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.lawyer_profiles WHERE profile_id=p_lawyer_id AND verified=true AND availability=true) THEN
    RAISE EXCEPTION 'المهني غير متاح للحجز حالياً';
  END IF;

  SELECT id INTO v_slot_id FROM public.lawyer_availability_slots
  WHERE lawyer_id=p_lawyer_id AND starts_at=p_scheduled_at AND is_available=true FOR UPDATE;
  IF v_slot_id IS NULL THEN RAISE EXCEPTION 'عذراً، هذا الموعد لم يعد متاحاً'; END IF;

  SELECT elem INTO v_package
  FROM public.lawyer_profiles lp, LATERAL jsonb_array_elements(COALESCE(lp.services,'[]'::jsonb)) elem
  WHERE lp.profile_id=p_lawyer_id AND lower(COALESCE(elem->>'title',''))=lower(trim(p_package_name)) LIMIT 1;
  IF v_package IS NULL THEN RAISE EXCEPTION 'الباقة المحددة غير متاحة'; END IF;

  v_price := NULLIF(v_package->>'price','')::numeric;
  v_duration := COALESCE(NULLIF(v_package->>'duration_minutes','')::integer,30);
  v_description := v_package->>'description';
  v_methods := v_package->'consultation_types';
  IF v_price IS NULL OR v_price<=0 THEN RAISE EXCEPTION 'سعر الباقة غير صالح'; END IF;
  IF p_consultation_type NOT IN ('نصية','صوتية','فيديو') THEN RAISE EXCEPTION 'نوع الاستشارة غير صالح'; END IF;
  IF jsonb_typeof(v_methods)='array' AND NOT (v_methods ? p_consultation_type) THEN RAISE EXCEPTION 'نوع الاستشارة غير متاح لهذه الباقة'; END IF;
  IF p_scheduled_at<=now() THEN RAISE EXCEPTION 'الموعد يجب أن يكون في المستقبل'; END IF;
  IF EXISTS (SELECT 1 FROM public.bookings b WHERE b.lawyer_id=p_lawyer_id AND b.scheduled_at=p_scheduled_at AND b.status NOT IN ('ملغي','مسترد')) THEN
    RAISE EXCEPTION 'عذراً، هذا الموعد لم يعد متاحاً';
  END IF;

  INSERT INTO public.bookings(user_id,lawyer_id,status,scheduled_at,price,consultation_type,description,document_url,whatsapp_number,package_name,package_description,package_duration_minutes,consultation_status)
  VALUES(v_user_id,p_lawyer_id,'قيد انتظار الدفع',p_scheduled_at,v_price,p_consultation_type,NULLIF(trim(p_description),''),p_document_url,NULLIF(trim(p_client_whatsapp),''),trim(p_package_name),v_description,v_duration,'لم تبدأ')
  RETURNING * INTO v_booking;
  RETURN v_booking;
END;
$$;

CREATE OR REPLACE FUNCTION public.change_booking_status(p_booking_id uuid,p_new_status text)
RETURNS public.bookings
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
  v_actor uuid:=auth.uid(); v_profile_id uuid; v_booking public.bookings; v_is_admin boolean:=public.is_admin(); v_is_paid boolean;
BEGIN
  IF v_actor IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول أولاً'; END IF;
  IF p_new_status NOT IN ('قيد انتظار الدفع','بانتظار التأكيد','مؤكد','قيد التنفيذ','مكتمل','ملغي','مسترد') THEN RAISE EXCEPTION 'حالة الحجز غير صالحة'; END IF;
  SELECT id INTO v_profile_id FROM public.profiles WHERE auth_id=v_actor;
  SELECT * INTO v_booking FROM public.bookings WHERE id=p_booking_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'الحجز غير موجود'; END IF;
  SELECT EXISTS(SELECT 1 FROM public.payments WHERE booking_id=v_booking.id AND status='تم الدفع') INTO v_is_paid;

  IF v_is_admin THEN NULL;
  ELSIF v_booking.user_id=v_profile_id AND p_new_status='ملغي' AND v_booking.status IN ('قيد انتظار الدفع','بانتظار التأكيد','مؤكد') THEN NULL;
  ELSIF v_booking.lawyer_id=v_profile_id AND p_new_status='قيد التنفيذ' THEN
    IF v_booking.status<>'مؤكد' OR NOT v_is_paid OR v_booking.consultation_status<>'لم تبدأ' THEN RAISE EXCEPTION 'لا يمكن بدء الاستشارة قبل تأكيد الدفع والحجز'; END IF;
  ELSIF v_booking.lawyer_id=v_profile_id AND p_new_status='مكتمل' THEN
    IF v_booking.status<>'قيد التنفيذ' OR v_booking.consultation_status<>'قيد التنفيذ' THEN RAISE EXCEPTION 'لا يمكن إنهاء الاستشارة في حالتها الحالية'; END IF;
  ELSIF v_booking.lawyer_id=v_profile_id AND p_new_status='ملغي' AND v_booking.status IN ('بانتظار التأكيد','مؤكد','قيد التنفيذ') THEN NULL;
  ELSE RAISE EXCEPTION 'غير مصرح بهذا الإجراء'; END IF;

  UPDATE public.bookings SET status=p_new_status,
    consultation_status=CASE
      WHEN p_new_status='قيد التنفيذ' THEN 'قيد التنفيذ'
      WHEN p_new_status='مكتمل' THEN 'انتهت'
      WHEN p_new_status='ملغي' AND status='قيد التنفيذ' THEN 'أُلغيت'
      ELSE consultation_status END
  WHERE id=p_booking_id RETURNING * INTO v_booking;
  RETURN v_booking;
END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_payments_one_active_per_booking
ON public.payments(booking_id) WHERE status IN ('قيد معالجة الدفع','تم الدفع');

CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  UPDATE public.conversations SET last_message=NEW.content,last_message_at=NEW.created_at WHERE id=NEW.conversation_id;
  RETURN NEW;
END; $$;

CREATE TABLE IF NOT EXISTS public.custom_consultation_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  lawyer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject text NOT NULL CHECK(length(trim(subject)) BETWEEN 3 AND 200),
  description text NOT NULL CHECK(length(trim(description)) BETWEEN 10 AND 5000),
  consultation_type text NOT NULL CHECK(consultation_type IN ('نصية','صوتية','فيديو')),
  status text NOT NULL DEFAULT 'جديد' CHECK(status IN ('جديد','قيد المراجعة','مقبول','مرفوض','ملغي','مكتمل')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_custom_requests_user ON public.custom_consultation_requests(user_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_custom_requests_lawyer ON public.custom_consultation_requests(lawyer_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_custom_requests_status ON public.custom_consultation_requests(status);
ALTER TABLE public.custom_consultation_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS custom_requests_select_participant ON public.custom_consultation_requests;
CREATE POLICY custom_requests_select_participant ON public.custom_consultation_requests FOR SELECT TO authenticated USING(user_id IN(SELECT id FROM public.profiles WHERE auth_id=auth.uid()) OR lawyer_id IN(SELECT id FROM public.profiles WHERE auth_id=auth.uid()) OR public.is_admin());
DROP POLICY IF EXISTS custom_requests_insert_own ON public.custom_consultation_requests;
CREATE POLICY custom_requests_insert_own ON public.custom_consultation_requests FOR INSERT TO authenticated WITH CHECK(user_id IN(SELECT id FROM public.profiles WHERE auth_id=auth.uid()));
DROP POLICY IF EXISTS custom_requests_update_participant ON public.custom_consultation_requests;

CREATE OR REPLACE FUNCTION public.create_custom_consultation_request(p_lawyer_id uuid,p_subject text,p_description text,p_consultation_type text)
RETURNS public.custom_consultation_requests LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_user_id uuid; v_request public.custom_consultation_requests;
BEGIN
  SELECT id INTO v_user_id FROM public.profiles WHERE auth_id=auth.uid();
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'ملف المستخدم غير مكتمل'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.lawyer_profiles WHERE profile_id=p_lawyer_id AND verified=true AND availability=true) THEN RAISE EXCEPTION 'المهني غير متاح حالياً'; END IF;
  IF p_consultation_type NOT IN('نصية','صوتية','فيديو') THEN RAISE EXCEPTION 'نوع الاستشارة غير صالح'; END IF;
  INSERT INTO public.custom_consultation_requests(user_id,lawyer_id,subject,description,consultation_type) VALUES(v_user_id,p_lawyer_id,trim(p_subject),trim(p_description),p_consultation_type) RETURNING * INTO v_request;
  RETURN v_request;
END; $$;
REVOKE ALL ON FUNCTION public.create_custom_consultation_request(uuid,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_custom_consultation_request(uuid,text,text,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.change_custom_consultation_request_status(p_request_id uuid,p_new_status text)
RETURNS public.custom_consultation_requests LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_actor_profile uuid; v_request public.custom_consultation_requests;
BEGIN
  SELECT id INTO v_actor_profile FROM public.profiles WHERE auth_id=auth.uid();
  IF v_actor_profile IS NULL THEN RAISE EXCEPTION 'ملف المستخدم غير مكتمل'; END IF;
  IF p_new_status NOT IN('جديد','قيد المراجعة','مقبول','مرفوض','ملغي','مكتمل') THEN RAISE EXCEPTION 'حالة الطلب غير صالحة'; END IF;
  SELECT * INTO v_request FROM public.custom_consultation_requests WHERE id=p_request_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'الطلب غير موجود'; END IF;
  IF NOT public.is_admin() AND v_request.lawyer_id<>v_actor_profile THEN RAISE EXCEPTION 'غير مصرح بهذا الإجراء'; END IF;
  UPDATE public.custom_consultation_requests SET status=p_new_status WHERE id=p_request_id RETURNING * INTO v_request;
  RETURN v_request;
END; $$;
REVOKE ALL ON FUNCTION public.change_custom_consultation_request_status(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.change_custom_consultation_request_status(uuid,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.set_custom_request_updated_at()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$ BEGIN NEW.updated_at:=now(); RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS custom_request_updated_at ON public.custom_consultation_requests;
CREATE TRIGGER custom_request_updated_at BEFORE UPDATE ON public.custom_consultation_requests FOR EACH ROW EXECUTE FUNCTION public.set_custom_request_updated_at();

REVOKE ALL ON FUNCTION public.create_booking(uuid,timestamptz,text,text,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_booking(uuid,timestamptz,text,text,text,text,text) TO authenticated;
REVOKE ALL ON FUNCTION public.change_booking_status(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.change_booking_status(uuid,text) TO authenticated;
REVOKE ALL ON FUNCTION public.get_booking_contact(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_booking_contact(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.submit_payment(uuid,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.submit_payment(uuid,text,text,text) TO authenticated;
