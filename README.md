# astshara

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Learn Flutter](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
examples, guidance on mobile development, and a full API reference.

## Latest Production Fix — Consultation Type Compatibility

- Migration: `supabase/migrations/20260906160000_normalize_video_consultation_type_for_booking.sql`
- Repository commit: `197e37f1acbedba7e075554dc0fbe9ee0e8702c2`
- Root cause: the booking screen sends the Arabic label `مرئية` for video consultation, while the booking RPC validates the canonical value `فيديو`.
- Fix: `create_booking` now normalizes `مرئية` to `فيديو` before validation and storage. This preserves the existing database value and package compatibility rules.
- Supabase production migration: applied successfully.
- Database verification: the deployed function definition was checked and contains the normalization rule.
- Scope: no change to authentication, WhatsApp eligibility, lawyer availability, slot locking, payment state, or booking ownership rules.
