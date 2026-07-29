الدور:
أنت مهندس Supabase وPostgreSQL خبير، متخصص في أمن قواعد البيانات، RLS، Storage، Auth، Performance، وProduction Readiness، ولديك خبرة في تطبيقات Flutter المتصلة بـ Supabase.

مهمتك هي تدقيق وإصلاح وتأمين مشروع Supabase الحالي المرتبط بتطبيق Flutter لمنصة استشارات قانونية عراقية، مع الحفاظ الكامل على البيانات والتوافق مع التطبيق.

==================================================
أولًا: قواعد إلزامية قبل التنفيذ
==================================================

1. ممنوع تنفيذ أي تعديل على قاعدة البيانات قبل إكمال الفحص الشامل.
2. ممنوع حذف أي بيانات.
3. ممنوع حذف أي جدول إلا بعد إثبات عدم استخدامه من التطبيق.
4. ممنوع حذف أو تعديل أي Trigger قبل فهم وظيفته.
5. ممنوع تحويل SECURITY DEFINER إلى SECURITY INVOKER بشكل عشوائي.
6. ممنوع افتراض أسماء الجداول أو الأعمدة.
7. ممنوع افتراض أن RLS الحالية خاطئة قبل تحليل منطق التطبيق.
8. ممنوع تغيير Bucket من Public إلى Private إذا كان Flutter يعتمد على Public URLs قبل تحديد التعديل المطلوب في Flutter.
9. ممنوع تعديل Authentication بطريقة تكسر تسجيل الدخول أو التسجيل.
10. يجب إنشاء Backup أو التأكد من وجود نقطة استعادة آمنة قبل أي تعديل إنتاجي.
11. يفضل تنفيذ الإصلاحات على مراحل.
12. بعد كل Migration يجب تنفيذ Verification.
13. إذا فشل أي Migration، توقف ولا تنتقل إلى التالية حتى تحليل السبب.
14. لا تستخدم حلولًا التفافية تتجاوز ضوابط الأمان.
15. لا تنفذ DDL عبر قناة غير مخصصة لتطبيق Migrations.
16. إذا كان هناك إصلاح يحتاج تعديل Flutter، لا تطبقه بشكل قد يكسر التطبيق؛ سجله كـ Deferred Fix مع تعليمات تعديل Flutter.
17. يجب الحفاظ على التوافق مع Flutter وSupabase Client الحالي.
18. لا تعتبر المهمة مكتملة إلا بعد إعادة فحص Advisors.

==================================================
ثانيًا: بيانات المشروع الحالية
==================================================

المشروع:
Supabase Project

Project Ref:
iidxqrnrazkyfgzelzhb

PostgreSQL:
17.6.1

Region:
ap-northeast-1

حالة المشروع:
ACTIVE_HEALTHY

التطبيق:
Flutter + Supabase

نوع التطبيق:
منصة استشارات قانونية عراقية

الجداول التطبيقية الأساسية المكتشفة:
- profiles
- lawyer_profiles
- bookings
- conversations
- messages

Storage Buckets:
- lawyer_documents
- receipts

==================================================
ثالثًا: بنية العلاقات المكتشفة
==================================================

العلاقة العامة:

auth.users
    |
    | auth_id
    v
profiles
    |
    +-- lawyer_profiles.profile_id
    |
    +-- bookings.user_id
    +-- bookings.lawyer_id
    |
    +-- conversations.user_id
    +-- conversations.lawyer_id
    |
    +-- messages.sender_id

bookings
    |
    v
conversations
    |
    v
messages

Foreign Keys المكتشفة:

profiles.auth_id -> auth.users.id
ON DELETE CASCADE

lawyer_profiles.profile_id -> profiles.id
ON DELETE CASCADE

bookings.user_id -> profiles.id

bookings.lawyer_id -> profiles.id

conversations.booking_id -> bookings.id

conversations.user_id -> profiles.id

conversations.lawyer_id -> profiles.id

messages.conversation_id -> conversations.id

messages.sender_id -> profiles.id


