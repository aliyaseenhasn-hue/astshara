CREATE POLICY "payments_select_participant_auth" ON public.payments FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM public.bookings b WHERE b.id=payments.booking_id AND (
    b.user_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR
    b.lawyer_id IN (SELECT p.id FROM public.profiles p WHERE p.auth_id=(SELECT auth.uid())) OR (SELECT public.is_admin())
  ))
);
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
CREATE POLICY "profiles_insert_auth" ON public.profiles FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid())=auth_id);
DROP POLICY IF EXISTS "lawyer_profiles_insert" ON public.lawyer_profiles;
CREATE POLICY "lawyer_profiles_insert_auth" ON public.lawyer_profiles FOR INSERT TO authenticated WITH CHECK (((SELECT auth.uid())=public.get_profile_auth_id(profile_id)) OR (public.get_my_role() = ANY (ARRAY['admin'::user_role,'moderator'::user_role])));
