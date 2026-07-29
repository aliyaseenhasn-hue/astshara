-- 1. تفعيل الإضافات اللازمة
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. تعريف الأنواع المخصصة (Enums)
CREATE TYPE user_role AS ENUM ('user', 'lawyer', 'admin', 'moderator');
CREATE TYPE account_status AS ENUM ('active', 'blocked', 'pending', 'deleted');

-- 3. إنشاء جدول البروفايل (Profiles)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role DEFAULT 'user',
    full_name TEXT,
    phone TEXT UNIQUE,
    email TEXT UNIQUE,
    avatar_url TEXT,
    city TEXT,
    is_verified BOOLEAN DEFAULT false,
    status account_status DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. إنشاء جدول بيانات المحامين (Lawyer Profiles)
CREATE TABLE public.lawyer_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    license_number TEXT UNIQUE,
    bio TEXT,
    years_experience INT,
    consultation_price DECIMAL(12,2),
    rating DECIMAL(3,2) DEFAULT 0,
    review_count INT DEFAULT 0,
    verified BOOLEAN DEFAULT false,
    availability BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 5. تفعيل RLS (Row Level Security)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_profiles ENABLE ROW LEVEL SECURITY;

-- 6. سياسات الأمان لجدول Profiles
CREATE POLICY "الكل يمكنه رؤية المحامين" ON public.profiles
    FOR SELECT USING (role = 'lawyer' OR auth.uid() = auth_id);

CREATE POLICY "المستخدم يمكنه تعديل بياناته فقط" ON public.profiles
    FOR UPDATE USING (auth.uid() = auth_id);

-- 7. وظيفة (Function) لإنشاء بروفايل تلقائياً عند التسجيل
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (auth_id, full_name, phone, email, role)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.phone,
    new.email,
    COALESCE((new.raw_user_meta_data->>'role')::user_role, 'user')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. جدول الحجوزات (Bookings)
CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id),
    lawyer_id UUID REFERENCES public.profiles(id),
    status TEXT DEFAULT 'pending',
    scheduled_at TIMESTAMPTZ,
    price DECIMAL(12,2),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. جدول المحادثات (Conversations)
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES public.bookings(id),
    user_id UUID REFERENCES public.profiles(id),
    lawyer_id UUID REFERENCES public.profiles(id),
    last_message TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 10. جدول الرسائل (Messages)
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES public.conversations(id),
    sender_id UUID REFERENCES public.profiles(id),
    content TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- تفعيل RLS للجداول الجديدة
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- سياسات الوصول للمحادثات (فقط أطراف المحادثة)
CREATE POLICY "الوصول للمحادثة لأطرافها فقط" ON public.conversations
    FOR ALL USING (auth.uid() IN (SELECT auth_id FROM public.profiles WHERE id = user_id OR id = lawyer_id));

CREATE POLICY "الوصول للرسائل لأطراف المحادثة" ON public.messages
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE id = conversation_id AND
            auth.uid() IN (SELECT auth_id FROM public.profiles WHERE id = user_id OR id = lawyer_id)
        )
    );
