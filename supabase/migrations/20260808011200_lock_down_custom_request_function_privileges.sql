REVOKE EXECUTE ON FUNCTION public.create_custom_consultation_request(uuid,text,text,text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.set_custom_request_updated_at() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.change_custom_consultation_request_status(uuid,text) FROM anon;
