# 02_TECH_STACK.md

# 🏗️ LawConnect Technology Stack

Version 2.0

Flutter + Supabase Edition

---

# الهدف

اختيار Stack حديث يمكنه تشغيل التطبيق بالكامل دون Backend مستقل.

يعتمد المشروع على:

Flutter

+

Supabase

فقط.

---

# المبادئ الأساسية

✅ Single Codebase

✅ Clean Architecture

✅ Feature First

✅ Production Ready

✅ Offline Ready

✅ AI Friendly

---

# المنصات المدعومة

- Android
- iOS
- Web
- Progressive Web App (PWA)

جميعها من نفس المشروع.

---

# Frontend

Framework

Flutter Stable

---

Language

Dart 3

---

UI

Material 3

---

RTL

مدعوم بالكامل.

---

Responsive

إجباري.

يجب أن يعمل التطبيق على:

- الهاتف
- التابلت
- الويب

---

# Backend

لا يوجد Backend مستقل.

يعتمد المشروع بالكامل على

Supabase

---

# Database

Supabase PostgreSQL

يمنع استخدام

SQLite

كقاعدة بيانات رئيسية.

يسمح بها فقط في الاختبارات.

---

# Authentication

Supabase Auth

طرق التسجيل:

- الهاتف
- Google
- Apple (iOS)
- Email (اختياري)

---

# Realtime

Supabase Realtime

يستخدم في:

- المحادثات
- حالة الاتصال
- تحديثات الحجز
- الإشعارات داخل التطبيق

---

# Storage

Supabase Storage

Buckets

avatars

lawyer_documents

receipts

chat_files

attachments

---

# Edge Functions

تستخدم فقط في العمليات الحساسة.

مثل

- التحقق من الدفع
- إرسال OTP
- الإشعارات الجماعية
- Webhooks

---

# Push Notifications

Firebase Cloud Messaging

FCM

---

# Analytics

Firebase Analytics

---

# Crash Reports

Firebase Crashlytics

---

# State Management

Riverpod

هو النظام الوحيد المعتمد.

---

ممنوع استخدام

Provider

---

Bloc

---

GetX

---

MobX

---

Redux

---

# Navigation

GoRouter

جميع التنقلات يجب أن تتم من خلاله.

---

# Dependency Injection

Riverpod Providers

ولا يستخدم

GetIt

إلا إذا دعت الحاجة مستقبلاً.

---

# Local Storage

Hive

للبيانات المحلية.

---

Flutter Secure Storage

لتخزين

JWT

Refresh Token

Encryption Keys

---

Shared Preferences

للإعدادات البسيطة فقط.

---

# Serialization

json_serializable

---

Freezed

للنماذج.

---

build_runner

لتوليد الكود.

---

# الصور

cached_network_image

---

image_picker

---

image_cropper

---

flutter_image_compress

---

# الخرائط

google_maps_flutter

---

geolocator

---

geocoding

---

# الملفات

file_picker

---

open_filex

---

pdf

---

printing

---

# الروابط

url_launcher

---

share_plus

---

# الاتصال

connectivity_plus

---

internet_connection_checker_plus

---

# الأذونات

permission_handler

---

# التاريخ

intl

---

timeago

---

# البحث

debounce_throttle

---

# QR

mobile_scanner

---

qr_flutter

---

# التشفير

crypto

---

encrypt

---

# Logging

logger

---

# البيئة

flutter_dotenv

---

# Testing

flutter_test

mocktail

integration_test

---

# Lint

flutter_lints

very_good_analysis

---

# Architecture

lib/

core/

features/

shared/

main.dart

---

داخل كل Feature

data/

domain/

presentation/

---

داخل Data

datasources

repositories

models

---

داخل Domain

entities

repositories

usecases

---

داخل Presentation

pages

widgets

controllers

providers

---

# Naming Convention

Files

snake_case

مثال

booking_repository.dart

---

Classes

PascalCase

BookingRepository

---

Variables

camelCase

bookingId

---

Constants

UPPER_SNAKE_CASE

MAX_UPLOAD_SIZE

---

Folders

snake_case

---

# Performance Rules

Pagination

إجباري.

---

Lazy Loading

إجباري.

---

Caching

إجباري.

---

Infinite Scroll

إجباري.

---

Image Compression

إجباري.

---

Optimistic UI

يفضل استخدامه.

---

# Security

لا يتم تخزين

Service Role Key

داخل Flutter.

مطلقاً.

---

Anon Key

هو المفتاح الوحيد المسموح.

---

جميع العمليات الحساسة

داخل Edge Functions.

---

# Offline

يجب أن يعمل التطبيق جزئياً بدون إنترنت.

يشمل

- آخر المحادثات
- آخر البيانات
- الملف الشخصي
- الإعدادات

---

# Code Quality

SOLID

DRY

KISS

YAGNI

Clean Code

Production Ready

---

# ممنوعات

❌ إنشاء REST API بدون سبب.

❌ إنشاء Backend مستقل.

❌ تخزين كلمات المرور.

❌ استدعاء قاعدة البيانات من Widgets.

❌ وضع Business Logic داخل UI.

❌ نسخ الكود بين Features.

---

# قاعدة المشروع الذهبية

إذا كانت الوظيفة مدعومة داخل Supabase

فلا يتم إنشاء Backend لها.

---

# نهاية الملف