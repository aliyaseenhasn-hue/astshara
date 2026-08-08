-- Secure consultation booking lifecycle.
-- Applied to the linked Supabase project as migration 20260808004504.

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS package_name TEXT,
  ADD COLUMN IF NOT EXISTS package_description TEXT,
  ADD COLUMN IF NOT EXISTS package_duration_minutes INTEGER NOT NULL DEFAULT 30,
  ADD COLUMN IF NOT EXISTS consultation_status TEXT NOT NULL DEFAULT 'لم تبدأ',
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

ALTER TABLE public.lawyer_profiles
  ADD COLUMN IF NOT EXISTS completed_consultations INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES public.profiles(id);

ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_status_check;
UPDATE public.bookings SET status=CASE status WHEN 'pending' THEN 'قيد انتظار الدفع' WHEN 'accepted' THEN 'مؤكد' WHEN 'confirmed' THEN 'مؤكد' WHEN 'completed' THEN 'مكتمل' WHEN 'cancelled' THEN 'ملغي' WHEN 'rejected' THEN 'ملغي' ELSE 'قيد انتظار الدفع' END;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_status_check CHECK (status = ANY (ARRAY['قيد انتظار الدفع','بانتظار التأكيد','مؤكد','قيد التنفيذ','مكتمل','ملغي','مسترد']));

ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_status_check;
UPDATE public.payments SET status=CASE status WHEN 'pending' THEN 'قيد معالجة الدفع' WHEN 'paid' THEN 'تم الدفع' WHEN 'failed' THEN 'فشل الدفع' WHEN 'rejected' THEN 'فشل الدفع' WHEN 'refunded' THEN 'تم استرداد المبلغ' ELSE 'قيد معالجة الدفع' END;
ALTER TABLE public.payments ADD CONSTRAINT payments_status_check CHECK (status = ANY (ARRAY['بانتظار الدفع','قيد معالجة الدفع','تم الدفع','فشل الدفع','تم استرداد المبلغ']));

ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS reviews_rating_check;
ALTER TABLE public.reviews ADD CONSTRAINT reviews_rating_check CHECK (rating >= 1 AND rating <= 5);
CREATE UNIQUE INDEX IF NOT EXISTS ux_reviews_booking_id ON public.reviews(booking_id);
CREATE INDEX IF NOT EXISTS idx_bookings_lawyer_scheduled_at ON public.bookings(lawyer_id, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_bookings_consultation_status ON public.bookings(consultation_status);
CREATE INDEX IF NOT EXISTS idx_bookings_user_status ON public.bookings(user_id, status);
CREATE INDEX IF NOT EXISTS idx_payments_booking_status ON public.payments(booking_id, status);

CREATE TABLE IF NOT EXISTS public.lawyer_availability_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lawyer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  is_available BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT availability_slot_time_check CHECK (ends_at > starts_at),
  CONSTRAINT availability_slot_min_duration_check CHECK (ends_at - starts_at >= interval '15 minutes'),
  UNIQUE (lawyer_id, starts_at)
);
ALTER TABLE public.lawyer_availability_slots ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_availability_lawyer_starts ON public.lawyer_availability_slots(lawyer_id, starts_at);

-- Booking creation is server-authoritative: price, duration and package are read from the verified professional profile.
CREATE OR REPLACE FUNCTION public.create_booking(p_lawyer_id uuid,p_scheduled_at timestamptz,p_package_name text,p_consultation_type text,p_description text DEFAULT NULL,p_document_url text DEFAULT NULL,p_client_whatsapp text DEFAULT NULL)
RETURNS public.bookings LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_user_id uuid; v_package jsonb; v_booking public.bookings; v_price numeric; v_duration integer; v_description text; v_methods jsonb; v_locked_lawyer uuid;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول أولاً'; END IF;
  SELECT id INTO v_user_id FROM public.profiles WHERE auth_id=(SELECT auth.uid());
  SELECT profile_id INTO v_locked_lawyer FROM public.lawyer_profiles WHERE profile_id=p_lawyer_id FOR UPDATE;
  IF v_user_id IS NULL OR v_locked_lawyer IS NULL THEN RAISE EXCEPTION 'بيانات الحجز غير مكتملة'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.lawyer_profiles WHERE profile_id=p_lawyer_id AND verified=true AND availability=true) THEN RAISE EXCEPTION 'المهني غير متاح للحجز حالياً'; END IF;
  SELECT elem INTO v_package FROM public.lawyer_profiles lp,LATERAL jsonb_array_elements(COALESCE(lp.services,'[]'::jsonb)) elem WHERE lp.profile_id=p_lawyer_id AND lower(COALESCE(elem->>'title',''))=lower(trim(p_package_name)) LIMIT 1;
  IF v_package IS NULL THEN RAISE EXCEPTION 'الباقة المحددة غير متاحة'; END IF;
  v_price:=NULLIF(v_package->>'price','')::numeric; v_duration:=COALESCE(NULLIF(v_package->>'duration_minutes','')::integer,30); v_description:=v_package->>'description'; v_methods:=v_package->'consultation_types';
  IF v_price IS NULL OR v_price<=0 THEN RAISE EXCEPTION 'سعر الباقة غير صالح'; END IF;
  IF p_consultation_type NOT IN('نصية','صوتية','فيديو') THEN RAISE EXCEPTION 'نوع الاستشارة غير صالح'; END IF;
  IF jsonb_typeof(v_methods)='array' AND NOT(v_methods ? p_consultation_type) THEN RAISE EXCEPTION 'نوع الاستشارة غير متاح لهذه الباقة'; END IF;
  IF p_scheduled_at<=now() THEN RAISE EXCEPTION 'الموعد يجب أن يكون في المستقبل'; END IF;
  IF EXISTS(SELECT 1 FROM public.bookings b WHERE b.lawyer_id=p_lawyer_id AND b.scheduled_at=p_scheduled_at AND b.status NOT IN('ملغي','مسترد')) THEN RAISE EXCEPTION 'عذراً، هذا الموعد لم يعد متاحاً'; END IF;
  INSERT INTO public.bookings(user_id,lawyer_id,status,scheduled_at,price,consultation_type,description,document_url,whatsapp_number,package_name,package_description,package_duration_minutes,consultation_status)
  VALUES(v_user_id,p_lawyer_id,'قيد انتظار الدفع',p_scheduled_at,v_price,p_consultation_type,NULLIF(trim(p_description),''),p_document_url,NULLIF(trim(p_client_whatsapp),''),trim(p_package_name),v_description,v_duration,'لم تبدأ') RETURNING * INTO v_booking;
  RETURN v_booking;