==================================================
رابعًا: المخاطر الأمنية المكتشفة
==================================================

المشكلة 1:
lawyer_documents Public Bucket

الخطورة:
CRITICAL / HIGH

الوضع:
Bucket = Public

المخاطر:
- إمكانية الوصول إلى الملفات عبر Public URL.
- إمكانية كشف مستندات قانونية أو مهنية.
- Public Bucket لا يناسب المستندات الحساسة.
- احتمال إمكانية Listing للملفات حسب السياسات الحالية.

طريقة العلاج:
1. فحص استخدام Flutter لـ getPublicUrl().
2. إذا كان التطبيق لا يحتاج Public URLs:
   - تحويل Bucket إلى Private.
   - إنشاء Storage Policies تعتمد على auth.uid().
   - استخدام Signed URLs.
3. إذا كان Flutter يعتمد على Public URLs:
   - عدم تحويل Bucket مباشرة.
   - تعديل Flutter أولًا.
   - بعد تعديل التطبيق تحويل Bucket إلى Private.
4. منع anon من Listing.
5. السماح للمالك فقط:
   - SELECT
   - INSERT
   - UPDATE
   - DELETE
6. السماح للإدارة بصلاحية كاملة.
7. التحقق من مسار الملف file path وعدم الاعتماد على bucket_id فقط.

ممنوع تنفيذ تحويل Public إلى Private قبل التأكد من توافق Flutter.


==================================================

المشكلة 2:
Public Listing في lawyer_documents

الخطورة:
HIGH

السبب:
وجود Policy تسمح SELECT بشكل عام على Storage.

العلاج:
إزالة Public SELECT Policy.

إنشاء سياسة:
TO authenticated

بحيث يتحقق النظام من ملكية الملف.

يفضل أن يكون مسار الملفات مثل:

lawyer_documents/{user_id}/{filename}

ثم التحقق من:

(storage.foldername(name))[1] = auth.uid()::text

أو استخدام استراتيجية المسار الفعلية الموجودة في التطبيق بعد فحصها.

يجب عدم افتراض بنية path قبل فحص الملفات الموجودة.


==================================================

المشكلة 3:
Anonymous INSERT على lawyer_documents

الخطورة:
HIGH

السبب:
Policy الرفع الحالية على public وقد تعتمد فقط على bucket_id.

الخطر:
- مستخدم مجهول يستطيع محاولة رفع ملفات.
- إمكانية إساءة استخدام Storage.
- إمكانية رفع ملفات غير مصرح بها.

العلاج:
تحويل INSERT إلى authenticated.

التحقق من:
- auth.uid()
- bucket_id
- ملكية المسار

عدم السماح للمستخدم بكتابة ملف داخل مسار مستخدم آخر.


==================================================

المشكلة 4:
Anonymous INSERT على receipts

الخطورة:
HIGH

العلاج:
- تحويل INSERT إلى authenticated.
- التحقق من owner.
- التحقق من path.
- عدم الاعتماد على bucket_id فقط.

فحص ما إذا كان receipts يحتوي بيانات دفع أو مستندات حساسة.

إذا كانت الملفات حساسة:
- يفضل Private Bucket.
- Signed URLs.


==================================================

المشكلة 5:
handle_new_user() SECURITY DEFINER

الخطورة:
HIGH

الدالة:
public.handle_new_user()

الاستخدام:
Trigger بعد إنشاء مستخدم في auth.users.

السبب المحتمل لاستخدام SECURITY DEFINER:
إنشاء profile عند إنشاء المستخدم حتى مع وجود RLS.

العلاج:
لا تحول الدالة إلى SECURITY INVOKER إلا بعد إثبات أن Trigger سيستمر بالعمل.

الإجراء الصحيح:
- الإبقاء على SECURITY DEFINER إذا كانت ضرورية.
- تقييد EXECUTE.
- إزالة EXECUTE من anon.
- إزالة EXECUTE من authenticated.
- إزالة EXECUTE العام إذا لم يكن مطلوبًا.
- ضبط search_path بشكل آمن داخل الدالة.
- عدم الاعتماد على search_path غير موثوق.
- استخدام أسماء مؤهلة بالكامل schema-qualified names.

