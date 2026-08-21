-- Harden the financial cycle further after review of payout reservation,
-- state transitions, and fail-closed accounting behavior.

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
  where id = p_payment_id
  for update;

  if not found or p.status <> 'تم الدفع' then
    return;
  end if;

  if coalesce(p.amount, 0) <= 0 then
    raise exception 'لا يمكن تسجيل عملية دفع بمبلغ غير صالح';
  end if;

  select * into b
  from public.bookings
  where id = p.booking_id
  for update;

  if not found or b.lawyer_id is null then
    return;
  end if;

  if exists (select 1 from public.payment_financials where payment_id = p.id) then
    return;
  end if;

  select * into s
  from public.platform_financial_settings
  where id = true;

  if not found or s.commission_rate is null or s.commission_rate < 0 or s.commission_rate > 100 then
    raise exception 'إعداد العمولة المالية غير صالح أو غير موجود';
  end if;

  c := round(p.amount * s.commission_rate / 100, 2);
  net := round(p.amount - c, 2);

  if net < 0 then
    raise exception 'صافي المحامي غير صالح';
  end if;

  insert into public.payment_financials(
    payment_id, booking_id, client_id, lawyer_id, gross_amount, commission_rate,
    platform_commission, penalty_amount, client_credit_amount, lawyer_net_amount,
    currency, status
  ) values (
    p.id, b.id, b.user_id, b.lawyer_id, p.amount, s.commission_rate,
    c, 0, 0, net, coalesce(s.currency, 'IQD'), 'pending'
  )
  on conflict (payment_id) do nothing;

  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return;
  end if;

  insert into public.financial_ledger(
    payment_id, booking_id, client_id, lawyer_id, entry_type, amount, currency,
    idempotency_key, metadata
  ) values (
    p.id, b.id, b.user_id, b.lawyer_id, 'payment_gross', p.amount,
    coalesce(s.currency, 'IQD'), 'payment:' || p.id || ':gross',
    jsonb_build_object('qicard_payment_id', p.qicard_payment_id, 'qicard_request_id', p.qicard_request_id)
  ) on conflict (idempotency_key) do nothing;

  insert into public.financial_ledger(
    payment_id, booking_id, client_id, lawyer_id, entry_type, amount, currency,
    idempotency_key, metadata
  ) values (
    p.id, b.id, b.user_id, b.lawyer_id, 'platform_commission', c,
    coalesce(s.currency, 'IQD'), 'payment:' || p.id || ':commission',
    jsonb_build_object('commission_rate', s.commission_rate)
  ) on conflict (idempotency_key) do nothing;

  insert into public.financial_ledger(
    payment_id, booking_id, client_id, lawyer_id, entry_type, amount, currency,
    idempotency_key, metadata
  ) values (
    p.id, b.id, b.user_id, b.lawyer_id, 'lawyer_earning', net,
    coalesce(s.currency, 'IQD'), 'payment:' || p.id || ':lawyer',
    jsonb_build_object('availability', 'pending_until_consultation_completed')
  ) on conflict (idempotency_key) do nothing;

  insert into public.lawyer_wallets(
    lawyer_id, available_balance, pending_balance, lifetime_earned, currency, updated_at
  ) values (
    b.lawyer_id, 0, net, net, coalesce(s.currency, 'IQD'), now()
  )
  on conflict (lawyer_id) do update set
    pending_balance = lawyer_wallets.pending_balance + excluded.pending_balance,
    lifetime_earned = lawyer_wallets.lifetime_earned + excluded.lifetime_earned,
    updated_at = now();
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
  v_pending numeric(18,2);
