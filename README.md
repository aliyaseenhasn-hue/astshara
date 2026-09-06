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

## Production Audit — 2026-09-06

- Latest main-branch CI run: `34043144047` — **SUCCESS** (analyze/tests/build/deployment workflow completed successfully).
- Latest verified commit: `c1d164a34bb88eee9b38bca7352b62df1030f8f8` (`fix: import go_router for booking action navigation`).
- Public database tables were checked: all exposed `public` tables currently have RLS enabled.
- Booking/payment authorization was rechecked after the booking hardening work. Direct payment INSERT remains blocked by RLS, while payment submission is performed through the guarded `submit_payment` RPC.
- Supabase security-advisor findings were reviewed. The remaining `SECURITY DEFINER` warnings are concentrated on intentionally callable application RPCs whose function bodies contain role/ownership checks, plus the two intentionally public lawyer-directory RPCs. They are not being blindly revoked because doing so would break the existing authenticated booking/admin flows.
- `telegram_login_requests` intentionally has RLS enabled without direct table policies; the application accesses it through trusted security-definer functions. No direct table access was added.
- Supabase Auth currently reports leaked-password protection as disabled. This is an Auth project setting rather than repository code; it must be enabled from the Supabase Auth security settings before the production security audit can be marked fully clean.
- The security advisor also reports anonymous-access policy warnings. These are tied to the project's authenticated-role policy model/anonymous-sign-in setting and require verification of the Auth anonymous-sign-in configuration before changing any RLS policy. No destructive RLS changes were made.
- Storage policies were reviewed for avatars, lawyer documents, lawyer achievements, and receipts. Ownership checks are present for writes; receipt and lawyer-document reads are restricted to the owner or admin/moderator.
- No Telegram flow was changed.
- Qi Card integration remains configuration-dependent; no production credentials or payment behavior were fabricated or changed.

## Latest Production Fix — Booking Actions

- Repository commit: `f24fb0e74c4e3dbf9c0a32ff4c5d7d3b409acd8a`
- Root cause: the booking details route wrapped the core details page with cancellation state, but review/cancellation actions were not reliably exposed as a single actionable flow; client cancellation was also missing from the details route.
- Fix: added a guarded action layer for lawyer approval/rejection and cancellation requests, added client cancellation for eligible future bookings, prevented duplicate submissions while an action is running, and invalidated booking providers after successful state changes.
- Database: existing `review_booking`, `request_booking_cancellation`, and `change_booking_status` RPC authorization was preserved; no public execute grants were added.
- Verification: Supabase production RPCs were inspected and their `authenticated` execute grants were verified while `anon` execute remained disabled. `review_booking` was also exercised inside a transaction and rolled back successfully.
- CI: the later main-branch workflow `34043144047` completed successfully, including the analyze/tests/build/deployment pipeline.

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
