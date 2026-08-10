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

## 4) قاعدة البيانات الحالية
الجداول المهمة:
- `profiles`: id, auth_id, role, full_name, phone, email, avatar_url, city, whatsapp_number, onboarding_completed وغيرها.
- `lawyer_profiles`: profile_id, full_name, whatsapp, verified, availability, services, specialization, completed_consultations وغيرها.
- `bookings`: user_id, lawyer_id, status, scheduled_at, price, consultation_type, consultation_mode, whatsapp_number, package data, started_at, completed_at, manual payment fields.
- `payments`: الدفع الإلكتروني/اليدوي.
- `lawyer_availability_slots`: المواعيد المتاحة.
- `conversations/messages`: المحادثات.
- `reviews/public_reviews`: التقييمات.
- `notifications`: الإشعارات.
- `specialization_change_requests`: طلبات تغيير التخصص.
- `lawyer_achievements`: صور الإنجازات.

Storage buckets الفعلية:
- `avatars`: public.
- `lawyer_documents`: private.
- `receipts`: private.

## 5) حالات الحجز
`قيد انتظار الدفع`، `قيد معالجة الدفع`، `قيد مراجعة المحامي`، `بانتظار التأكيد`، `مؤكد`، `قيد التنفيذ`، `مكتمل`، `ملغي`، `مسترد`، `بانتظار الاسترداد`، `بانتظار مراجعة عدم الحضور`.

يمنع تعارض الحالة مع الدفع أو التوقيت.

## 6) أنواع الاستشارة
- `نصية`
- `صوتية`
- `فيديو`
- طريقة التنفيذ: `عن بعد` أو `في المكتب`.

حالياً لا توجد غرفة فيديو داخلية مؤكدة (WebRTC/Agora/Jitsi). لا تنشئ غرفة وهمية. الاستشارات عن بعد تعتمد على بيانات WhatsApp المرتبطة بالحجز.

## 7) WhatsApp والملف الشخصي
### طالب الخدمة
- أضيف العمود `profiles.whatsapp_number` ليكون رقم WhatsApp مستقلاً عن رقم الهاتف العام.
- يمكن تعديل الاسم، رقم الهاتف، WhatsApp، والمحافظة من صفحة الملف/الإعدادات.
- الصورة الشخصية قابلة للرفع فعلياً إلى bucket `avatars` وحفظ رابطها في `profiles.avatar_url`.
- رقم WhatsApp مطلوب لطلب الاستشارة.
- `create_booking` يقرأ WhatsApp من profile على الخادم ويضعه في `bookings.whatsapp_number`.
- `p_client_whatsapp` ليس مصدر الحقيقة.
- صفحة معلومات طلب الاستشارة تعرض رقم WhatsApp الحالي كرقم التواصل.

### المحامي
- صفحة الملف نفسها تسمح بتعديل الاسم والهاتف وWhatsApp والمحافظة والصورة.
- عند الحفظ للمحامي يتم تحديث `profiles.whatsapp_number` و`lawyer_profiles.whatsapp` معاً.
- الاستشارة عن بعد تتطلب WhatsApp للمحامي؛ الاستشارة في المكتب لا تتطلب WhatsApp.

## 8) إنشاء الحجز
`create_booking` RPC آمن (`SECURITY DEFINER`).
الشروط:
- المستخدم مسجل الدخول وله profile.
- لديه `whatsapp_number` غير فارغ.
- المحامي verified وavailable.
- الموعد موجود ومتاح ولم يمر.
- نوع الاستشارة والباقة صالحان.
- لا يوجد حجز متعارض.
- التنفيذ `عن بعد` أو `في المكتب` فقط.
- عن بعد: يجب أن يملك المحامي WhatsApp.
- المكتب: لا يشترط WhatsApp للمحامي.
- المكتب يبدأ بـ `بانتظار التأكيد` و`manual_payment_required=true`.
- عن بعد يبدأ بـ `قيد انتظار الدفع`.

تم حذف overload القديم ذي 8 معاملات لأنه كان مساراً يمكن أن يتجاوز منطق WhatsApp الحالي. التطبيق يستخدم دالة 9 معاملات.

## 9) بدء الاستشارة
لا يجوز الانتقال إلى `قيد التنفيذ` إلا بعد تحقق شروط الحجز والدفع والوقت وعدم البدء السابق. قاعدة البيانات/RPC هي الحماية النهائية وليست الواجهة فقط.

عند البدء:
- `status = قيد التنفيذ`.
- تسجيل `started_at` فعلياً.
- منع البدء الثاني.
- عن بعد: فتح WhatsApp للطرف الآخر باستخدام بيانات الحجز/RPC، وليس رقماً ثابتاً.
- المكتب: لا يفتح WhatsApp؛ تظهر رسالة أن الجلسة بدأت حضورياً.

