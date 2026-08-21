-- Fix runtime and accounting defects found during the financial-cycle review.
-- 1) GET DIAGNOSTICS ROW_COUNT must target an integer, not boolean.
-- 2) Prevent zero/negative paid payments from creating financial records.
-- 3) Keep settlement audit entries distinct from the original earning entry.
-- 4) Require an external provider reference when an admin marks a payout paid.
-- 5) Require a reason when a payout is rejected/failed.

create or replace function public.ensure_financial_accounting_for_payment(p_payment_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  p public.payments%rowtype;
  b public.bookings%rowtype;
  s public.platform_financial_settings%rowtype;
  c numeric(18,2);
  net numeric(18,2);
  v_inserted integer := 0;
begin
  select * into p
  from public.payments
  where id=p_payment_id
  for update;

  if not found or p.status <> 'تم الدفع' then
    return;
  end if;

  if coalesce(p.amount,0) <= 0 then
    raise exception 'لا يمكن تسجيل عملية دفع بمبلغ غير صالح';
  end if;

  select * into b
  from public.bookings
  where id=p.booking_id
  for update;

  if not found or b.lawyer_id is null then
    return;
  end if;

  if exists(select 1 from public.payment_financials where payment_id=p.id) then
    return;
  end if;

  select * into s
  from public.platform_financial_settings
  where id=true;

  c := round(coalesce(p.amount,0) * coalesce(s.commission_rate,0) / 100, 2);
  net := round(greatest(0, coalesce(p.amount,0) - c), 2);

  insert into public.payment_financials(
    payment_id,booking_id,client_id,lawyer_id,gross_amount,commission_rate,
    platform_commission,penalty_amount,client_credit_amount,lawyer_net_amount,
    currency,status
  ) values (
    p.id,b.id,b.user_id,b.lawyer_id,coalesce(p.amount,0),coalesce(s.commission_rate,0),
    c,0,0,net,coalesce(s.currency,'IQD'),'pending'
  )
  on conflict(payment_id) do nothing;

  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return;
  end if;

  insert into public.financial_ledger(
    payment_id,booking_id,client_id,lawyer_id,entry_type,amount,currency,idempotency_key,metadata
  ) values (
    p.id,b.id,b.user_id,b.lawyer_id,'payment_gross',coalesce(p.amount,0),coalesce(s.currency,'IQD'),
    'payment:'||p.id||':gross',
    jsonb_build_object('qicard_payment_id',p.qicard_payment_id,'qicard_request_id',p.qicard_request_id)
  ) on conflict(idempotency_key) do nothing;

  insert into public.financial_ledger(
    payment_id,booking_id,client_id,lawyer_id,entry_type,amount,currency,idempotency_key,metadata
  ) values (
    p.id,b.id,b.user_id,b.lawyer_id,'platform_commission',c,coalesce(s.currency,'IQD'),
    'payment:'||p.id||':commission',
    jsonb_build_object('commission_rate',coalesce(s.commission_rate,0))
  ) on conflict(idempotency_key) do nothing;

  insert into public.financial_ledger(
    payment_id,booking_id,client_id,lawyer_id,entry_type,amount,currency,idempotency_key,metadata
  ) values (
    p.id,b.id,b.user_id,b.lawyer_id,'lawyer_earning',net,coalesce(s.currency,'IQD'),
    'payment:'||p.id||':lawyer',
    jsonb_build_object('availability','pending_until_consultation_completed')
  ) on conflict(idempotency_key) do nothing;

  insert into public.lawyer_wallets(
    lawyer_id,available_balance,pending_balance,lifetime_earned,currency,updated_at
  ) values (
    b.lawyer_id,0,net,net,coalesce(s.currency,'IQD'),now()
  )
  on conflict(lawyer_id) do update set
    pending_balance=lawyer_wallets.pending_balance+excluded.pending_balance,
    lifetime_earned=lawyer_wallets.lifetime_earned+excluded.lifetime_earned,
    updated_at=now();
end;
$$;

create or replace function public.release_lawyer_earnings_for_completed_booking(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  v_booking public.bookings%rowtype;
  v_financial record;
  moved numeric(18,2);
begin
  select * into v_booking
  from public.bookings
  where id=p_booking_id
  for update;

  if not found or v_booking.status <> 'مكتمل' or v_booking.lawyer_id is null then
    return;
  end if;

  for v_financial in
    select pf.payment_id,pf.lawyer_id,pf.lawyer_net_amount,pf.currency
    from public.payment_financials pf
    where pf.booking_id=p_booking_id and pf.status='pending'
    for update
  loop
    moved := greatest(0,coalesce(v_financial.lawyer_net_amount,0));

    update public.lawyer_wallets
    set pending_balance=greatest(0,pending_balance-moved),
        available_balance=available_balance+moved,
        updated_at=now()
    where lawyer_id=v_financial.lawyer_id;

    if not found then
      raise exception 'محفظة المحامي غير موجودة';
    end if;

    update public.payment_financials
    set status='settled',updated_at=now()
    where payment_id=v_financial.payment_id and status='pending';

    -- This is a settlement/audit event, not a second earning.
    insert into public.financial_ledger(
      payment_id,booking_id,lawyer_id,entry_type,amount,currency,idempotency_key,metadata
    ) values (
      v_financial.payment_id,p_booking_id,v_financial.lawyer_id,'lawyer_earning_settlement',moved,
      v_financial.currency,'payment:'||v_financial.payment_id||':release',
      jsonb_build_object('source','consultation_completed')
    ) on conflict(idempotency_key) do nothing;
  end loop;
end;
$$;

create or replace function public.admin_complete_payout(
  p_payout_id uuid,
  p_status text,
  p_provider_reference text default null,
  p_rejection_reason text default null
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  r public.lawyer_payout_requests%rowtype;
  v_reference text := nullif(trim(coalesce(p_provider_reference,'')),'');
  v_reason text := nullif(trim(coalesce(p_rejection_reason,'')),'');
begin
  if not exists(
    select 1 from public.profiles
    where auth_id=auth.uid() and role='admin'
  ) then
    raise exception 'غير مصرح';
  end if;

  select * into r
  from public.lawyer_payout_requests
  where id=p_payout_id
  for update;

  if not found then
    raise exception 'طلب السحب غير موجود';
  end if;

  if p_status not in ('approved','processing','paid','rejected','failed') then
    raise exception 'حالة غير صالحة';
  end if;

  if r.status='paid' then
    raise exception 'تم إغلاق طلب السحب مسبقاً';
  end if;

  if p_status='approved' then
    if r.status<>'pending_review' then
      raise exception 'لا يمكن اعتماد الطلب من حالته الحالية';
    end if;
    update public.lawyer_payout_requests
    set status='approved',approved_at=coalesce(approved_at,now()),provider_reference=coalesce(v_reference,provider_reference)
    where id=r.id;

  elsif p_status='processing' then
    if r.status not in ('approved','pending_review') then
      raise exception 'لا يمكن بدء التحويل من حالته الحالية';
    end if;
    update public.lawyer_payout_requests
    set status='processing',provider_reference=coalesce(v_reference,provider_reference),processed_at=coalesce(processed_at,now())
    where id=r.id;

  elsif p_status='paid' then
    if r.status not in ('approved','processing') then
      raise exception 'لا يمكن إغلاق التحويل من حالته الحالية';
    end if;
    if v_reference is null and nullif(trim(coalesce(r.provider_reference,'')),'') is null then
      raise exception 'مرجع التحويل الخارجي مطلوب قبل تسجيل العملية كمدفوعة';
    end if;

    update public.lawyer_wallets
    set pending_balance=greatest(0,pending_balance-r.amount),
        lifetime_paid_out=lifetime_paid_out+r.amount,
        updated_at=now()
    where lawyer_id=r.lawyer_id;

    if not found then
      raise exception 'محفظة المحامي غير موجودة';
    end if;

    update public.lawyer_payout_requests
    set status='paid',
        provider_reference=coalesce(v_reference,provider_reference),
        processed_at=coalesce(processed_at,now()),
        completed_at=coalesce(completed_at,now())
    where id=r.id;

    insert into public.financial_ledger(
      lawyer_id,entry_type,amount,currency,reference_id,idempotency_key,metadata
    ) values (
      r.lawyer_id,'payout',r.amount,r.currency,r.id,'payout:'||r.id||':paid',
      jsonb_build_object('provider_reference',coalesce(v_reference,r.provider_reference),'status','paid')
    ) on conflict(idempotency_key) do nothing;

  elsif p_status in ('rejected','failed') then
    if r.status not in ('pending_review','approved','processing') then
      raise exception 'لا يمكن رفض الطلب من حالته الحالية';
    end if;
    if v_reason is null then
      raise exception 'سبب الرفض أو الفشل مطلوب';
    end if;

    update public.lawyer_wallets
    set pending_balance=greatest(0,pending_balance-r.amount),
        available_balance=available_balance+r.amount,
        updated_at=now()
    where lawyer_id=r.lawyer_id;

    if not found then
      raise exception 'محفظة المحامي غير موجودة';
    end if;

    update public.lawyer_payout_requests
    set status=p_status,
        rejection_reason=v_reason,
        processed_at=coalesce(processed_at,now()),
        rejected_at=coalesce(rejected_at,now())
    where id=r.id;
  end if;
end;
$$;

revoke execute on function public.admin_complete_payout(uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.admin_complete_payout(uuid,text,text,text) to authenticated;
revoke execute on function public.ensure_financial_accounting_for_payment(uuid) from public,anon,authenticated;
revoke execute on function public.release_lawyer_earnings_for_completed_booking(uuid) from public,anon,authenticated;
