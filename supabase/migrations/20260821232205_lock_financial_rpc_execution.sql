revoke execute on function public.admin_complete_payout(uuid,text,text,text) from public,anon,authenticated;
revoke execute on function public.admin_set_commission_rate(numeric) from public,anon,authenticated;
revoke execute on function public.ensure_financial_accounting_for_payment(uuid) from public,anon,authenticated;
revoke execute on function public.release_lawyer_earnings_for_completed_booking(uuid) from public,anon,authenticated;
revoke execute on function public.request_lawyer_payout(numeric) from public,anon;
revoke execute on function public.sync_financial_payment_trigger() from public,anon,authenticated;
revoke execute on function public.settle_oldest_lawyer_penalties_for_payment(uuid) from public,anon,authenticated;
grant execute on function public.request_lawyer_payout(numeric) to authenticated;
grant execute on function public.admin_complete_payout(uuid,text,text,text) to authenticated;
grant execute on function public.admin_set_commission_rate(numeric) to authenticated;

drop policy if exists financial_ledger_admin on public.financial_ledger;
drop policy if exists financial_ledger_lawyer_select on public.financial_ledger;
drop policy if exists financial_ledger_client_select on public.financial_ledger;
create policy financial_ledger_admin on public.financial_ledger for select to authenticated using (exists(select 1 from public.profiles where auth_id=auth.uid() and role='admin'));
create policy financial_ledger_lawyer_select on public.financial_ledger for select to authenticated using (lawyer_id=(select id from public.profiles where auth_id=auth.uid()));
create policy financial_ledger_client_select on public.financial_ledger for select to authenticated using (client_id=(select id from public.profiles where auth_id=auth.uid()));

drop policy if exists payment_financials_admin on public.payment_financials;
drop policy if exists payment_financials_lawyer_select on public.payment_financials;
drop policy if exists payment_financials_client_select on public.payment_financials;
create policy payment_financials_admin on public.payment_financials for select to authenticated using (exists(select 1 from public.profiles where auth_id=auth.uid() and role='admin'));
create policy payment_financials_lawyer_select on public.payment_financials for select to authenticated using (lawyer_id=(select id from public.profiles where auth_id=auth.uid()));
create policy payment_financials_client_select on public.payment_financials for select to authenticated using (client_id=(select id from public.profiles where auth_id=auth.uid()));

drop policy if exists lawyer_payout_self_read on public.lawyer_payout_requests;
create policy lawyer_payout_self_read on public.lawyer_payout_requests for select to authenticated using (lawyer_id=(select id from public.profiles where auth_id=auth.uid()) or exists(select 1 from public.profiles where auth_id=auth.uid() and role='admin'));
