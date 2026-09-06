# سجل تغييرات الوكيل الذكي — 2026-08-11

## الهدف
استكمال متطلبات إعادة تصميم تطبيق «استشارة» اعتماداً على تصميم Stitch، مع الحفاظ على منطق الحجز والدفع والأمان الحاليين.

## قاعدة إلزامية قبل أي تعديل جديد
- مراجعة آخر commits أولاً وعدم إعادة تنفيذ شاشة أو ملف سبق تعديله إلا إذا كان الإصلاح يستهدف خطأ مثبتاً.
- مراجعة الملفات التي تم تعديلها سابقاً قبل إنشاء commit جديد.
- تسجيل كل تغيير جوهري في هذا الملف مع: commit، الملف/الصفحة، نوع التعديل، والنتيجة.
- لا يعتبر أي إصلاح ناجحاً قبل فحص CI المرتبط بالـcommit نفسه.
- لا إنشاء نسخ مكررة من الملفات؛ التعديل يتم على الملف الأصلي فقط.

## تدقيق 2026-08-12 قبل دفعة التصميم الحالية
تمت مراجعة سجل التنفيذ والملفات الفعلية قبل أي تعديل. تم تأكيد أن تسجيل الدخول وOTP والملف الشخصي والدفع اليدوي وقائمة الاستشارات وتفاصيل الحجز ودليل المحامين والرئيسية والتنبيهات وتدفقات الدفع سبق تنفيذها، لذلك لا تتم إعادة إنشائها.

### تعديل منفذ
- الملف: `lib/features/home/presentation/pages/home_page.dart`
- commit: `2fa48f4bc92f125d6f3f86612162faff2758cf91`
- التعديل: إزالة الخلفية الداكنة الثابتة من Header الصفحة الرئيسية واستبدالها بـ`ColorScheme.surface`، واستبدال لون خلفية الصورة الافتراضية الثابت في الوضع الفاتح بـ`surfaceContainerHighest`.
- السبب: مطابقة أفضل لـStitch Light/Dark ومنع اختلاف السطوح عند تغيير الثيم.
- النتيجة: التعديل محدود بصرياً ولا يغير منطق البحث أو التخصصات أو بيانات المحامين أو التنقل.

## التغييرات المنفذة سابقاً
### 1. توثيق العمل
- إنشاء `CHANGELOG_AI_2026-08-11.md` كسجل دائم للتعديلات الخاصة بهذه المرحلة.
- تحديث `PROJECT_AI_CONTEXT.md` ليشير إلى السجل ويلخص قرارات الواجهة والحجز الحالية.

### 2. إصلاح تباين صفحة إكمال الملف الشخصي
الملف: `lib/features/authentication/presentation/pages/complete_profile_page.dart`.
- إزالة الاعتماد على `Colors.white` في بطاقات الأدوار ومنطقة رفع الهوية، لأنه كان يسبب تعارضاً عند استخدام الوضع الداكن.

## استكمال تدقيق الإنتاج — 2026-09-06
### إصلاح سلامة التقييمات
- الملف/قاعدة البيانات: `supabase/migrations/20260906210000_enforce_one_review_per_booking.sql`.
- تم التحقق من بيانات الإنتاج الحالية وعدم وجود أكثر من تقييم للحجز نفسه قبل إضافة القيد.
- أضيف Unique Index على `reviews.booking_id` لمنع إرسال تقييم مكرر لنفس الاستشارة حتى في حالات النقر المتكرر أو التزامن.
- لم يتم تغيير RLS أو صلاحيات التقييم؛ بقيت قاعدة أن التقييم لا يُقبل إلا من صاحب الحجز وبعد اكتمال الاستشارة والدفع.
- Migration طُبقت بنجاح على مشروع Supabase الإنتاجي.