END; $$;
REVOKE ALL ON FUNCTION public.create_booking(uuid,timestamptz,text,text,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_booking(uuid,timestamptz,text,text,text,text,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.submit_payment(p_booking_id uuid,p_payment_method text,p_transaction_number text,p_receipt_url text DEFAULT NULL)
RETURNS public.payments LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_user_id uuid; v_booking public.bookings; v_payment public.payments;
BEGIN
  SELECT p.id INTO v_user_id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid());
  SELECT * INTO v_booking FROM public.bookings WHERE id=p_booking_id AND user_id=v_user_id FOR UPDATE;
  IF NOT FOUND OR v_booking.status<>'قيد انتظار الدفع' THEN RAISE EXCEPTION 'لا يمكن إرسال الدفع لهذا الحجز حالياً'; END IF;
  IF NULLIF(trim(p_transaction_number),'') IS NULL THEN RAISE EXCEPTION 'رقم العملية مطلوب'; END IF;
  INSERT INTO public.payments(booking_id,amount,payment_method,transaction_number,receipt_url,status) VALUES(v_booking.id,v_booking.price,p_payment_method,trim(p_transaction_number),p_receipt_url,'قيد معالجة الدفع') RETURNING * INTO v_payment;
  UPDATE public.bookings SET status='بانتظار التأكيد' WHERE id=v_booking.id;
  RETURN v_payment;
END; $$;
REVOKE ALL ON FUNCTION public.submit_payment(uuid,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.submit_payment(uuid,text,text,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.change_booking_status(p_booking_id uuid,p_new_status text)
RETURNS public.bookings LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_profile_id uuid; v_booking public.bookings; v_is_admin boolean=(SELECT public.is_admin());
BEGIN
  SELECT id INTO v_profile_id FROM public.profiles WHERE auth_id=(SELECT auth.uid());
  SELECT * INTO v_booking FROM public.bookings WHERE id=p_booking_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'الحجز غير موجود'; END IF;
  IF v_is_admin THEN NULL;
  ELSIF v_booking.user_id=v_profile_id AND p_new_status='ملغي' AND v_booking.status IN('قيد انتظار الدفع','بانتظار التأكيد','مؤكد') THEN NULL;
  ELSIF v_booking.lawyer_id=v_profile_id AND p_new_status IN('قيد التنفيذ','مكتمل','ملغي') THEN
    IF p_new_status='قيد التنفيذ' AND NOT(v_booking.status='مؤكد' AND v_booking.consultation_status='لم تبدأ') THEN RAISE EXCEPTION 'لا يمكن بدء الاستشارة في حالتها الحالية'; END IF;
    IF p_new_status='مكتمل' AND NOT(v_booking.status='قيد التنفيذ' AND v_booking.consultation_status='قيد التنفيذ') THEN RAISE EXCEPTION 'لا يمكن إنهاء الاستشارة في حالتها الحالية'; END IF;
  ELSE RAISE EXCEPTION 'غير مصرح بهذا الإجراء'; END IF;
  UPDATE public.bookings SET status=p_new_status,consultation_status=CASE WHEN p_new_status='قيد التنفيذ' THEN 'قيد التنفيذ' WHEN p_new_status='مكتمل' THEN 'انتهت' WHEN p_new_status='ملغي' AND status='قيد التنفيذ' THEN 'أُلغيت' ELSE consultation_status END WHERE id=p_booking_id RETURNING * INTO v_booking;
  RETURN v_booking;
END; $$;
REVOKE ALL ON FUNCTION public.change_booking_status(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.change_booking_status(uuid,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_booking_contact(p_booking_id uuid) RETURNS TABLE(phone text,whatsapp text) LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
SELECT p.phone,lp.whatsapp FROM public.bookings b JOIN public.profiles viewer ON viewer.id=b.user_id JOIN public.profiles p ON p.id=b.lawyer_id JOIN public.lawyer_profiles lp ON lp.profile_id=b.lawyer_id WHERE b.id=p_booking_id AND viewer.auth_id=(SELECT auth.uid()) AND b.status IN('مؤكد','قيد التنفيذ','مكتمل') AND EXISTS(SELECT 1 FROM public.payments pay WHERE pay.booking_id=b.id AND pay.status='تم الدفع') AND b.status NOT IN('ملغي','مسترد'); $$;
REVOKE ALL ON FUNCTION public.get_booking_contact(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_booking_contact(uuid) TO authenticated;