يجب اختبار:
- إنشاء مستخدم جديد.
- تنفيذ Trigger.
- إنشاء profile.
- عدم قدرة anon/authenticated على استدعاء الدالة كـ RPC.


==================================================

المشكلة 6:
Role Escalation عبر raw_user_meta_data

الخطورة:
CRITICAL

المشكلة المحتملة:
handle_new_user() يستخدم:

raw_user_meta_data->>'role'

لتحديد role.

الخطر:
المستخدم قد يحاول التسجيل بدور:
admin
moderator
lawyer

وهذا خطر تصعيد صلاحيات.

العلاج:
عند التسجيل:
role = 'user'

فقط.

أي ترقية إلى:
lawyer
admin
moderator

يجب أن تتم بواسطة:
- Admin
- Backend موثوق
- Edge Function محمية
- عملية إدارية آمنة

ممنوع الاعتماد على:
raw_user_meta_data
لاتخاذ قرار Authorization.

قبل الإصلاح:
- فحص المستخدمين الحاليين.
- فحص roles الحالية.
- التأكد من عدم وجود حسابات admin غير شرعية.
- عدم تغيير أدوار المستخدمين الحاليين تلقائيًا دون مراجعة.


==================================================

المشكلة 7:
RLS Policies تستخدم public / anon

الجداول المتأثرة:
- profiles
- lawyer_profiles
- bookings
- conversations
- messages
- storage.objects

الخطورة:
HIGH / MEDIUM

العلاج:
إذا لم تكن anonymous access مطلوبة:
TO authenticated

بدل:
TO public
أو
TO anon

يجب عدم تنفيذ الاستبدال بشكل أعمى.

كل Policy يجب تحليلها حسب:
- SELECT
- INSERT
- UPDATE
- DELETE
- ALL

والتحقق من:
USING
WITH CHECK

==================================================

المشكلة 8:
bookings RLS

المالك الحقيقي:
bookings.user_id

المحامي:
bookings.lawyer_id

الصلاحيات المطلوبة:

العميل:
- SELECT حجوزه فقط
- INSERT لحجزه فقط
- UPDATE حجوزه فقط
- DELETE حجوزه فقط

المحامي:
- SELECT الحجوزات المسندة إليه
- الصلاحيات المطلوبة حسب منطق التطبيق

Admin:
- ALL

يجب:
- عدم افتراض أن العميل يمكنه تعديل كل الأعمدة.
- إذا كان العميل يستطيع تعديل status أو price أو lawyer_id، يجب تقييد ذلك.
- الأفضل استخدام Column-level privileges أو RPC/Backend للحقول الحساسة.

تحسين:
استخدام:

(select auth.uid())

بدل استدعاء:
auth.uid()

داخل شروط RLS عند الحاجة لتحسين InitPlan.

منع Multiple Permissive Policies غير الضرورية.

يفضل دمج السياسات المتشابهة.


==================================================

المشكلة 9:
profiles يحتوي بيانات حساسة

الأعمدة الحساسة:
- email
- phone

أعمدة عامة محتملة:
- full_name
- avatar_url
- city
- is_verified

المشكلة:
RLS لا تخفي أعمدة محددة من SELECT.

العلاج:
عدم السماح للزوار بقراءة الصف الكامل.

إنشاء View عامة مثل:

public.public_profiles

تحتوي فقط على:
- id
- full_name
- avatar_url
- city
- is_verified

عدم تضمين:
- email
- phone

إذا كان Flutter يعتمد على:
profiles.select('*')

يجب تسجيل هذا كتغيير يحتاج تعديل Flutter.

لا تنفذ تغييرًا يكسر التطبيق.

==================================================

المشكلة 10:
lawyer_profiles

المطلوب:

الزوار:
SELECT البيانات العامة فقط.

المحامي:
يعدل ملفه فقط.

Admin:
ALL.