### التحقق من إصلاح التقييم
- قاعدة الإنتاج تحتوي حالياً على تقييمين صحيحين مرتبطين بحجوزات مكتملة ومنتهية ومدفوعة.
- `lawyer_profiles.rating` و`review_count` متطابقان مع التقييمات الفعلية الحالية.
- سياسة `reviews_insert_completed_booking` الفعلية في الإنتاج تتحقق من هوية العميل، ملكية الحجز، المحامي المرتبط بالحجز، حالة `مكتمل`، انتهاء الاستشارة، ووجود دفع ناجح.

### تدقيق Auth والأمن — 2026-09-06
- تم فحص Supabase Security Advisor مباشرة.
- تم التحقق من سياسات RLS الفعلية للجداول التي أبلغ عنها Advisor؛ السياسات الحساسة تعمل بدور `authenticated` وليس `anon`، لذلك لم يتم حذفها عشوائياً.
- تم التحقق من صلاحيات دوال `SECURITY DEFINER`: الدوال التطبيقية الحساسة لا تملك `EXECUTE` للـ`anon`، بينما دوال دليل المحامين العامة `get_public_lawyer` و`get_public_lawyers` تسمح بالـ`anon` عمداً لخدمة الدليل العام.
- تم إصلاح ازدواجية فهارس `reviews.booking_id` في الإنتاج: الإبقاء على `reviews_one_per_booking_uidx` كالفهرس الفريد الأساسي وحذف `ux_reviews_booking_id` و`idx_reviews_booking_id` الزائدين.
- تم تسجيل نفس إصلاح الفهارس في المستودع عبر migration: `supabase/migrations/20260906213000_remove_duplicate_review_booking_indexes.sql`.
- حالة Auth: حماية كلمات المرور المسرّبة ما زالت معطلة وفق Advisor. هذا إعداد مُدار من Supabase Auth وليس من SQL migration المتاح في مسار المشروع، لذلك لم يتم إجراء تغيير غير موثوق قد يكسر المصادقة.

### إصلاح إضافي للأمن — دليل المحامين العام
- migration: `supabase/migrations/20260906214500_harden_public_lawyer_lookup_functions.sql`.
- commit: `122b551bace1310677d6fd6fd0d232d026ca1f31`.
- السبب: كان `get_public_lawyer` و`get_public_lawyers` يعملان كـ`SECURITY DEFINER` مع صلاحية تنفيذ عامة لخدمة الدليل العام، وهو ما كان يولّد تحذيرات Advisor.
- التعديل: إضافة `lawyer_profile_id` إلى `public_lawyer_directory` وربطه بملف المحامي، ثم تحويل دالتي القراءة العامتين إلى `SECURITY INVOKER` مع الاعتماد على جدول الدليل العام وسياسة القراءة العامة المقيدة بـ`is_verified = true`.
- الحفاظ على واجهة RPC وحقول `id` و`profile_id` حتى لا يتغير عقد التطبيق، مع استمرار إرجاع بيانات المحامين الموثقين فقط.
- تم تطبيق migration بنجاح على Supabase Production، والتحقق من وجود صف دليل موثق مرتبط بـ`lawyer_profile_id`.
- بعد الإصلاح اختفت تحذيرات Advisor الخاصة بـ`get_public_lawyer` و`get_public_lawyers`، بينما بقيت التحذيرات الأخرى التي تتطلب تدقيقاً منفصلاً.

### حالة الأمن المتبقية
- تحذيرات `SECURITY DEFINER` المتبقية لا تعني تلقائياً وجود ثغرة؛ يجب الحفاظ على الدوال التي يعتمد عليها التطبيق مع فحوص الصلاحيات الداخلية، وعدم إلغائها عشوائياً.
- تحذير `telegram_login_requests` سببه RLS مفعّل بدون سياسات مباشرة، وهو مقصود لأن الوصول يتم عبر دوال موثوقة.
- تحذيرات Anonymous Access Policies الحالية تتضمن سياسات فعلية بدور `authenticated`، لذلك لم تُعتبر سبباً كافياً لتغيير RLS.
- حماية كلمات المرور المسرّبة في Supabase Auth ما زالت تحتاج تفعيلها من إعدادات Auth في لوحة Supabase؛ لا يوجد مسار موثوق لتغيير هذا الإعداد عبر migration في المشروع الحالي.