begin
  select * into v_booking
  from public.bookings
  where id = p_booking_id
  for update;

  if not found or v_booking.status <> 'مكتمل' or v_booking.lawyer_id is null then
    return;
  end if;

  for v_financial in
    select pf.payment_id, pf.lawyer_id, pf.lawyer_net_amount, pf.currency
    from public.payment_financials pf
    where pf.booking_id = p_booking_id and pf.status = 'pending'
    for update
  loop
    moved := round(greatest(0, coalesce(v_financial.lawyer_net_amount, 0)), 2);

    select pending_balance into v_pending
    from public.lawyer_wallets
    where lawyer_id = v_financial.lawyer_id
    for update;

    if not found then
      raise exception 'محفظة المحامي غير موجودة';
    end if;

    if coalesce(v_pending, 0) < moved then
      raise exception 'الرصيد قيد التسوية غير كافٍ لإكمال التسوية';
    end if;

    update public.lawyer_wallets
    set pending_balance = pending_balance - moved,
        available_balance = available_balance + moved,
        updated_at = now()
    where lawyer_id = v_financial.lawyer_id;

    update public.payment_financials
    set status = 'settled', updated_at = now()
    where payment_id = v_financial.payment_id and status = 'pending';

    insert into public.financial_ledger(
      payment_id, booking_id, lawyer_id, entry_type, amount, currency,
      idempotency_key, metadata
    ) values (
      v_financial.payment_id, p_booking_id, v_financial.lawyer_id,
      'lawyer_earning_settlement', moved, v_financial.currency,
      'payment:' || v_financial.payment_id || ':release',
      jsonb_build_object('source', 'consultation_completed')
    ) on conflict (idempotency_key) do nothing;
  end loop;
end;
$$;

create or replace function public.request_lawyer_payout(p_amount numeric)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  v_lawyer uuid;
  v_wallet text;
  v_balance numeric;
  v_amount numeric(18,2);
  v_id uuid;
  v_currency text;
begin
  select id, wallet_number into v_lawyer, v_wallet
  from public.profiles
  where auth_id = auth.uid() and role = 'lawyer'
  limit 1;

  if v_lawyer is null then
    raise exception 'المستخدم ليس محامياً';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'مبلغ السحب غير صالح';
  end if;

  v_amount := round(p_amount, 2);
  if v_amount <= 0 then
    raise exception 'مبلغ السحب غير صالح';
  end if;

  if nullif(trim(coalesce(v_wallet, '')), '') is null then
    raise exception 'يجب إضافة رقم المحفظة أولاً';
  end if;

  select available_balance, currency into v_balance, v_currency
  from public.lawyer_wallets
  where lawyer_id = v_lawyer
  for update;

  if not found then
    raise exception 'محفظة المحامي غير موجودة';
  end if;

  if coalesce(v_balance, 0) < v_amount then
    raise exception 'الرصيد المتاح غير كافٍ';
  end if;

  if exists (
    select 1 from public.lawyer_payout_requests
    where lawyer_id = v_lawyer
      and status in ('pending_review', 'approved', 'processing')
  ) then
    raise exception 'لديك طلب سحب قيد المعالجة بالفعل';
  end if;

  insert into public.lawyer_payout_requests(
    lawyer_id, amount, wallet_number, status, currency
  ) values (
    v_lawyer, v_amount, v_wallet, 'pending_review', coalesce(v_currency, 'IQD')
  ) returning id into v_id;

  update public.lawyer_wallets
  set available_balance = available_balance - v_amount,
      pending_balance = pending_balance + v_amount,
      updated_at = now()
  where lawyer_id = v_lawyer
    and available_balance >= v_amount;

  if not found then
    raise exception 'تعذر حجز مبلغ السحب من الرصيد المتاح';
  end if;

  insert into public.financial_ledger(
    lawyer_id, entry_type, amount, currency, reference_id, idempotency_key, metadata
  ) values (
    v_lawyer, 'payout', v_amount, coalesce(v_currency, 'IQD'), v_id,
    'payout:' || v_id,
    jsonb_build_object('status', 'pending_review')
  ) on conflict (idempotency_key) do nothing;

  return v_id;
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
  v_reference text := nullif(trim(coalesce(p_provider_reference, '')), '');
  v_reason text := nullif(trim(coalesce(p_rejection_reason, '')), '');
  v_pending numeric(18,2);