يجب فحص:
- license_number
- bio
- years_experience
- consultation_price
- rating
- review_count
- verified
- availability

تحديد ما هو public وما هو private.

ممنوع عرض أي بيانات خاصة دون الحاجة.

يجب منع المحامي من تعديل:
- verified
- rating
- review_count

إذا كانت هذه القيم يجب أن تكون موثوقة من النظام.

يفضل جعلها System-managed.

==================================================

المشكلة 11:
conversations

الأطراف:
- user_id
- lawyer_id

العلاج:

العميل:
يرى محادثاته فقط.

المحامي:
يرى المحادثات المسندة إليه فقط.

Admin:
يرى الجميع.

anon:
ممنوع.

Policy تعتمد على:
auth.uid()

ويجب استخدام:
TO authenticated

يجب منع مستخدم من تعديل:
user_id
lawyer_id
booking_id

إلا من خلال Admin أو Backend موثوق.

==================================================

المشكلة 12:
messages

العلاقة:
messages.conversation_id -> conversations.id

العلاج:

المستخدم يستطيع:
SELECT الرسائل إذا كان طرفًا في conversation.

INSERT إذا كان طرفًا.

UPDATE فقط للحقول المسموح بها.

DELETE حسب متطلبات النظام.

anon:
ممنوع.

يجب منع مستخدم من:
- إرسال رسالة في محادثة ليست له.
- قراءة رسائل محادثة ليست له.
- تعديل sender_id.
- تعديل conversation_id.

يجب إضافة Index على:
messages.conversation_id

==================================================

المشكلة 13:
Storage Policies

يجب فحص:
storage.objects

لكل Bucket.

سياسات المالك:

SELECT
INSERT
UPDATE
DELETE

حسب:
auth.uid()

يجب التحقق من path.

Admin:
ALL.

anon:
ممنوع إلا إذا كان هناك سبب وظيفي مثبت.

لا تعتمد فقط على:
bucket_id = '...'

لأن ذلك لا يثبت ملكية الملف.


==================================================

المشكلة 14:
Foreign Keys بدون Index

الجداول المهمة:

bookings.user_id
bookings.lawyer_id

conversations.booking_id
conversations.user_id
conversations.lawyer_id

messages.conversation_id
messages.sender_id

العلاج:
إضافة Indexes مناسبة.

مثال:

CREATE INDEX IF NOT EXISTS idx_bookings_user_id
ON public.bookings(user_id);

CREATE INDEX IF NOT EXISTS idx_bookings_lawyer_id
ON public.bookings(lawyer_id);

CREATE INDEX IF NOT EXISTS idx_conversations_booking_id
ON public.conversations(booking_id);

CREATE INDEX IF NOT EXISTS idx_conversations_user_id
ON public.conversations(user_id);

CREATE INDEX IF NOT EXISTS idx_conversations_lawyer_id
ON public.conversations(lawyer_id);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id
ON public.messages(conversation_id);

CREATE INDEX IF NOT EXISTS idx_messages_sender_id
ON public.messages(sender_id);

قبل الإنشاء:
تحقق من وجود Index مكافئ حتى لا يتم إنشاء Duplicate Index.


==================================================

المشكلة 15:
Multiple Permissive Policies

الجداول:
- bookings
- profiles
- وربما غيرها

المشكلة:
وجود عدة Policies لنفس:
role + command

العلاج:
- دمج السياسات عند الإمكان.
- تقليل عدد Policies.
- الحفاظ على نفس المنطق.
- اختبار الحالات:
  anon
  authenticated
  user
  lawyer
  admin

لا تحذف Policy قبل إنشاء البديل واختباره.


==================================================

المشكلة 16:
RLS InitPlan Performance

المشكلة:
استخدام auth.uid() مباشرة داخل Policies.

العلاج:
استبدال:

auth.uid()

بـ:

(select auth.uid())

عند ملاءمة ذلك.

يجب التحقق من Execution Plan بعد التعديل.


==================================================

المشكلة 17:
Authentication

Leaked Password Protection:
الحالة الحالية حسب Advisor:
Disabled

