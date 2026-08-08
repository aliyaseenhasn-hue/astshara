DROP POLICY IF EXISTS availability_manage_lawyer_auth ON public.lawyer_availability_slots;
CREATE POLICY availability_insert_lawyer ON public.lawyer_availability_slots FOR INSERT TO authenticated WITH CHECK (lawyer_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin()));
CREATE POLICY availability_update_lawyer ON public.lawyer_availability_slots FOR UPDATE TO authenticated USING (lawyer_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin())) WITH CHECK (lawyer_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin()));
CREATE POLICY availability_delete_lawyer ON public.lawyer_availability_slots FOR DELETE TO authenticated USING (lawyer_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS custom_requests_select_participant ON public.custom_consultation_requests;
CREATE POLICY custom_requests_select_participant ON public.custom_consultation_requests FOR SELECT TO authenticated USING (user_id IN (SELECT id FROM public.profiles WHERE auth_id=(SELECT auth.uid())) OR lawyer_id IN (SELECT id FROM public.profiles WHERE auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin()));
DROP POLICY IF EXISTS custom_requests_insert_own ON public.custom_consultation_requests;
CREATE POLICY custom_requests_insert_own ON public.custom_consultation_requests FOR INSERT TO authenticated WITH CHECK (user_id IN (SELECT id FROM public.profiles WHERE auth_id=(SELECT auth.uid())));

CREATE INDEX IF NOT EXISTS idx_payments_verified_by ON public.payments(verified_by);
CREATE INDEX IF NOT EXISTS idx_public_reviews_lawyer_id ON public.public_reviews(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_specialization_requests_lawyer_id ON public.specialization_change_requests(lawyer_id);
