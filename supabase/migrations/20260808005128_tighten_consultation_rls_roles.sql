-- Applied to the linked Supabase project as migration 20260808005128.
-- All consultation-related direct table policies are restricted to authenticated users.

DROP POLICY IF EXISTS "bookings_select" ON public.bookings;
DROP POLICY IF EXISTS "bookings_delete" ON public.bookings;
DROP POLICY IF EXISTS "bookings_update" ON public.bookings;
DROP POLICY IF EXISTS "bookings_insert" ON public.bookings;
CREATE POLICY "bookings_select_participant_auth" ON public.bookings FOR SELECT TO authenticated USING (
  user_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR
  lawyer_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin())
);
CREATE POLICY "bookings_update_admin_auth" ON public.bookings FOR UPDATE TO authenticated USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY "bookings_delete_admin_auth" ON public.bookings FOR DELETE TO authenticated USING ((SELECT public.is_admin()));
CREATE POLICY "bookings_insert_blocked_auth" ON public.bookings FOR INSERT TO authenticated WITH CHECK (false);

DROP POLICY IF EXISTS "payments_select" ON public.payments;
DROP POLICY IF EXISTS "payments_update" ON public.payments;
DROP POLICY IF EXISTS "payments_insert" ON public.payments;
CREATE POLICY "payments_select_participant_auth" ON public.payments FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.bookings b WHERE b.id=payments.booking_id AND (b.user_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR b.lawyer_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin()))));
CREATE POLICY "payments_update_admin_auth" ON public.payments FOR UPDATE TO authenticated USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY "payments_insert_blocked_auth" ON public.payments FOR INSERT TO authenticated WITH CHECK (false);

DROP POLICY IF EXISTS "الجميع يمكنهم رؤية التقييمات" ON public.reviews;
DROP POLICY IF EXISTS "reviews_delete" ON public.reviews;
CREATE POLICY "reviews_public_read_auth" ON public.reviews FOR SELECT TO authenticated USING (true);
CREATE POLICY "reviews_delete_own_or_admin_auth" ON public.reviews FOR DELETE TO authenticated USING (user_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin()));
