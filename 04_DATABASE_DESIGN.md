# 04_DATABASE_DESIGN.md

# 🗄️ LawConnect Database Design

Version 2.0

Flutter + Supabase Edition

Database Engine

PostgreSQL (Supabase)

---

# الهدف

تصميم قاعدة بيانات:

- قابلة للتوسع
- عالية الأداء
- آمنة
- سهلة الصيانة
- مناسبة لمئات الآلاف من المستخدمين

---

# القواعد العامة

## UUID

جميع الجداول تستخدم

UUID

كمفتاح رئيسي.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

---

## Timestamps

كل جدول يحتوي على:

```sql
created_at TIMESTAMPTZ DEFAULT now()

updated_at TIMESTAMPTZ DEFAULT now()
```

---

## Soft Delete

لا يتم حذف البيانات المهمة.

يستخدم:

```sql
deleted_at TIMESTAMPTZ NULL
```

---

## Audit Fields

كل جدول يحتوي على

```
created_by

updated_by
```

عند الحاجة.

---

# الجداول

## profiles

تمثل جميع مستخدمي النظام.

---

Columns

```
id

auth_id

role

full_name

phone

email

avatar

city

address

birth_date

gender

language

is_verified

status

created_at

updated_at
```

---

Role

```
user

lawyer

admin

moderator
```

---

Status

```
active

blocked

pending

deleted
```

---

# lawyer_profiles

يمثل بيانات المحامين.

---

Columns

```
id

profile_id

license_number

bar_association

bio

years_experience

consultation_price

office_name

office_address

office_phone

latitude

longitude

rating

review_count

verified

availability

created_at

updated_at
```

---

Relationship

```
profiles

1

↓

1

lawyer_profiles
```

---

# lawyer_specializations

```
id

name

icon

color

sort_order

active
```

---

Examples

```
مدني

جزائي

أحوال شخصية

إداري

تجاري

ضريبي

عمال

نفط وغاز

استثمار

عقارات
```

---

# lawyer_specialization_items

Pivot Table

```
id

lawyer_id

specialization_id
```

---

# lawyer_documents

```
id

lawyer_id

document_type

file_url

status

reviewed_by

reviewed_at

notes
```

---

Document Types

```
National ID

Bar License

Personal Photo

Office License

Other
```

---

Status

```
Pending

Approved

Rejected
```

---

# bookings

```
id

user_id

lawyer_id

consultation_type

status

scheduled_at

description

price

payment_status

created_at

updated_at
```

---

Consultation Types

```
Text

Voice

Video

Office Visit
```

---

Booking Status

```
Pending

Accepted

Rejected

Cancelled

Completed
```

---

Payment Status

```
Pending

Paid

Rejected

Refunded
```

---

# consultations

```
id

booking_id

started_at

ended_at

status
```

---

Status

```
Waiting

Active

Completed

Cancelled
```

---

# conversations

```
id

booking_id

user_id

lawyer_id

last_message

last_message_time

created_at
```

---

# messages

```
id

conversation_id

sender_id

message_type

message

attachment

is_read

created_at
```

---

Message Types

```
Text

Image

PDF

Audio

Video

Location

File
```

---

# payments

```
id

booking_id

amount

payment_method

transaction_number

receipt

status

verified_by

verified_at

created_at
```

---

Payment Methods

```
Bank Transfer

Qi Card

ZainCash

Asia Hawala

Cash
```

---

# reviews

```
id

booking_id

user_id

lawyer_id

rating

comment

created_at
```

---

Rating

```
1

2

3

4

5
```

---

# notifications

```
id

user_id

title

body

type

is_read

created_at
```

---

Types

```
Booking

Payment

Message

Review

System

Admin
```

---

# favorites

```
id

user_id

lawyer_id

created_at
```

---

# reports

بلاغات المستخدمين.

```
id

reporter_id

target_user

reason

status

notes
```

---

# app_settings

إعدادات النظام.

```
id

key

value
```

---

# banners

```
id

title

image

url

active

sort_order
```

---

# faq

```
id

question

answer

sort_order
```

---

# contact_messages

```
id

name

email

phone

subject

message

status
```

---

# relationships

```
Profile

↓

Lawyer Profile

↓

Bookings

↓

Consultation

↓

Conversation

↓

Messages
```

---

```
Profile

↓

Favorites

↓

Lawyers
```

---

```
Profile

↓

Reviews

↓

Lawyers
```

---

# Indexes

يجب إنشاء Index على:

```
phone

email

role

status

lawyer_id

user_id

booking_id

conversation_id

created_at
```

---

Full Text Search

يفعل على:

```
Lawyer Name

Bio

Office Name

Specialization
```

---

# Triggers

## تحديث updated_at

عند كل عملية تحديث.

---

## تحديث التقييم

بعد كل Review جديد.

---

## إنشاء Profile

بعد التسجيل مباشرة.

---

## إنشاء Conversation

بعد قبول الحجز.

---

## حذف الملفات

عند حذف السجل.

---

## إرسال Notification

بعد:

- الحجز
- الرسائل
- الدفع
- قبول المحامي

---

# Views

```
lawyers_view

top_lawyers_view

active_bookings_view

payments_view

dashboard_statistics
```

---

# Constraints

```
Phone Unique

Email Unique

License Number Unique

One Review Per Booking

One Consultation Per Booking
```

---

# قواعد الأداء

- استخدام Pagination في جميع الاستعلامات.
- عدم استخدام `SELECT *`.
- تحديد الأعمدة المطلوبة فقط.
- استخدام Indexes في جميع الحقول المستخدمة للبحث.
- استخدام Full Text Search للبحث عن المحامين.

---

# قاعدة ذهبية

لا يتم الوصول إلى الجداول مباشرة من واجهة المستخدم، بل عبر طبقة Repository باستخدام Supabase SDK.

---

# نهاية الملف