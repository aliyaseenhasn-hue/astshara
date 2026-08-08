-- Cleanup applied after the initial consultation migrations.
DROP POLICY IF EXISTS "bookings_select_participant" ON public.bookings;
DROP POLICY IF EXISTS "bookings_update_admin" ON public.bookings;
DROP POLICY IF EXISTS "bookings_delete_admin" ON public.bookings;
DROP POLICY IF EXISTS "bookings_insert_blocked" ON public.bookings;
DROP POLICY IF EXISTS "payments_update_admin" ON public.payments;
DROP POLICY IF EXISTS "payments_insert_blocked" ON public.payments;
DROP POLICY IF EXISTS "payments_select_participant_auth" ON public.payments;
DROP POLICY IF EXISTS "lawyer_profiles_select_authorized" ON public.lawyer_profiles;
DROP POLICY IF EXISTS "profiles_select_self_or_admin" ON public.profiles;
DROP POLICY IF EXISTS "reviews_update_own" ON public.reviews;
DROP POLICY IF EXISTS "availability_select_public" ON public.lawyer_availability_slots;
DROP POLICY IF EXISTS "availability_manage_lawyer" ON public.lawyer_availability_slots;

CREATE POLICY "availability_select_auth" ON public.lawyer_availability_slots FOR SELECT TO authenticated USING (
  is_available=true OR lawyer_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin())
);
CREATE POLICY "availability_manage_lawyer_auth" ON public.lawyer_availability_slots FOR ALL TO authenticated USING (
  lawyer_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin())
) WITH CHECK (
  lawyer_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin())
);
