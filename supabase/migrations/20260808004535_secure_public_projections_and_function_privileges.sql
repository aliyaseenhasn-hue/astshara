-- Applied to the linked Supabase project as migration 20260808004535.
-- Public projections contain no phone, WhatsApp, ID documents, booking IDs or user IDs.

CREATE TABLE IF NOT EXISTS public.public_lawyer_directory (
  profile_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  full_name TEXT, avatar_url TEXT, city TEXT, is_verified BOOLEAN NOT NULL DEFAULT false,
  bio TEXT, years_experience INTEGER, consultation_price NUMERIC, rating NUMERIC(3,2) NOT NULL DEFAULT 0,
  review_count INTEGER NOT NULL DEFAULT 0, availability BOOLEAN NOT NULL DEFAULT true,
  specialization TEXT[], services JSONB NOT NULL DEFAULT '[]'::jsonb, updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.public_lawyer_directory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_lawyer_directory_select" ON public.public_lawyer_directory;
CREATE POLICY "public_lawyer_directory_select" ON public.public_lawyer_directory FOR SELECT TO anon,authenticated USING (is_verified=true);
GRANT SELECT ON public.public_lawyer_directory TO anon,authenticated;

CREATE TABLE IF NOT EXISTS public.public_reviews (
  review_id UUID PRIMARY KEY REFERENCES public.reviews(id) ON DELETE CASCADE,
  lawyer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating NUMERIC(2,1) NOT NULL CHECK (rating>=1 AND rating<=5),
  comment TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.public_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_reviews_select" ON public.public_reviews;
CREATE POLICY "public_reviews_select" ON public.public_reviews FOR SELECT TO anon,authenticated USING (true);
GRANT SELECT ON public.public_reviews TO anon,authenticated;

DROP VIEW IF EXISTS public.public_profiles;
CREATE VIEW public.public_profiles WITH (security_invoker=true) AS
SELECT profile_id AS id,full_name,avatar_url,city,'lawyer'::user_role AS role,is_verified,bio,years_experience,consultation_price,rating,review_count,availability
FROM public.public_lawyer_directory WHERE is_verified=true;
DROP VIEW IF EXISTS public.public_lawyer_profiles;
CREATE VIEW public.public_lawyer_profiles WITH (security_invoker=true) AS
SELECT profile_id AS id,profile_id,full_name,avatar_url,NULL::text AS license_number,bio,specialization,years_experience,consultation_price,rating,review_count,is_verified AS verified,availability,services
FROM public.public_lawyer_directory WHERE is_verified=true;
GRANT SELECT ON public.public_profiles TO anon,authenticated;
GRANT SELECT ON public.public_lawyer_profiles TO anon,authenticated;

-- Internal trigger functions are not exposed through the Data API.
REVOKE ALL ON FUNCTION public.sync_booking_from_payment() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.track_completed_consultation() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.validate_review() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.update_lawyer_rating() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.sync_public_lawyer_directory() FROM PUBLIC,anon,authenticated;
