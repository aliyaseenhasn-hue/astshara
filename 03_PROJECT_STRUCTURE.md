# 03_PROJECT_STRUCTURE.md

# 📁 LawConnect Project Structure

Version 2.0

Flutter + Supabase Edition

---

# الهدف

يهدف هذا الهيكل إلى:

- سهولة التوسع
- سهولة الصيانة
- سهولة الاختبار
- فصل المسؤوليات
- دعم Clean Architecture
- دعم Feature First Architecture

كل ميزة (Feature) تعتبر مشروعًا مستقلاً داخل التطبيق.

---

# الهيكل العام

```
lawconnect/

│
├── android/
├── ios/
├── web/
├── linux/
├── macos/
├── windows/
│
├── assets/
│
├── docs/
│
├── scripts/
│
├── test/
│
├── integration_test/
│
├── lib/
│
└── pubspec.yaml
```

---

# مجلد Assets

```
assets/

images/

icons/

logos/

animations/

fonts/

translations/

lottie/

placeholders/

defaults/
```

---

# مجلد Documentation

```
docs/

00_INDEX.md

01_MASTER_BUILD_PROMPT.md

02_TECH_STACK.md

03_PROJECT_STRUCTURE.md

04_DATABASE_DESIGN.md

...
```

---

# مجلد Scripts

```
scripts/

seed_database.dart

generate_icons.dart

generate_splash.dart

backup_database.dart
```

---

# مجلد الاختبارات

```
test/

unit/

widget/

repositories/

usecases/

features/

core/
```

---

# Integration Tests

```
integration_test/

auth/

booking/

chat/

payments/

lawyers/

admin/
```

---

# مجلد lib

```
lib/

core/

features/

shared/

app/

main.dart
```

---

# مجلد app

```
app/

app.dart

router.dart

theme.dart

providers.dart

bootstrap.dart

constants.dart
```

---

# مجلد Core

يحتوي على كل ما يستخدمه المشروع بالكامل.

```
core/

config/

constants/

errors/

exceptions/

extensions/

helpers/

mixins/

services/

utils/

validators/

network/

storage/

theme/

widgets/

localization/

permissions/

logging/
```

---

## Config

```
config/

environment.dart

supabase.dart

firebase.dart

app_config.dart
```

---

## Constants

```
constants/

app_colors.dart

app_sizes.dart

app_spacing.dart

api_constants.dart

storage_keys.dart
```

---

## Services

```
services/

notification_service.dart

location_service.dart

storage_service.dart

camera_service.dart

share_service.dart

permission_service.dart
```

---

## Utils

```
utils/

date_utils.dart

money_utils.dart

phone_utils.dart

image_utils.dart

validator_utils.dart
```

---

## Widgets المشتركة

```
widgets/

app_button.dart

app_card.dart

app_dialog.dart

loading_widget.dart

empty_widget.dart

error_widget.dart

network_image.dart

search_bar.dart
```

---

# Shared

كل ما يستخدمه أكثر من Feature.

```
shared/

models/

entities/

repositories/

providers/

widgets/
```

---

# Features

```
features/

authentication/

home/

lawyers/

bookings/

consultations/

chat/

payments/

reviews/

notifications/

profile/

settings/

admin/

search/

favorites/

support/
```

كل Feature مستقلة تمامًا.

---

# هيكل أي Feature

مثال

```
authentication/

data/

domain/

presentation/
```

---

## Data

```
data/

datasources/

models/

repositories/
```

---

### Datasources

```
datasources/

auth_remote_datasource.dart

auth_local_datasource.dart
```

---

### Models

```
models/

user_model.dart

session_model.dart

otp_model.dart
```

---

### Repository Implementation

```
repositories/

auth_repository_impl.dart
```

---

# Domain

```
domain/

entities/

repositories/

usecases/
```

---

## Entities

```
entities/

user.dart

session.dart
```

---

## Repository Interface

```
repositories/

auth_repository.dart
```

---

## UseCases

```
usecases/

login.dart

logout.dart

signup.dart

verify_otp.dart

refresh_token.dart
```

---

# Presentation

```
presentation/

pages/

widgets/

providers/

controllers/

dialogs/

bottom_sheets/
```

---

## Pages

```
pages/

login_page.dart

signup_page.dart

otp_page.dart
```

---

## Widgets

```
widgets/

phone_field.dart

otp_box.dart

google_button.dart

apple_button.dart
```

---

## Providers

```
providers/

auth_provider.dart

session_provider.dart
```

---

# مثال Feature المحامين

```
lawyers/

data/

domain/

presentation/
```

داخلها

```
pages/

lawyers_page.dart

lawyer_details_page.dart

edit_profile_page.dart

verification_page.dart
```

---

# مثال Feature الحجوزات

```
bookings/

pages/

create_booking_page.dart

booking_details_page.dart

booking_history_page.dart
```

---

# مثال Feature المحادثات

```
chat/

pages/

chat_page.dart

conversation_page.dart
```

---

داخل Widgets

```
message_bubble.dart

typing_indicator.dart

voice_message.dart

attachment_widget.dart
```

---

# مثال Feature الإدارة

```
admin/

dashboard/

users/

lawyers/

payments/

bookings/

reports/

settings/
```

---

# Routing

جميع الصفحات تعرف داخل

```
router.dart
```

ويمنع إنشاء Navigator يدوي.

---

# Assets Naming

```
logo.png

logo_dark.png

empty_chat.png

avatar_placeholder.png
```

---

# Feature Rules

كل Feature يجب أن تحتوي فقط على:

Data

Domain

Presentation

ولا يسمح بإضافة مجلدات عشوائية.

---

# Dependency Rules

Presentation

↓

Domain

↓

Repository

↓

Datasource

↓

Supabase

ولا يسمح بالعكس.

---

# Import Rules

Feature لا تستورد Feature أخرى مباشرة.

إذا احتاجت ذلك

يستخدم Shared أو Domain Interface.

---

# State Management

كل Feature تمتلك Providers الخاصة بها.

ولا يسمح باستخدام Provider عالمي إلا للآتي:

- المستخدم الحالي
- الثيم
- اللغة
- الاتصال
- الإشعارات

---

# Naming Rules

Pages

تنتهي بـ

Page

مثال

```
HomePage
```

---

Widgets

تنتهي بـ

Widget

```
BookingCardWidget
```

---

Providers

تنتهي بـ

Provider

---

Repositories

تنتهي بـ

Repository

---

Models

تنتهي بـ

Model

---

Entities

بدون أي لاحقة.

---

# قاعدة ذهبية

كل ملف يجب أن تكون له مسؤولية واحدة فقط.

Single Responsibility Principle

---

# نهاية الملف