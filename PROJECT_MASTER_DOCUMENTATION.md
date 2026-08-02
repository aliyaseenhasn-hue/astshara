# 📚 LawConnect (استشارة) - Master Documentation

**Version:** 2.0 (Unified Production Edition)  
**Last Updated:** July 2026  
**Project Ref:** iidxqrnrazkyfgzelzhb  
**Status:** Production Ready (Conditional)

---

## 1. Executive Summary & Project Overview
**LawConnect (استشارة)** هو تطبيق قانوني احترافي يربط العملاء بالمحامين داخل العراق. تم تصميم المشروع وفق مفهوم **Single Codebase** باستخدام Flutter و Supabase، مما يلغي الحاجة إلى Backend مستقل.

### الأهداف الأساسية:
- بناء منصة قانونية احترافية تعمل على Android، iOS، و Web (PWA).
- ضمان أقصى درجات الأمان والخصوصية للمستندات القانونية العراقية.
- توفير واجهة إدارة مركزية (Admin Dashboard) للتحكم في المنصة.

---

## 2. Technical Stack (التقنيات المعتمدة)
| المكون | التقنية المستخدمة |
| :--- | :--- |
| **Frontend** | Flutter Stable (Dart 3) |
| **Database** | Supabase PostgreSQL (17.6.1) |
| **Authentication** | Supabase Auth (Phone, Google, Apple) |
| **Realtime** | Supabase Realtime (Chat & Status) |
| **Storage** | Supabase Storage (Private Buckets) |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Serialization** | Freezed & JsonSerializable |
| **Styling** | Material 3 (RTL Support) |

---

## 3. Project Architecture (هيكل المشروع)
يعتمد المشروع على **Clean Architecture** مع نهج **Feature-First**.

### الهيكل العام للمجلدات:
- `lib/core`: الإعدادات العامة، الثيم، الخدمات المشتركة (الذكاء الاصطناعي، الإشعارات).
- `lib/features`: كل ميزة مقسمة إلى (Data, Domain, Presentation).
- `lib/shared`: المكونات والنماذج المشتركة بين الميزات.
- `lib/app`: مشغل التطبيق والـ Router.

### الميزات الأساسية (Features):
1. **Authentication**: نظام الدخول برقم الهاتف و Google.
2. **Lawyers**: عرض المحامين، البحث، وتصنيفات (جنائي، مدني، إلخ).
3. **Bookings**: إدارة طلبات الاستشارة والمواعيد.
4. **Chat**: محادثة فورية مشفرة بين المحامي والعميل.
5. **Payments**: نظام رفع إيصالات الدفع (زين كاش، آسيا حوالة).
6. **Admin**: لوحة التحكم المركزية للإحصائيات وتوثيق المحامين.

---

## 4. Database Design (تصميم قاعدة البيانات)
### الجداول الأساسية:
- `profiles`: البيانات الأساسية (الاسم، الدور، الهاتف).
- `lawyer_profiles`: بيانات المحامين المهنية (رقم الإجازة، السعر، الخبرة).
- `bookings`: سجل الحجوزات وحالتها.
- `conversations` & `messages`: نظام المراسلة.
- `payments`: تتبع عمليات الدفع والتحقق منها.
- `notifications`: التنبيهات اللحظية.

### العلاقات:
- `auth.users` -> `profiles` (One-to-One via `auth_id`).
- `profiles` -> `lawyer_profiles` (One-to-One).
- `profiles` -> `bookings` (One-to-Many).
- `bookings` -> `conversations` -> `messages`.

---

## 5. Security & RLS Policies (الأمن والخصوصية)
الأمن هو الأولوية القصوى في هذا التطبيق نظراً لحساسية البيانات القانونية.

### قواعد الأمان الإلزامية:
- **RLS (Row Level Security)**: مفعل على جميع الجداول.
- **SECURITY DEFINER**: تستخدم فقط في Triggers الضرورية مع ضبط `search_path`.
- **Private Storage**: جميع المجلدات (`lawyer_documents`, `receipts`) خاصة (Private). الوصول يتم عبر **Signed URLs** صالحة لمدة ساعة واحدة فقط.
- **Role Isolation**: الأدمن له وصول كامل، المحامي يرى ملفاته وحجوزاته، والعميل يرى بياناته فقط.

---