العلاج:
تفعيلها.

Password Strength:
ضبط سياسة قوية مناسبة للإنتاج.

مقترح:
Minimum length = 12

لكن يجب اختبار Flutter لمعالجة:
WeakPasswordError

Secure Email Confirmation:
التحقق من إعداد Auth الفعلي.

Password Change:
يفضل:
- Reauthentication
- Current Password verification

MFA:
يفضل:
- إلزام Admin
- تشجيع Lawyers
- اختياري للمستخدمين في البداية

Auth Rate Limits:
مراجعة وتفعيل القيم المناسبة.

CAPTCHA:
دراسة تفعيله على:
- Sign Up
- Password Reset

SMTP:
استخدام SMTP موثوق للإنتاج بدل البريد الافتراضي عند الحاجة.

Redirect URLs:
مراجعة جميع الروابط.
السماح فقط بالدومينات المطلوبة.

==================================================

المشكلة 18:
Realtime

realtime.messages

ممنوع تعديل جداول Supabase الداخلية عشوائيًا.

افحص:
- Channels
- Broadcast
- Presence
- Private Channels

إذا كانت المحادثات تستخدم Realtime:
تأكد أن المستخدم لا يستطيع الاشتراك في قناة محادثة لا تخصه.

يفضل استخدام Private Channels وRLS المناسبة إذا كان ذلك متوافقًا مع Flutter.

أي تغيير يحتاج Flutter يسجل كـ Deferred Fix.


==================================================

المشكلة 19:
Database Objects غير المستخدمة

افحص:
- Tables
- Views
- Functions
- Triggers
- Indexes

قبل حذف أي عنصر:
- البحث عن dependencies.
- البحث في Functions.
- البحث في Policies.
- البحث في Views.
- البحث في Flutter repository إن كان متاحًا.
- البحث في Edge Functions.
- البحث في API usage.

ممنوع حذف أي عنصر بناءً على عدم وجود بيانات فقط.


==================================================

المشكلة 20:
Security Definer Hardening

لكل SECURITY DEFINER Function:

افحص:
- owner
- search_path
- EXECUTE grants
- هل يمكن استدعاؤها من API
- هل هي Trigger-only
- هل يمكن استغلالها لتجاوز RLS

يجب:
- تقييد EXECUTE.
- ضبط search_path.
- استخدام schema-qualified names.
- منع SQL injection.
- التحقق من صلاحيات المدخلات.


==================================================
خامسًا: خطة التنفيذ الإلزامية
==================================================

Migration 001:
Preflight

- فحص الحالة الحالية.
- تسجيل عدد الصفوف.
- تسجيل Policies.
- تسجيل Grants.
- تسجيل Functions.
- تسجيل Triggers.
- تسجيل Indexes.
- التأكد من وجود Backup/Recovery Point.

لا تغير البيانات.


Migration 002:
Hardening handle_new_user

- لا تحول SECURITY DEFINER دون اختبار.
- تقييد EXECUTE.
- ضبط search_path.
- منع Role Escalation.
- التأكد من أن التسجيل ينشئ role=user.
- اختبار Trigger.


Migration 003:
Bookings RLS

- إزالة السياسات الزائدة.
- إنشاء Policies دقيقة.
- user_id للعميل.
- lawyer_id للمحامي.
- Admin ALL.
- اختبار CRUD.


Migration 004:
Profiles

- حماية email وphone.
- إنشاء Public View إذا لزم.
- حماية التعديل.
- منع تعديل role من العميل.
- Admin ALL.


Migration 005:
Lawyer Profiles

- Public read للبيانات العامة.
- Owner update.
- منع تعديل verified/rating/review_count.
- Admin ALL.


Migration 006:
Conversations

- الأطراف فقط.
- Admin ALL.
- anon ممنوع.


Migration 007:
Messages

- أطراف المحادثة فقط.
- sender_id مضبوط.
- conversation_id لا يمكن تغييره من العميل.
- anon ممنوع.


Migration 008:
Storage

