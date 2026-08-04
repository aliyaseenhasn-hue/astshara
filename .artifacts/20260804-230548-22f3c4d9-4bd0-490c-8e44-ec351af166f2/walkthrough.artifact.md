# ملخص إصلاح تسجيل دخول جوجل

تم الانتهاء من تحديث إعدادات التطبيق لتمكين تسجيل الدخول عبر جوجل بشكل صحيح.

## التغييرات التي تمت:

1.  **في الأندرويد ([AndroidManifest.xml](file:///C:/Allmyprojects/astshara/android/app/src/main/AndroidManifest.xml)):**
    *   تمت إضافة `intent-filter` للتعامل مع رابط إعادة التوجيه `io.supabase.astshara://login-callback`. هذا يسمح للنظام بفتح التطبيق تلقائياً عند انتهاء عملية المصادقة في المتصفح.

2.  **في iOS ([Info.plist](file:///C:/Allmyprojects/astshara/ios/Runner/Info.plist)):**
    *   تمت إضافة `CFBundleURLTypes` لتعريف الـ URL Scheme الخاص بالتطبيق (`io.supabase.astshara`).

3.  **في كود الفلاتر:**
    *   **[auth_repository_impl.dart](file:///C:/Allmyprojects/astshara/lib/features/authentication/data/repositories/auth_repository_impl.dart):** تم تغيير `_googleOAuthRedirectUrl` ليدعم الويب والموبايل تلقائياً.
    *   **[supabase_config.dart](file:///C:/Allmyprojects/astshara/lib/core/config/supabase_config.dart):** تم تنظيف الإعدادات وإزالة HuggingFace.

4.  **في قواعد بيانات Supabase ([supabase_setup.sql](file:///C:/Allmyprojects/astshara/docs/supabase_setup.sql)):**
    *   **إصلاح Recursion Error:** تم تحديث دالة `is_admin()` لتعتمد على JWT Claims بدلاً من الاستعلام المتكرر، مما منع حدوث "التكرار اللانهائي" في سياسات RLS.
    *   **تبسيط السياسات:** تم تحسين قواعد الوصول لجدول `profiles` و `bookings` لضمان سرعة الاستجابة وأمان البيانات.

## الخطوات النهائية المطلوبة منك:

لإتمام العملية بنجاح، يجب القيام بالخطوات التالية يدوياً في لوحة تحكم Supabase:

1.  اذهب إلى [Supabase Dashboard](https://supabase.com/dashboard).
2.  اختر مشروعك.
3.  انتقل إلى **Authentication** -> **URL Configuration**.
4.  في قسم **Redirect URLs**، أضف الرابط التالي:
    `io.supabase.astshara://login-callback`
5.  احفظ الإعدادات.

بعد القيام بذلك، قم بإعادة بناء التطبيق وتشغيله، وسيعمل تسجيل الدخول عبر جوجل بشكل سليم وسيعود إلى التطبيق بعد اختيار الحساب.