## 6. Authentication & User Onboarding
### طرق الدخول:
1. **رقم الهاتف**: عبر Twilio مع دعم الأرقام الاختبارية.
2. **Google Auth**: متاح للعملاء والمحامين.

### رحلة المستخدم الجديد:
عند الدخول لأول مرة، يتم توجيه المستخدم إجبارياً لصفحة **"إكمال الملف الشخصي"** لاختيار دوره (عميل/محامي) وإدخال اسمه، لضمان اكتمال قاعدة البيانات.

---

## 7. Implementation Progress (مسار التقدم)
- [x] إعداد البيئة والربط بـ Supabase.
- [x] تصميم وبرمجة واجهة المستخدم (Ethical Juris Theme).
- [x] تفعيل نظام الدخول الحقيقي (الهاتف و Google).
- [x] بناء لوحة تحكم المسؤول (Admin Dashboard).
- [x] ميزة فلترة المحامين وتوثيقهم.
- [x] تأمين الملفات (Private Storage & Signed URLs).
- [x] إضافة ميزة حذف الحساب نهائياً.
- [x] نظام الإشعارات المتقدم مع تخصيص الصوت.
- [x] إصلاح نظام توثيق المحامين (توحيد المعرفات). ✅
- [ ] إعدادات اللغة (قيد التنفيذ).

---

## 8. Technical Fixes Log (سجل التعديلات التقنية)
### تحديث يوليو 2026: إصلاح حلقة التكرار وظهور الطلبات
1. **المشكلة**: فشل ظهور طلبات المحامين في لوحة الأدمن وتعليق التطبيق في حلقة تكرار.
2. **السبب**: تضارب بين `auth_id` و `profiles.id` في الربط البرمجي، مع وجود ثغرة في شروط التوجيه (Redirect).
3. **الإصلاح**:
    - توحيد استخدام `auth_id` كمرجع أساسي في كافة الاستعلامات.
    - تبسيط عملية جلب بيانات المحامين في الـ Admin Provider لتعمل بشكل منفصل (Decoupled Queries).
    - إضافة وظيفة `is_admin()` في قاعدة البيانات لضمان صلاحيات وصول الأدمن بنسبة 100%.
4. **إصلاح عرض الأسماء**: تعديل ربط البيانات بين `lawyer_profiles` و `profiles` لضمان ظهور اسم المحامي الحقيقي بدلاً من "محامي مجهول" عبر فحص كافة احتمالات المعرفات (ID fallback).
5. **نظام الإشعارات الفوري للتوثيق**: إضافة إرسال إشعارات لجدول `notifications` فور قيام الأدمن بالموافقة أو الرفض للمحامي، ليعلم المستخدم بحالة طلبه لحظياً.
6. **تطوير صفحة الإكمال للمحامين**: جعل الحقول الإضافية (صورة شخصية (أفاتار)، صورة الهوية، ورقم الواتساب) إلزامية في صفحة منفصلة مرتبة مع تثبيت الأزرار في الأسفل لضمان جودة البيانات وسهولة تجربة المستخدم.

---

## 9. Rules for Development (قواعد التطوير)
1. **ممنوع إنشاء Backend مستقل**: أي ميزة يجب تنفيذها داخل Supabase (Edge Functions, Triggers, RLS).
2. **التوافق مع الويب**: استخدام مكتبات متوافقة مع المتصفحات (مثل `XFile` للصور).
3. **لا تكرار للكود (DRY)**: الوظائف المشتركة توضع في `lib/core/services`.
4. **دقة البيانات**: لا يتم افتراض أسماء الأعمدة؛ يجب مراجعة `04_DATABASE_DESIGN.md` دائماً.

---

## 9. Deployment & Hosting (النشر)
- **GitHub**: المستودع الرئيسي `aliyaseenhasn-hue/astshara`.
- **Hosting**: يتم النشر تلقائياً عبر GitHub Actions إلى GitHub Pages.
- **Site URL**: `https://aliyaseenhasn-hue.github.io/astshara/`.

---

## 10. Final Audit & Readiness Status
التطبيق حالياً في حالة **Production Ready (Conditional)**.
- **الثغرات المعالجة**: منع تصعيد الصلاحيات، تأمين المجلدات العامة، حماية البيانات الحساسة عبر Views.
- **المتطلبات المتبقية**: ترقية حساب Twilio لاستقبال رسائل حقيقية خارج وضع الاختبار.

---
**نهاية الملف - المرجع الشامل لمشروع استشارة**