- إزالة Anonymous Listing.
- إزالة Anonymous Upload.
- Owner Policies.
- Admin Policies.
- عدم تحويل Public إلى Private قبل توافق Flutter.


Migration 009:
Indexes

- إضافة Missing FK Indexes.
- عدم إنشاء Duplicate Indexes.


Migration 010:
Auth

- Leaked Password Protection.
- Password Strength.
- Email Confirmation.
- Auth Rate Limits.
- CAPTCHA عند الحاجة.

أي إعداد يحتاج تعديل Flutter يسجل كـ Deferred.


==================================================
سادسًا: التحقق بعد كل Migration
==================================================

بعد كل Migration:

1. تحقق من نجاح Migration.
2. تحقق من RLS.
3. تحقق من Policies.
4. تحقق من Grants.
5. تحقق من Function behavior.
6. تحقق من Trigger.
7. تحقق من Storage.
8. تحقق من عدم فقدان البيانات.
9. تحقق من عدم وجود أخطاء SQL.
10. تحقق من Advisor إذا كان مناسبًا.

اختبر الحالات:

Anonymous:
- لا يرى بيانات خاصة.
- لا يقرأ المحادثات.
- لا يقرأ الرسائل.
- لا يرفع ملفات غير مصرح بها.

Authenticated User:
- يرى بياناته.
- يرى حجوزاته.
- يرى محادثاته.
- يرى رسائله.
- لا يرى بيانات الآخرين.

Lawyer:
- يرى بيانات المحامين العامة.
- يرى حجوزاته المسندة.
- يرى محادثاته.
- يعدل ملفه فقط.
- لا يعدل verified/rating.

Admin:
- Full Access حسب الحاجة.

==================================================
سابعًا: التعديلات التي قد تحتاج Flutter
==================================================

يجب عدم تطبيقها مباشرة قبل تعديل التطبيق:

1. تحويل lawyer_documents إلى Private.
   Flutter يجب أن يستخدم Signed URLs بدل Public URLs.

2. تغيير profiles إلى Public View.
   Flutter يجب أن يستخدم:
   public_profiles
   للبيانات العامة.

3. تعديل select('*').
   يجب تحديد الأعمدة صراحة.

4. Password Strength.
   Flutter يجب أن يعالج WeakPasswordError.

5. Reauthentication.
   Flutter يحتاج تدفق إعادة مصادقة.

6. MFA.
   Flutter يحتاج واجهة MFA.

7. Private Realtime Channels.
   Flutter يجب أن يتصل بالقنوات الخاصة بطريقة صحيحة.

8. أي تغيير في Storage Path.
   يجب تحديث كود الرفع والتنزيل.

هذه التعديلات لا تعتبر فشلًا في الإصلاح، بل:
DEFERRED - REQUIRES FLUTTER CODE CHANGES


==================================================
ثامنًا: التقرير النهائي الإلزامي
==================================================

أنشئ تقريرًا نصيًا قابلًا للنسخ بالكامل.

يجب أن يحتوي:

==================================================
SUPABASE PRODUCTION SECURITY AUDIT
==================================================

Project:
[Project Name]

Project Ref:
[Project Ref]

Audit Date:
[Date]

Application:
Flutter + Supabase

Status:
[Production Ready / Conditionally Ready / Not Ready]

--------------------------------------------------
1. Executive Summary
--------------------------------------------------

ملخص تنفيذي.

--------------------------------------------------
2. Database Architecture
--------------------------------------------------

الجداول.

العلاقات.

Foreign Keys.

Views.

Functions.

Triggers.

Storage.

Auth.

--------------------------------------------------
3. Security Findings
--------------------------------------------------

لكل مشكلة:

ID:
اسم المشكلة:

Severity:
Critical / High / Medium / Low

Description:

Root Cause:

Current State:

Risk:

Affected Components:

Fix Applied:

Migration:

Verification:

Expected Result:

Rollback:

Status:
Fixed / Deferred / Requires Flutter / Accepted Risk

--------------------------------------------------
4. RLS Audit
--------------------------------------------------

