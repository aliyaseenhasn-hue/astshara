CREATE OR REPLACE FUNCTION public.get_booking_client_name(p_booking_id uuid)
RETURNS TABLE(full_name text)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO ''
AS $$
  SELECT p.full_name
  FROM public.bookings b
  JOIN public.profiles p ON p.id = b.user_id
  JOIN public.profiles actor ON actor.auth_id = auth.uid()
  WHERE b.id = p_booking_id
    AND (actor.id = b.lawyer_id OR actor.id = b.user_id OR public.is_admin())
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_booking_client_name(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_booking_client_name(uuid) TO authenticated;
