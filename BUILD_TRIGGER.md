# CI trigger

This file intentionally triggers the repository CI/Android/PWA workflows after the latest verified changes.

## Production audit — 2026-09-06
- Applied `20260906173000_optimize_rls_auth_checks_and_remove_duplicate_indexes.sql` to production Supabase.
- Applied `20260906174500_consolidate_financial_select_rls_policies.sql` to production Supabase.
- The first migration removed confirmed duplicate indexes and optimized repeated `auth.uid()` evaluation in RLS policies.
- The second migration consolidated equivalent participant/admin SELECT policies for financial ledger and payment financials while preserving access rules.
- Supabase Performance Advisor was rechecked: the previous `auth_rls_initplan` and duplicate-index warnings are no longer present; remaining findings are INFO unused-index notices plus a small set of intentionally separate policy groups that require further semantic review before removal.
