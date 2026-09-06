# astshara

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Latest Production Fix — Lawyer WhatsApp Booking Eligibility

- Migration: `supabase/migrations/20260906153000_fix_lawyer_whatsapp_source_for_booking.sql`
- Repository commit: `d81cbda03d8ebd2f2d25cd5c9d0be8e0409235a5`
- Root cause: the booking RPC checked only `lawyer_profiles.whatsapp`, while the lawyer profile flow can persist the WhatsApp number in `profiles.whatsapp_number`. This caused a valid lawyer with a saved WhatsApp number to be rejected for remote consultation requests.
- Fix: `create_booking` now uses `lawyer_profiles.whatsapp` first and falls back to the verified lawyer's `profiles.whatsapp_number`.
- Supabase production migration: applied successfully.
- Database verification: the affected data pattern was reproduced (`profiles.whatsapp_number` populated while `lawyer_profiles.whatsapp` was null), and the deployed `create_booking` definition was verified to contain the fallback.
- Scope: no change to payment, authentication, availability, consultation modes, or booking ownership rules.
