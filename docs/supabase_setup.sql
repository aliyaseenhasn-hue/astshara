-- ==========================================
-- 📚 LawConnect (استشارة) - COMPLETE DATABASE SETUP
-- Version: 3.0 (Final Production Edition)
-- ==========================================

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Enums
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('user', 'lawyer', 'admin');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- 3. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY, -- Linked to auth.users.id
    auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    role user_role DEFAULT 'user',
    full_name TEXT,
    phone TEXT UNIQUE,
    email TEXT UNIQUE,
    avatar_url TEXT,
    onboarding_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Lawyer Profiles Table
CREATE TABLE IF NOT EXISTS public.lawyer_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    license_number TEXT,
    bio TEXT,
    specialization TEXT, -- تخصص المحامي
    years_experience INT DEFAULT 0,
    consultation_price DECIMAL(12,2) DEFAULT 0,
    whatsapp TEXT,
    id_card_url TEXT,
    rating DECIMAL(3,2) DEFAULT 0,
    review_count INT DEFAULT 0, -- إجمالي عدد التقييمات
    verified BOOLEAN DEFAULT false,
    availability BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lawyer_profiles_specialization ON public.lawyer_profiles(specialization);

-- 5. Bookings Table
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    lawyer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending', -- pending, confirmed, completed, cancelled
    scheduled_at TIMESTAMPTZ,
    price DECIMAL(12,2),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Payments Table
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    amount DECIMAL(12,2),
    payment_method TEXT,
    transaction_number TEXT,
    receipt_url TEXT,
    status TEXT DEFAULT 'pending', -- pending, verified, rejected
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. Messaging System
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id),
    lawyer_id UUID REFERENCES public.profiles(id),
    last_message TEXT,
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles(id),
    content TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT,
    body TEXT,
    type TEXT, -- info, booking, payment, chat
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 8.1 Reviews Table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    lawyer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating DECIMAL(2,1) NOT NULL CHECK (rating >= 0 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. Functions & Triggers
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, auth_id, full_name, phone, email, role)
  VALUES (
    new.id, 
    new.id, 
    COALESCE(new.raw_user_meta_data->>'full_name', 'مستخدم جديد'),
    new.phone,
    new.email,
    'user'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
    updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
DECLARE
  admin_role boolean;
BEGIN
  SELECT (role = 'admin') INTO admin_role 
  FROM public.profiles 
  WHERE id = auth.uid();
  
  RETURN COALESCE(admin_role, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة حذف حساب المستخدم نهائياً
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  DELETE FROM auth.users WHERE id = uid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- دالة تحديث تقييم المحامي تلقائياً عند إضافة تقييم جديد
CREATE OR REPLACE FUNCTION update_lawyer_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE lawyer_profiles
  SET
    rating = (
      SELECT ROUND(AVG(rating)::numeric, 2)
      FROM reviews
      WHERE lawyer_id = NEW.lawyer_id
    ),
    review_count = (
      SELECT COUNT(*)
      FROM reviews
      WHERE lawyer_id = NEW.lawyer_id
    )
  WHERE profile_id = NEW.lawyer_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_review_added ON public.reviews;
CREATE TRIGGER on_review_added
  AFTER INSERT ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION update_lawyer_rating();

-- 10. Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Policies for Profiles
DROP POLICY IF EXISTS "Public Lawyers" ON public.profiles;
CREATE POLICY "Public Lawyers" ON public.profiles FOR SELECT USING (role = 'lawyer' OR auth.uid() = id OR auth.uid() = auth_id OR is_admin());
DROP POLICY IF EXISTS "Self Manage" ON public.profiles;
CREATE POLICY "Self Manage" ON public.profiles FOR ALL USING (auth.uid() = id OR auth.uid() = auth_id);

-- Policies for Lawyer Profiles
-- العملاء يرون المحامين الموثقين فقط، والمحامي يرى ملفه، والأدمن يرى الكل
DROP POLICY IF EXISTS "View Verified Lawyers" ON public.lawyer_profiles;
CREATE POLICY "View Verified Lawyers" ON public.lawyer_profiles FOR SELECT USING (
    verified = true OR auth.uid() = profile_id OR is_admin()
);
DROP POLICY IF EXISTS "Manage Own Lawyer Profile" ON public.lawyer_profiles;
CREATE POLICY "Manage Own Lawyer Profile" ON public.lawyer_profiles FOR ALL USING (auth.uid() = profile_id);
DROP POLICY IF EXISTS "Admin Manage All" ON public.lawyer_profiles;
CREATE POLICY "Admin Manage All" ON public.lawyer_profiles FOR ALL USING (is_admin());

-- Policies for Bookings
DROP POLICY IF EXISTS "Access Own Bookings" ON public.bookings;
CREATE POLICY "Access Own Bookings" ON public.bookings 
FOR ALL USING (
  (user_id = (SELECT id FROM public.profiles WHERE id = auth.uid() LIMIT 1)) OR
  (lawyer_id = (SELECT id FROM public.profiles WHERE id = auth.uid() LIMIT 1)) OR
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Policies for Reviews
DROP POLICY IF EXISTS "View Reviews" ON public.reviews;
CREATE POLICY "View Reviews" ON public.reviews FOR SELECT USING (true);
DROP POLICY IF EXISTS "Insert Own Review" ON public.reviews;
CREATE POLICY "Insert Own Review" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Manage Own Review" ON public.reviews;
CREATE POLICY "Manage Own Review" ON public.reviews FOR UPDATE USING (auth.uid() = user_id);

-- Storage Buckets & Policies
-- Create buckets if not exist (Run this in Supabase Storage UI or via RPC)
-- Policy: Anyone logged in can upload to their own folder in avatars, lawyer_documents, receipts
DROP POLICY IF EXISTS "Storage Upload Policy" ON storage.objects;
CREATE POLICY "Storage Upload Policy" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id IN ('avatars', 'lawyer_documents', 'receipts')
    AND (auth.uid()::text = (storage.foldername(name))[1])
);
-- فقط المالك أو الأدمن يمكنهم رؤية الملفات
DROP POLICY IF EXISTS "Storage View Policy" ON storage.objects;
CREATE POLICY "Storage View Policy" ON storage.objects FOR SELECT USING (
    auth.uid()::text = (storage.foldername(name))[1] OR is_admin()
);

-- 11. Performance Indexes (v3.1)
-- تم إضافة الفهارس لتحسين أداء الاستعلامات
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_auth_id ON public.profiles(auth_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_lawyer_id ON public.bookings(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_lawyer_profiles_profile_id ON public.lawyer_profiles(profile_id);
CREATE INDEX IF NOT EXISTS idx_lawyer_profiles_verified ON public.lawyer_profiles(verified);

-- 12. Additional Columns (v3.1)
-- إضافة عمود الاسم الكامل لجدول محامي
ALTER TABLE public.lawyer_profiles
ADD COLUMN IF NOT EXISTS full_name TEXT;