عند الإنهاء:
- يجب وجود `started_at`.
- تسجيل `completed_at`.
- `status = مكتمل`.
- تحديث `lawyer_profiles.completed_consultations` عبر منطق قاعدة البيانات.
- السماح لطالب الخدمة بالتقييم.

## 10) الدفع اليدوي للمكتب
الحجز المكتبي يبقى معلقاً حتى يسجل المحامي المبلغ المستلم. الشروط النهائية تشمل وجود مبلغ مستلم و`manual_received_at` ومطابقة المبلغ مع رسوم الحجز. لا يسمح ببدء الجلسة قبل اكتمال هذه الشروط.

## 11) معلومات التواصل
- الاسم الكامل لطالب الخدمة يظهر للمحامي إذا توفر.
- اسم المحامي يظهر لطالب الخدمة في تفاصيل الحجز.
- `bookingDetailsProvider` يجلب اسم المحامي من `profiles` باستخدام `bookings.lawyer_id`.
- لا تستخدم `عميل` أو `عميل جديد` إذا توفر الاسم الحقيقي.
- لا تعرض WhatsApp للمكتب.
- معلومات التواصل لا تظهر قبل الحالة المناسبة والدفع.

## 12) الملف الشخصي والإعدادات
`lib/features/profile/presentation/pages/profile_page.dart` يحتوي حالياً على:
- تعديل الاسم.
- تعديل رقم الهاتف.
- تعديل رقم WhatsApp.
- تعديل المحافظة (`profiles.city` مستخدمة كمحافظة في الواجهة الحالية).
- رفع وتغيير الصورة الشخصية من bucket `avatars`.
- الحفاظ على تسجيل الخروج وحذف الحساب.
- الحفاظ على إعدادات الإشعارات وإعدادات التطبيق.

`AuthRepository` أصبح يعرّف `refreshUser()` حتى يمكن تحديث حالة المستخدم بعد تعديل الملف.

رفع الصورة يستخدم `FileOptions` من `storage_client`، ولذلك أصبحت `storage_client` dependency مباشرة في `pubspec.yaml` وليست مجرد dependency عابرة.

## 13) صفحة طلب الاستشارة
`lib/features/bookings/presentation/pages/create_booking_page.dart`:
- تعرض رقم WhatsApp في خطوة مراجعة الحجز.
- تمنع المتابعة النهائية عند غياب الرقم.
- تعرض رسالة لإضافته من الإعدادات.
- الرقم read-only في الطلب ومصدره profile.
- المنع النهائي موجود أيضاً في RPC.

## 14) صفحة تفاصيل الاستشارة
`lib/features/bookings/presentation/pages/booking_details_page.dart`:
- تعرض اسم المحامي للعميل.
- تعرض اسم العميل للمحامي.
- تفصل المكتب عن WhatsApp عند بدء الاستشارة.
- زر بدء الاستشارة مرتبط بنافذة الوقت.
- زر الإنهاء للمحامي عند `قيد التنفيذ`.
- التقييم لطالب الخدمة بعد `مكتمل`.

## 15) RPC والأمان
RPCs الحساسة تشمل:
- `create_booking`
- `change_booking_status`
- `get_booking_participant_contact_info`
- `review_booking`
- `record_manual_payment`
- `report_booking_no_show`

تم التحقق سابقاً من منع `anon` من تنفيذ RPCs الحساسة الخاصة بتغيير الحالة/بيانات التواصل، مع السماح للمستخدم المصادق عليه حسب الصلاحيات.

## 16) الميزات التي يجب الحفاظ عليها
- تسجيل الخروج.
- حذف الحساب.
- إعدادات الإشعارات.
- الوضع الداكن والفاتح.
- الإشعارات الحقيقية.
- المحادثات.
- حذف/أرشفة المواعيد السابقة حسب السياسة الحالية.
- طلب تغيير تخصص المحامي مع صورة هوية النقابة وموافقة الإدارة.
- رفع صور الإنجازات.
- الدفع ورفع الإيصالات.
- الدفع اليدوي للمكتب.
- الاسم الكامل لطالب الخدمة.
- إعدادات طرق الدفع ومركز المساعدة.
- الشريط السفلي الواحد وعدم تكرار عناصر التنقل.

