create or replace function public.get_booking_client_name(p_booking_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_profile_id uuid;
  v_booking public.bookings%rowtype;
  v_name text;
begin
  if auth.uid() is null then
    raise exception 'يجب تسجيل الدخول أولاً';
  end if;

  select id into v_profile_id
  from public.profiles
  where auth_id = auth.uid()
  limit 1;

  if v_profile_id is null then
    raise exception 'ملف المستخدم غير مكتمل';
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id
    and (user_id = v_profile_id or lawyer_id = v_profile_id or public.is_admin());

  if not found then
    raise exception 'غير مصرح بهذا الحجز';
  end if;

  select nullif(trim(full_name), '') into v_name
  from public.profiles
  where id = v_booking.user_id;

  return v_name;
end;
$function$;

grant execute on function public.get_booking_client_name(uuid) to authenticated;
revoke execute on function public.get_booking_client_name(uuid) from anon;