begin
  if not exists (
    select 1 from public.profiles
    where auth_id = auth.uid() and role = 'admin'
  ) then
    raise exception 'غير مصرح';
  end if;

  select * into r
  from public.lawyer_payout_requests
  where id = p_payout_id
  for update;

  if not found then
    raise exception 'طلب السحب غير موجود';
  end if;

  if p_status not in ('approved', 'processing', 'paid', 'rejected', 'failed') then
    raise exception 'حالة غير صالحة';
  end if;

  if r.status in ('paid', 'rejected', 'failed') then
    raise exception 'تم إغلاق طلب السحب مسبقاً';
  end if;

  if p_status = 'approved' then
    if r.status <> 'pending_review' then
      raise exception 'لا يمكن اعتماد الطلب من حالته الحالية';
    end if;

    update public.lawyer_payout_requests
    set status = 'approved',
        approved_at = coalesce(approved_at, now()),
        provider_reference = coalesce(v_reference, provider_reference)
    where id = r.id;

  elsif p_status = 'processing' then
    if r.status <> 'approved' then
      raise exception 'لا يمكن بدء التحويل قبل اعتماد طلب السحب';
    end if;

    update public.lawyer_payout_requests
    set status = 'processing',
        provider_reference = coalesce(v_reference, provider_reference),
        processed_at = coalesce(processed_at, now())
    where id = r.id;

  elsif p_status = 'paid' then
    if r.status <> 'processing' then
      raise exception 'لا يمكن تسجيل السحب كمدفوع قبل بدء التحويل';
    end if;

    if v_reference is null and nullif(trim(coalesce(r.provider_reference, '')), '') is null then
      raise exception 'مرجع التحويل الخارجي مطلوب قبل تسجيل العملية كمدفوعة';
    end if;

    select pending_balance into v_pending
    from public.lawyer_wallets
    where lawyer_id = r.lawyer_id
    for update;

    if not found then
      raise exception 'محفظة المحامي غير موجودة';
    end if;

    if coalesce(v_pending, 0) < r.amount then
      raise exception 'الرصيد المحجوز للسحب غير كافٍ';
    end if;

    update public.lawyer_wallets
    set pending_balance = pending_balance - r.amount,
        lifetime_paid_out = lifetime_paid_out + r.amount,
        updated_at = now()
    where lawyer_id = r.lawyer_id;

    update public.lawyer_payout_requests
    set status = 'paid',
        provider_reference = coalesce(v_reference, provider_reference),
        processed_at = coalesce(processed_at, now()),
        completed_at = coalesce(completed_at, now())
    where id = r.id;

    insert into public.financial_ledger(
      lawyer_id, entry_type, amount, currency, reference_id, idempotency_key, metadata
    ) values (
      r.lawyer_id, 'payout', r.amount, r.currency, r.id,
      'payout:' || r.id || ':paid',
      jsonb_build_object('provider_reference', coalesce(v_reference, r.provider_reference), 'status', 'paid')
    ) on conflict (idempotency_key) do nothing;

  elsif p_status in ('rejected', 'failed') then
    if r.status not in ('pending_review', 'approved', 'processing') then
      raise exception 'لا يمكن إغلاق طلب السحب من حالته الحالية';
    end if;

    if v_reason is null then
      raise exception 'سبب الرفض أو الفشل مطلوب';
    end if;

    select pending_balance into v_pending
    from public.lawyer_wallets
    where lawyer_id = r.lawyer_id
    for update;

    if not found then
      raise exception 'محفظة المحامي غير موجودة';
    end if;

    if coalesce(v_pending, 0) < r.amount then
      raise exception 'الرصيد المحجوز للسحب غير كافٍ لإرجاع المبلغ';
    end if;

    update public.lawyer_wallets
    set pending_balance = pending_balance - r.amount,
        available_balance = available_balance + r.amount,
        updated_at = now()
    where lawyer_id = r.lawyer_id;

    update public.lawyer_payout_requests
    set status = p_status,
        rejection_reason = v_reason,
        processed_at = coalesce(processed_at, now()),
        rejected_at = coalesce(rejected_at, now())
    where id = r.id;
  end if;
end;
$$;

revoke execute on function public.admin_complete_payout(uuid, text, text, text) from public, anon, authenticated;
grant execute on function public.admin_complete_payout(uuid, text, text, text) to authenticated;
revoke execute on function public.ensure_financial_accounting_for_payment(uuid) from public, anon, authenticated;
revoke execute on function public.release_lawyer_earnings_for_completed_booking(uuid) from public, anon, authenticated;
revoke execute on function public.request_lawyer_payout(numeric) from public, anon;
grant execute on function public.request_lawyer_payout(numeric) to authenticated;