## 17) CI والنشر
Workflow الفعلي الموحد: `.github/workflows/deploy.yml`.
- يعمل على push إلى `main` وPull Request إلى `main` وworkflow_dispatch.
- خطوة `analyze` تنفذ `flutter analyze` قبل البناء.
- خطوة `build` تعتمد على نجاح التحليل.
- ينشئ `.env` من GitHub Secrets ويوقف البناء برسالة واضحة إذا كانت الأسرار ناقصة.
- يبني Flutter Web release باستخدام dart2js مع `--no-wasm-dry-run`.
- يرفع `build/web` كـPages artifact ثم ينشر GitHub Pages.
- تم حذف `.github/workflows/flutter-ci.yml` لأنه كان workflow مكرراً يؤدي إلى تشغيل تحليل/بناء ثانٍ غير ضروري.
- لا تعتبر CI ناجحاً إلا بعد ظهور Run فعلي ناجح.

## 18) سجل التعديلات — أغسطس 2026
### بدء الاستشارة والدفع
- `supabase/migrations/20260810023000_harden_consultation_start_flow.sql`: تشديد بدء/إنهاء الاستشارة والدفع اليدوي.
- حماية RPCs الحساسة من `anon`.
- منع WhatsApp للمكتب.

### WhatsApp وملف المستخدم
- `supabase/migrations/20260810030000_require_whatsapp_and_sync_profile_contact.sql`: إضافة `profiles.whatsapp_number` وفرض WhatsApp عند إنشاء الحجز، مع اشتراط WhatsApp للمحامي عن بعد فقط.
- `supabase/migrations/20260810032000_remove_legacy_create_booking_overload.sql`: حذف overload القديم لـ `create_booking`.
- `profile_page.dart`: تعديل الاسم/الهاتف/WhatsApp/المحافظة والصورة.
- إصلاح استيراد `FileOptions` وإعلان `storage_client` كـ direct dependency بعد فشل CI بسبب `FileOptions` غير معروف.

### الحجز والتفاصيل
- `bookings_provider.dart`: جلب اسم المحامي والعميل وWhatsApp الحالي.
- `create_booking_page.dart`: عرض WhatsApp في مراجعة الطلب ومنع الإرسال بدونه.
- `booking_details_page.dart`: إصلاح ظهور اسم المحامي للعميل وفصل بدء المكتب عن WhatsApp.
- `auth_repository.dart`: إضافة `refreshUser()` للواجهة.

### CI
- تم توحيد Workflow النشر والتحليل في `.github/workflows/deploy.yml`.
- تم حذف `.github/workflows/flutter-ci.yml` المكرر.
- تم الإبقاء على تحليل Flutter كمرحلة مستقلة قبل build.

## 19) اختبارات القبول المطلوبة
- `flutter analyze` بدون أخطاء.
- `flutter build web --release` ناجح.
- CI ناجح فعلياً.
- طلب استشارة بدون WhatsApp مرفوض.
- طلب عن بعد لمحامٍ بلا WhatsApp مرفوض.
- طلب مكتبي لمحامٍ بلا WhatsApp مسموح إذا استوفى شروط المكتب.
- رقم WhatsApp يظهر في صفحة مراجعة الطلب ويحفظ مع الحجز.
- اسم المحامي يظهر في تفاصيل الحجز للعميل.
- المكتب لا يفتح WhatsApp.
- لا يمكن بدء الاستشارة قبل الدفع اليدوي للمكتب.
- لا يمكن البدء مرتين.
- `قيد التنفيذ` دائماً معه `started_at`.
- `مكتمل` دائماً معه `completed_at`.
- التقييم يظهر بعد الإكمال.
- تعديل الاسم/الهاتف/WhatsApp/المحافظة/الصورة يعمل ويستمر بعد إعادة تسجيل الدخول.
- تسجيل الخروج وحذف الحساب والإشعارات والثيمات تبقى عاملة.

## 20) حالة آخر تحقق
- آخر commit قبل توحيد الـworkflow: `0df1bbcc4d6a89bced1359ddcb296b187fa19480` لإعلان `storage_client` كاعتماد مباشر.
- آخر تعديل تالٍ: حذف workflow المكرر `.github/workflows/flutter-ci.yml`، والـcommit الناتج `9c66d8a7911caa30856d29a425de13f509eea267`.
- تعذر تشغيل `flutter analyze` محلياً من بيئة الوكيل لأن شبكة التنفيذ لا تستطيع الوصول إلى GitHub؛ لذلك مصدر التحقق النهائي هو GitHub Actions نفسه.
- آخر خطأ CI معروف من السجل المقدم كان `FileOptions` غير معروف في `profile_page.dart`. تم إصلاح الاستيراد، ثم تم جعل `storage_client` dependency مباشرة لتثبيت العقد البرمجية المستخدمة.

## 21) مبدأ المصدر الواحد
إذا اختلف هذا الملف عن الكود أو Supabase، افحص الواقع أولاً، أصلح النظام الحقيقي، ثم حدّث هذا الملف. لا تترك التوثيق قديماً.
