# استشارة — المرجع الموحد للوكيل الذكي

> اقرأ هذا الملف قبل أي تعديل. الكود الفعلي في آخر commit على `main` وقاعدة Supabase الفعلية هما مصدر الحقيقة، وهذا الملف يشرح المنطق والقرارات والتاريخ. إذا خالف التوثيق الواقع، افحص الواقع أولاً ثم حدّث الملف.

## 1) هوية المشروع
- الاسم: استشارة / astshara.
- GitHub: `aliyaseenhasn-hue/astshara`.
- الفرع: `main`.
- Flutter: Android / iOS / Web.
- Backend: Supabase PostgreSQL + Auth + Storage + Realtime.
- Architecture: Feature-first / Clean Architecture.
- State: Riverpod.
- Routing: GoRouter / ShellRoute.
- RTL، والرسائل وحالات الحجز والدفع للمستخدم بالعربية.
- الهوية البصرية: ذهبي + سماوي. لا تغيّرها دون سبب.

## 2) قواعد الوكيل
1. لا تبدأ من الصفر ولا تعيد إصلاحاً منفذاً.
2. قبل التعديل افحص آخر commit والملفات المرتبطة وCI وقاعدة Supabase.
3. لا تخمّن schema/RLS/RPC؛ افحصها فعلياً.
4. المشاكل الحقيقية تعالج بكود/SQL/Edge Function حقيقي، وليس Mock أو حل مؤقت.
5. بعد كل تعديل راجع الكود، أصلح أخطاء compilation/analyzer، ثم افحص CI والنشر عند توفر النتائج.
6. أي تغيير في قاعدة البيانات يجب أن يكون Migration محفوظاً في `supabase/migrations` ومطبقاً على المشروع الفعلي.
7. لا تحذف ميزة قائمة إلا عند الضرورة، وحافظ على وظيفتها.
8. حدّث هذا الملف بعد كل تعديل جوهري.

## 3) الملفات الرئيسية
- `lib/core`: إعدادات وخدمات مشتركة.
- `lib/features/authentication`: المصادقة والملف الشخصي.
- `lib/features/profile`: الإعدادات والملف الشخصي.
- `lib/features/lawyers`: ملفات المحامين والخدمات والتخصصات.
- `lib/features/bookings`: إنشاء الحجز وتفاصيله والحالات وبدء/إنهاء الاستشارة.
- `lib/features/payments`: الدفع والإيصالات.
- `lib/features/chat`: المحادثات.
- `lib/features/reviews`: تقييمات المحامين.
- `lib/features/admin`: الإدارة وطلبات تغيير التخصص.
- `lib/shared/widgets/app_shell.dart`: الحاوية الرئيسية.
- `lib/shared/widgets/main_bottom_nav.dart`: الشريط السفلي الوحيد.
- `PROJECT_MASTER_DOCUMENTATION.md`: توثيق تاريخي/تقني.
- `PROJECT_AI_CONTEXT.md`: هذا المرجع التشغيلي.

## 4) تعديل معلومات الحساب — الحالة الحالية
- صفحة `lib/features/profile/presentation/pages/profile_page.dart` تحتوي فعلياً على تعديل الاسم، رقم الهاتف، رقم WhatsApp، المحافظة والصورة الشخصية.
- الصورة تُرفع إلى Supabase Storage bucket `avatars` ثم يُحدث `profiles.avatar_url`.
- لأن الشريط السفلي يفتح `/app-settings` عند اختيار «الإعدادات»، تمت إضافة مدخل واضح داخل `AppSettingsPage` باسم **«المعلومات الشخصية والتواصل»** مع وصف يوضح الحقول القابلة للتعديل.
- المدخل يفتح `/profile` حيث توجد واجهة تعديل البيانات وزر تعديل الصورة.
- التغيير الأخير: commit `730fba558a6b67683648274439a8b3118cc67a1c`.
- لا تعتبر ميزة تعديل الحساب متاحة للمستخدم من ناحية UX إذا لم يكن لها مدخل واضح من صفحة الإعدادات؛ لذلك يجب الحفاظ على مدخل `AppSettingsPage` وعدم إخفائه.

## 5) ملاحظات CI
- يجب أن يكون هناك Workflow موحد لتجنب تشغيل تحليل/بناء مكرر.
- خطأ `FileOptions` السابق عولج بإضافة `package:storage_client/storage_client.dart` وإضافة `storage_client` كاعتماد مباشر.
- لا تعتبر `info` و`warning` في `flutter analyze` فشلاً عندما يستخدم الـWorkflow `--no-fatal-infos --no-fatal-warnings`؛ الأخطاء الحقيقية فقط تمنع الاستمرار.

## 6) سجل آخر التعديلات
### 2026-08-10
- إصلاح استيراد `FileOptions` في رفع الصورة الشخصية.
- إضافة `storage_client` كاعتماد مباشر.
- توحيد Workflow الخاص بالتحليل والبناء والنشر وإزالة التكرار.
- إضافة مدخل «المعلومات الشخصية والتواصل» إلى صفحة «إعدادات التطبيق» لأن زر الإعدادات في الشريط السفلي يفتح `/app-settings` وليس `/profile`.
- الحفاظ على تسجيل الخروج وحذف الحساب والوضع الداكن/الفاتح وإعدادات الإشعارات.
