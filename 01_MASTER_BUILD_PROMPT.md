# 01_MASTER_BUILD_PROMPT.md

# 🎯 LawConnect — MASTER BUILD PROMPT
## المرجع الوحيد الذي يجب على أي مساعد برمجي اتباعه

الإصدار

2.0

Flutter + Supabase Edition

---

# اقرأ هذا الملف أولاً

أنت مهندس برمجيات خبير مكلف ببناء تطبيق

LawConnect

من الصفر وحتى النشر.

هذا الملف هو

Single Source of Truth

للمشروع.

لا يجوز اتخاذ أي قرار يخالف هذا الملف إلا إذا طلب المستخدم ذلك صراحة.

---

# طريقة العمل

في بداية كل جلسة يجب تنفيذ الخطوات التالية بالترتيب.

## 1

اقرأ الملف

11_PROGRESS_TRACKER.md

بالكامل.

---

## 2

ابحث عن أول مهمة غير منجزة.

---

## 3

ابدأ منها فقط.

---

## 4

لا تنتقل إلى أي مهمة أخرى.

---

## 5

بعد الانتهاء

اختبر الكود فعلياً.

لا تفترض أنه يعمل.

---

## 6

حدّث Progress Tracker.

---

## 7

اذكر للمستخدم:

ما الذي تم إنجازه.

ما هي الخطوة التالية.

---

# ممنوعات

ممنوع استخدام

Django

---

ممنوع استخدام

NodeJS

---

ممنوع استخدام

Express

---

ممنوع استخدام

Laravel

---

ممنوع إنشاء Backend مستقل.

---

ممنوع إنشاء REST API إذا كان Supabase يوفر الخدمة.

---

ممنوع كتابة كود غير مستخدم.

---

ممنوع تكرار الكود.

---

ممنوع إنشاء ملفات ضخمة تحتوي أكثر من مسؤولية.

---

# التكنولوجيا النهائية

Frontend

Flutter Stable

---

Language

Dart

---

Architecture

Clean Architecture

---

Folder Strategy

Feature First

---

State Management

Riverpod

---

Dependency Injection

Riverpod Providers

---

Navigation

GoRouter

---

Backend

Supabase فقط

---

Database

PostgreSQL

---

Authentication

Supabase Auth

---

Realtime

Supabase Realtime

---

Storage

Supabase Storage

---

Functions

Supabase Edge Functions

---

Notifications

Firebase Cloud Messaging

---

Crash Reports

Firebase Crashlytics

---

Analytics

Firebase Analytics

---

Deep Links

App Links

Universal Links

---

Supported Platforms

Android

iOS

Web

PWA

---

# تصميم المشروع

كل ميزة تعتبر Feature مستقلة.

مثال

Authentication

Lawyers

Bookings

Chat

Payments

Reviews

Admin

Notifications

Settings

لكل Feature

Data

Domain

Presentation

---

# قاعدة ذهبية

لا يسمح لأي Feature بمعرفة تفاصيل Feature أخرى.

التواصل يكون عبر

Repositories

و

UseCases

فقط.

---

# Naming Rules

الكلاسات

PascalCase

---

المتغيرات

camelCase

---

الملفات

snake_case

---

الثوابت

UPPER_SNAKE_CASE

---

# جودة الكود

يجب أن يكون

Readable

Reusable

Scalable

Testable

Maintainable

Production Ready

Null Safe

Responsive

Offline Ready

---

# معايير التصميم

Material 3

RTL كامل

Dark Mode

Light Mode

Adaptive UI

Accessibility

---

# قاعدة البيانات

لا يتم الوصول مباشرة للجداول من واجهة المستخدم.

جميع العمليات تمر عبر

Repository

↓

Datasource

↓

Supabase

---

# المصادقة

المستخدم يستطيع التسجيل بواسطة

رقم الهاتف

Google

Apple

(Apple يفعّل عند نشر iOS)

---

بعد التسجيل

ينشأ Profile تلقائياً.

---

الصلاحيات

User

Lawyer

Admin

Moderator

---

# المحامون

يمكن للمحامي

رفع صورة

رفع هوية

رفع هوية النقابة

رفع إجازة المحاماة

إضافة السيرة الذاتية

التخصصات

سنوات الخبرة

سعر الاستشارة

حالة التوفر

---

لا يظهر المحامي داخل البحث

حتى تتم الموافقة عليه.

---

# العملاء

يمكنهم

البحث

الحجز

المحادثة

الدفع

التقييم

---

# المحادثة

Realtime

Typing Indicator

Read Receipts

Online Status

Push Notifications

---

# الدفع

يدعم أكثر من مزود.

لكن داخل MVP

يعتمد رفع إيصال الدفع.

---

# لوحة الإدارة

إدارة المستخدمين

إدارة المحامين

إدارة الحجوزات

إدارة المدفوعات

إدارة البلاغات

إدارة الإشعارات

إدارة التخصصات

إدارة الصفحات

إدارة الإعدادات

---

# الأمن

Row Level Security

إجباري.

---

لا يسمح باستخدام Service Role Key داخل Flutter.

---

جميع المفاتيح السرية

تستخدم داخل Edge Functions فقط.

---

# التخزين

يتم تقسيم الملفات إلى Buckets

avatars

lawyer_documents

receipts

chat_files

attachments

---

# الأداء

Pagination

Lazy Loading

Caching

Image Compression

Infinite Scroll

Debounce Search

Optimistic Updates

---

# الاختبارات

Unit Tests

Widget Tests

Integration Tests

Manual Tests

---

# قاعدة صارمة

لا يتم اعتبار أي Feature مكتملة

حتى يتم

تشغيلها

واختبارها

فعلياً.

---

# التسليم

بعد كل جلسة

يجب تحديث

Progress Tracker

وذكر

ما الذي اكتمل

وما هي المهمة التالية.

---

# نهاية الملف