### التحقق من المستودع
- إصلاح الفهارس طُبق بنجاح على Supabase production.
- إصلاح دليل المحامين العام طُبق بنجاح على Supabase production.
- commit الأخير: `122b551bace1310677d6fd6fd0d232d026ca1f31`.
- يجب فحص CI المرتبط بالـcommit قبل إعلان الإصلاح البرمجي متحققاً بالكامل.

## ربط Firebase للإشعارات الأصلية — 2026-09-06
### تسجيل Google Services Gradle Plugin
- الملف: `android/settings.gradle.kts`.
- commit: `749dfe808269f9a6ab5f406a071c53bbc9a2f7ee`.
- التعديل: إضافة `com.google.gms.google-services` بالإصدار `4.5.0` ضمن plugins مع `apply false`.
- السبب: تجهيز مشروع Android لمعالجة `android/app/google-services.json` ضمن تكامل Firebase الرسمي قبل إضافة Firebase Messaging.
- النتيجة: تم تعديل ملف الإعداد الأصلي فقط، دون تغيير منطق التطبيق أو استبدال نظام الإشعارات الحالي. لم يُعلن نجاح CI بعد، ويجب فحص CI المرتبط بهذا commit قبل اعتبار الخطوة مكتملة.

### توحيد Android Application ID
- الملفات: `android/app/build.gradle.kts`، `android/app/src/main/kotlin/com/istishara/app/MainActivity.kt`، وحذف الملف القديم من `android/app/src/main/kotlin/com/example/astshara/MainActivity.kt`.
- commits: `d956e64f553e89434ebf347c6db61da9e88e8db1` و`4c1178aa778de9a1f02a8e81df78446395a64b92` و`88def2b9e83be318adefb6b02d5f9cf51147f6cb`.
- التعديل: توحيد `namespace` و`applicationId` إلى `com.istishara.app`، وتحديث package لمسار `MainActivity` بما يطابق الـnamespace، وتفعيل `com.google.gms.google-services` داخل وحدة التطبيق.
- السبب: مطابقة هوية Android مع حزمة Firebase الموجودة في `google-services.json` ومنع فشل ربط Google Services أو عدم العثور على `MainActivity`.
- النتيجة: إعداد Android أصبح متوافقاً مبدئياً مع ملف Firebase المرفوع. لم يُعلن نجاح CI بعد؛ يجب فحص البناء قبل متابعة إضافة Firebase Messaging.

### إضافة Firebase Core وFirebase Messaging
- الملف: `pubspec.yaml`.
- commit: `55426f11b2ff491f320fabb70ae185ef0895402d`.
- التعديل: إضافة `firebase_core: ^4.14.0` و`firebase_messaging: ^16.6.0` دون تغيير بقية الاعتمادات.
- السبب: إصدارات متوافقة مع حد Dart `>=3.12.0` وFlutter `>=3.47.0` في المشروع؛ صفحة الإصدارات الحالية لـFlutterFire توضح أن كلا الإصدارين يتطلبان Dart 3.6 على الأقل، كما أن سجل `firebase_messaging` يذكر مواءمة أدوات Android مع Flutter 3.47.
- النتيجة: تم تعديل `pubspec.yaml` فقط في هذه الخطوة. لم تتم إضافة منطق FCM أو تغيير نظام الإشعارات الحالي بعد. يلزم تشغيل `flutter pub get`/البناء وفحص CI لتحديث `pubspec.lock` والتحقق من عدم وجود تعارضات قبل متابعة تكامل FCM.

