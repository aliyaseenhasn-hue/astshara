# 00_INDEX.md

# 📚 LawConnect Documentation Index

Version: 2.0 (Flutter + Supabase Edition)

Last Updated: July 2026

---

# 🎯 Project Overview

LawConnect هو تطبيق قانوني احترافي يربط العملاء بالمحامين داخل العراق.

تم تصميم المشروع وفق مفهوم:

> **Single Codebase**
>
> Flutter + Supabase

بدون أي Backend مستقل مثل:

- Django
- Laravel
- Node.js
- NestJS
- Express

جميع الخدمات الخلفية تعتمد على Supabase.

---

# الهدف

بناء منصة قانونية احترافية يمكن تشغيلها على:

✅ Android

✅ iPhone

✅ Web

✅ PWA

من قاعدة كود واحدة.

---

# التقنيات المعتمدة

Frontend

- Flutter Stable

Database

- Supabase PostgreSQL

Authentication

- Supabase Auth

Storage

- Supabase Storage

Realtime

- Supabase Realtime

Functions

- Supabase Edge Functions

Notifications

- Firebase Cloud Messaging

Maps

- Google Maps

Payments

- حسب بوابة الدفع العراقية التي سيتم اختيارها لاحقاً.

---

# Architecture

يعتمد المشروع على

Clean Architecture

مع

Feature First Architecture

وليس Layer First.

---

# State Management

Riverpod

---

# Routing

GoRouter

---

# Networking

Supabase SDK

ولا يتم استخدام REST APIs إلا عند الحاجة.

---

# Local Storage

Hive

Flutter Secure Storage

Shared Preferences

---

# المشروع مقسم إلى الملفات التالية

00_INDEX.md

فهرس المشروع

---

01_MASTER_BUILD_PROMPT.md

المرجع الوحيد للمساعد البرمجي.

يجب قراءته قبل كتابة أي سطر كود.

---

02_TECH_STACK.md

جميع التقنيات المستخدمة وأسباب اختيارها.

---

03_PROJECT_STRUCTURE.md

هيكل المشروع بالكامل.

---

04_DATABASE_DESIGN.md

تصميم قاعدة البيانات.

الجداول

العلاقات

الفهارس

Triggers

Views

---

05_SUPABASE_RLS.md

سياسات الأمان.

Row Level Security.

Policies.

Permissions.

---

06_AUTHENTICATION.md

التسجيل

OTP

Google

Apple

Sessions

Roles

---

07_STORAGE.md

إدارة الملفات.

صور المستخدمين.

صور المحامين.

الوثائق.

الإيصالات.

---

08_REALTIME_CHAT.md

نظام المحادثات.

Realtime.

Presence.

Typing.

Read Receipts.

---

09_FEATURES_SPECIFICATION.md

جميع خصائص التطبيق بالتفصيل.

---

10_UI_UX_GUIDELINES.md

التصميم.

Material 3

RTL

Accessibility

Dark Mode

---

11_PROGRESS_TRACKER.md

خطة التنفيذ خطوة بخطوة.

لا يجوز تخطي أي مرحلة.

---

12_CODING_STANDARDS.md

معايير كتابة الكود.

Lint Rules.

Naming.

Folder Rules.

Architecture Rules.

---

13_TESTING.md

اختبارات المشروع.

Unit Tests

Widget Tests

Integration Tests

Manual Tests

---

14_DEPLOYMENT.md

طريقة النشر.

Android

iOS

Web

PWA

---

15_ADMIN_PANEL.md

لوحة الإدارة داخل Flutter.

---

16_AI_DEVELOPMENT_RULES.md

القواعد التي يجب أن يلتزم بها أي ذكاء اصطناعي أثناء البرمجة.

---

17_FUTURE_ROADMAP.md

خطة التطوير بعد إطلاق MVP.

---

# ترتيب القراءة

أي مساعد برمجي يجب أن يقرأ الملفات بهذا الترتيب:

1

00_INDEX.md

↓

2

01_MASTER_BUILD_PROMPT.md

↓

3

02_TECH_STACK.md

↓

4

03_PROJECT_STRUCTURE.md

↓

5

04_DATABASE_DESIGN.md

↓

بقية الملفات حسب الحاجة.

---

# قواعد صارمة

❌ لا يتم إنشاء Backend خارجي.

❌ لا يتم استخدام Django.

❌ لا يتم استخدام Next.js.

❌ لا يتم استخدام Firebase Database.

❌ لا يتم استخدام REST API خارجي إلا إذا تعذر تنفيذ الوظيفة داخل Supabase.

---

# قاعدة المشروع الذهبية

إذا أمكن تنفيذ الميزة داخل Supabase

فيجب تنفيذها داخل Supabase

ولا يتم إنشاء Backend مستقل.

---

# جودة الكود

يجب أن يكون الكود:

Production Ready

Clean

SOLID

Scalable

Maintainable

Testable

Null Safe

Responsive

Offline Ready

AI Friendly

---

# نهاية الملف