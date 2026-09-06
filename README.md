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

## Latest Production Fix — Booking Actions

- Repository commit: `f24fb0e74c4e3dbf9c0a32ff4c5d7d3b409acd8a`
- Root cause: the booking details route wrapped the core details page with cancellation state, but review/cancellation actions were not reliably exposed as a single actionable flow; client cancellation was also missing from the details route.
- Fix: added a guarded action layer for lawyer approval/rejection and cancellation requests, added client cancellation for eligible future bookings, prevented duplicate submissions while an action is running, and invalidated booking providers after successful state changes.
- Database: existing `review_booking`, `request_booking_cancellation`, and `change_booking_status` RPC authorization was preserved; no public execute grants were added.
- Verification: Supabase production RPCs were inspected and their `authenticated` execute grants were verified while `anon` execute remained disabled. `review_booking` was also exercised inside a transaction and rolled back successfully.
- CI: GitHub Actions run `34037317840` is currently executing analyze/build verification for this commit; final CI status is intentionally not marked PASS until completion.

## Latest Production Fix — PWA Notification State

- Repository commit: `6163de41167b005a982603a01db558bae5a4299c`
- Root cause: the PWA notification service exposed `isEnabled()` on the web implementation but not on the non-web stub, which caused Flutter analysis/build failures and prevented the corrected web notification behavior from being deployed.
- Fix: aligned the notification service API across web and non-web platforms by adding `isEnabled()` to the stub and keeping the settings screen state synchronized after enable/disable operations.
- Web behavior: the service reads both browser notification permission and the active Push API subscription before reporting notifications as enabled.
- Security: the existing `pwa_push_subscriptions` RLS policy remains scoped to `auth.uid() = user_id`; no public access was added.
- Verification: GitHub Actions run `34036615327` completed successfully for build, analysis/tests, and GitHub Pages deployment.
- Scope: no authentication, Telegram, booking, payment, database schema, or existing PWA subscription security rules were weakened.

## Latest Production Fix — Consultation Type Compatibility

- Migration: `supabase/migrations/20260906160000_normalize_video_consultation_type_for_booking.sql`
- Repository commit: `197e37f1acbedba7e075554dc0fbe9ee0e8702c2`
- Root cause: the booking screen sends the Arabic label `مرئية` for video consultation, while the booking RPC validates the canonical value `فيديو`.
- Fix: `create_booking` now normalizes `مرئية` to `فيديو` before validation and storage, and accepts existing package configurations that still advertise `مرئية` as the video alias.
- Supabase production migration: applied successfully.
- Database verification: the deployed function was updated successfully; the normalization and compatibility rules are present.
- Scope: no change to authentication, WhatsApp eligibility, lawyer availability, slot locking, payment state, or booking ownership rules.

## Latest Security Hardening — Booking Archive/Restore RPCs

- Migration: `supabase/migrations/20260906162000_lock_down_booking_archive_restore_functions.sql`
- Root cause: `archive_booking_for_user(uuid)` and `restore_booking_from_archive(uuid)` had unnecessary SQL EXECUTE grants to `anon` and `authenticated` even though these operations are intended for trusted application flows.
- Fix: revoked EXECUTE from `anon`, `authenticated`, and `public`; retained `service_role` for trusted maintenance paths.
- Supabase production migration: applied successfully.
- Database verification: `anon_exec=false`, `auth_exec=false`, `service_exec=true` for both functions.
- Scope: no booking data, archive logic, ownership predicates, authentication flow, Telegram flow, or payment integration was changed.