### دمج FCM داخل التطبيق
- الملفات: `lib/core/services/push_notification_service.dart`, `lib/core/services/notification_service.dart`, `lib/app/bootstrap.dart`, `android/app/src/main/AndroidManifest.xml`.
- commits: `3a56c2b0fa1f169701d3ec6951bd892ff835f6e7`, `315b0c08ea8627d491d1b0ab0a01b2ad2b82174f`, `8e1d618f42adcffd4069bb3f1b3d6c7b8e354f69`, `7321c58d09c72cecec7db4b6a28f751d50468188`.
- التعديل: إضافة تسجيل FCM، طلب صلاحية الإشعارات، الاستماع للرسائل في المقدمة، معالجة فتح التطبيق من الخلفية/الحالة المنتهية، وتسجيل معالج FCM للخلفية. تمت المحافظة على `flutter_local_notifications` وSupabase Realtime وعدم استبدال Web/PWA Push.
- Android: إضافة `POST_NOTIFICATIONS` وربط قناة `law_connect_channel` عالية الأهمية بقناة FCM الافتراضية.
- النتيجة: أصبح التطبيق جاهزاً من جهة العميل لتسجيل FCM token واستقبال رسائل FCM الأصلية؛ الإشعار في الخلفية/الحالة المنتهية يعتمد على notification payload الذي يعرضه نظام التشغيل.

### تخزين رموز الأجهزة في Supabase
- الملف: `supabase/migrations/20260906230000_add_push_device_tokens.sql`.
- commit: `30af23b4caaf8be0b00bf9c31819129a28c12a6a`.
- التعديل: إنشاء `push_device_tokens` مع Unique token وRLS مقيد بمالك الجهاز، وفهارس للحسابات النشطة، وتحديث `updated_at` تلقائياً.
- النتيجة: تم تطبيق migration فعلياً على Supabase Production والتحقق من وجود الجدول. لا يسمح الجدول للعميل بالوصول إلى رموز مستخدمين آخرين.

### خادم إرسال FCM
- الملفات: `supabase/functions/send-native-push/index.ts`, `supabase/config.toml`.
- commits: `5bae72e211d5c072e8b99f6fa08988fff8893c91`, `67548391d11fcc241d79d5e7b7d99683483aa7f3`.
- التعديل: إنشاء Edge Function ترسل FCM HTTP v1 باستخدام Service Account مخزن كسِر، وتقرأ فقط الأجهزة النشطة للمستخدم، وترسل title/body/data، وتستخدم قناة Android عالية الأولوية وصوت default، وتبطل الرموز غير المسجلة. تم تقييد endpoint بالتحقق من Service Role Authorization داخل الوظيفة مع تعطيل تحقق JWT الخاص بالمنصة لأن الاستدعاء المقصود هو Database Webhook.
- النتيجة: تم نشر `send-native-push` على Supabase Production بنجاح، لكن الإرسال الفعلي لا يعتبر مكتملاً بعد حتى يتم ضبط `FCM_SERVICE_ACCOUNT_JSON` وربط Database Webhook على `public.notifications`.

### حالة التحقق الحالية
- Supabase: جدول `push_device_tokens` موجود فعلياً في Production.
- Supabase: Edge Function `send-native-push` حالتها `ACTIVE`.
- GitHub: لا توجد status checks مسجلة حتى الآن على commit `8e1d618f42adcffd4069bb3f1b3d6c7b8e354f69`، لذلك لم يتم الادعاء بأن CI مر بنجاح.
- المطلوب قبل إعلان الإشعارات الأصلية مكتملة 100%: إضافة Firebase Service Account كـSupabase secret باسم `FCM_SERVICE_ACCOUNT_JSON`، ثم إنشاء Database Webhook من `public.notifications` حدث `INSERT` إلى `send-native-push` مع Authorization/service key، وبعدها اختبار جهاز Android فعلي في foreground/background/terminated.
- iOS يحتاج لاحقاً `GoogleService-Info.plist` الصحيح وAPNs key وPush Notifications/Background Modes قبل إعلان دعم iOS الإنتاجي؛ هذا لا يؤثر على عدم كسر Web/PWA الحالي.