لكل جدول:

Table:
Policy:
Role:
Command:
USING:
WITH CHECK:

Current Risk:

Fix:

Verification:

--------------------------------------------------
5. Storage Audit
--------------------------------------------------

Bucket:
Public/Private:

Policies:

Risk:

Fix:

Flutter Impact:

Status:

--------------------------------------------------
6. Auth Audit
--------------------------------------------------

Leaked Password Protection:
Status

Password Strength:
Status

Email Confirmation:
Status

MFA:
Status

Reauthentication:
Status

Rate Limits:
Status

CAPTCHA:
Status

SMTP:
Status

--------------------------------------------------
7. Performance Audit
--------------------------------------------------

Missing Indexes.

Duplicate Indexes.

Unused Indexes.

RLS InitPlans.

Multiple Permissive Policies.

Query Performance.

Fixes.

--------------------------------------------------
8. Migrations Applied
--------------------------------------------------

Migration 001:
Name:
Status:
Date:

Migration 002:
Name:
Status:
Date:

وهكذا.

--------------------------------------------------
9. Deferred Changes
--------------------------------------------------

قائمة كاملة بكل التعديلات التي لم تنفذ لأنها تحتاج تعديل Flutter.

لكل واحدة:

Change:
Reason:
Flutter File/Area:
Required Code Change:
Risk if Ignored:
Priority:

--------------------------------------------------
10. Rollback Plan
--------------------------------------------------

لكل Migration:

Rollback SQL:

أو:

Restore Point:

--------------------------------------------------
11. Final Advisor Results
--------------------------------------------------

Security Advisor:
Before:
After:

Database Advisor:
Before:
After:

Performance Advisor:
Before:
After:

--------------------------------------------------
12. Data Integrity
--------------------------------------------------

Rows Lost:
0

Tables Deleted:
0

Data Deleted:
0

Foreign Keys Broken:
0

Triggers Broken:
0

--------------------------------------------------
13. Production Readiness
--------------------------------------------------

Security:
Score / 10

Performance:
Score / 10

Data Integrity:
Score / 10

Auth Security:
Score / 10

Storage Security:
Score / 10

Overall:
Score / 10

Status:
READY
أو
CONDITIONALLY READY
أو
NOT READY

--------------------------------------------------
14. Remaining Risks
--------------------------------------------------

قائمة المخاطر المتبقية.

--------------------------------------------------
15. Flutter Required Changes
--------------------------------------------------

قائمة كاملة بالتعديلات المطلوبة في Flutter.

--------------------------------------------------
16. Future Recommendations
--------------------------------------------------

- MFA للإدارة.
- Private Storage.
- Signed URLs.
- Audit Logs.
- Rate Limiting.
- Monitoring.
- Backup Verification.
- Disaster Recovery.
- Security Testing.
- Penetration Testing.
- Dependency Updates.

==================================================
نهاية التقرير
==================================================

مهم جدًا:

لا تقل إن المشروع Production Ready إذا بقيت مشكلة Critical أو High غير معالجة إلا إذا كانت موثقة بوضوح كـ Deferred بسبب Flutter.

لا تقل إن Migration نجحت إلا بعد التحقق منها فعليًا.

لا تقل إن Advisor أصبح نظيفًا إلا بعد إعادة تشغيله.

لا تخفِ أي مشكلة تم اكتشافها.

أي تعديل لم يتم تنفيذه بسبب توافق Flutter يجب وضعه بوضوح تحت:

DEFERRED - REQUIRES FLUTTER CODE CHANGES

وأي تعديل تم رفضه من أداة التنفيذ أو تعذر تطبيقه يجب تسجيله تحت:

BLOCKED - REQUIRES MANUAL/ADMINISTRATIVE ACTION

مع كتابة SQL المقترح وطريقة تطبيقه يدويًا، دون الادعاء أنه تم تنفيذه.

الهدف النهائي:
Supabase آمن ومستقر وProduction Ready، دون فقدان البيانات ودون كسر تطبيق Flutter.