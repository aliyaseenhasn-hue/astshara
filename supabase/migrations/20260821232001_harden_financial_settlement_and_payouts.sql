alter table public.lawyer_payout_requests add column if not exists approved_at timestamptz, add column if not exists completed_at timestamptz, add column if not exists rejected_at timestamptz;
create unique index if not exists lawyer_payout_one_active_per_lawyer on public.lawyer_payout_requests(lawyer_id) where status in ('pending_review','approved','processing');
create index if not exists payments_booking_created_idx on public.payments(booking_id, created_at desc);
create index if not exists financial_ledger_lawyer_created_idx on public.financial_ledger(lawyer_id, created_at desc);
create index if not exists payment_financials_lawyer_status_idx on public.payment_financials(lawyer_id, status, created_at desc);

create or replace function public.ensure_financial_accounting_for_payment(p_payment_id uuid) returns void language plpgsql security definer set search_path=public as $$
declare p public.payments%rowtype; b public.bookings%rowtype; s public.platform_financial_settings%rowtype; c numeric(18,2); net numeric(18,2); v_inserted boolean;
begin
 select * into p from payments where id=p_payment_id for update; if not found or p.status<>'تم الدفع' then return; end if;
 select * into b from bookings where id=p.booking_id for update; if not found or b.lawyer_id is null then return; end if;
 if exists(select 1 from payment_financials where payment_id=p.id) then return; end if;
 select * into s from platform_financial_settings where id=true;
 c:=round(coalesce(p.amount,0)*coalesce(s.commission_rate,0)/100,2); net:=greatest(0,coalesce(p.amount,0)-c);
 insert into payment_financials(payment_id,booking_id,client_id,lawyer_id,gross_amount,commission_rate,platform_commission,penalty_amount,client_credit_amount,lawyer_net_amount,currency,status) values(p.id,b.id,b.user_id,b.lawyer_id,coalesce(p.amount,0),coalesce(s.commission_rate,0),c,0,0,net,coalesce(s.currency,'IQD'),'pending') on conflict(payment_id) do nothing;
 get diagnostics v_inserted=row_count; if not v_inserted then return; end if;
 insert into financial_ledger(payment_id,booking_id,client_id,lawyer_id,entry_type,amount,currency,idempotency_key,metadata) values(p.id,b.id,b.user_id,b.lawyer_id,'payment_gross',coalesce(p.amount,0),coalesce(s.currency,'IQD'),'payment:'||p.id||':gross',jsonb_build_object('qicard_payment_id',p.qicard_payment_id,'qicard_request_id',p.qicard_request_id)) on conflict(idempotency_key) do nothing;
 insert into financial_ledger(payment_id,booking_id,client_id,lawyer_id,entry_type,amount,currency,idempotency_key,metadata) values(p.id,b.id,b.user_id,b.lawyer_id,'platform_commission',c,coalesce(s.currency,'IQD'),'payment:'||p.id||':commission',jsonb_build_object('commission_rate',coalesce(s.commission_rate,0))) on conflict(idempotency_key) do nothing;
 insert into financial_ledger(payment_id,booking_id,client_id,lawyer_id,entry_type,amount,currency,idempotency_key,metadata) values(p.id,b.id,b.user_id,b.lawyer_id,'lawyer_earning',net,coalesce(s.currency,'IQD'),'payment:'||p.id||':lawyer',jsonb_build_object('availability','pending_until_consultation_completed')) on conflict(idempotency_key) do nothing;
 insert into lawyer_wallets(lawyer_id,available_balance,pending_balance,lifetime_earned,currency,updated_at) values(b.lawyer_id,0,net,net,coalesce(s.currency,'IQD'),now()) on conflict(lawyer_id) do update set pending_balance=lawyer_wallets.pending_balance+excluded.pending_balance,lifetime_earned=lawyer_wallets.lifetime_earned+excluded.lifetime_earned,updated_at=now();
end; $$;

create or replace function public.release_lawyer_earnings_for_completed_booking(p_booking_id uuid) returns void language plpgsql security definer set search_path=public as $$
declare r record; moved numeric(18,2);
begin
 select b.id,b.lawyer_id,b.status into r from bookings b where b.id=p_booking_id for update; if not found or r.status<>'مكتمل' or r.lawyer_id is null then return; end if;
 for r in select pf.payment_id,pf.lawyer_id,pf.lawyer_net_amount,pf.status from payment_financials pf where pf.booking_id=p_booking_id and pf.status='pending' for update loop
   moved:=greatest(0,r.lawyer_net_amount);
   update lawyer_wallets set pending_balance=greatest(0,pending_balance-moved),available_balance=available_balance+moved,updated_at=now() where lawyer_id=r.lawyer_id;
   if not found then raise exception 'محفظة المحامي غير موجودة'; end if;
   update payment_financials set status='settled',updated_at=now() where payment_id=r.payment_id;
   insert into financial_ledger(payment_id,booking_id,lawyer_id,entry_type,amount,currency,idempotency_key,metadata) select r.payment_id,p_booking_id,r.lawyer_id,'lawyer_earning',moved,pf.currency,'payment:'||r.payment_id||':release',jsonb_build_object('source','consultation_completed') from payment_financials pf where pf.payment_id=r.payment_id on conflict(idempotency_key) do nothing;
 end loop;
end; $$;

create or replace function public.track_completed_consultation() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if old.status<>'مكتمل' and new.status='مكتمل' then new.completed_at:=coalesce(new.completed_at,now()); update public.lawyer_profiles set completed_consultations=completed_consultations+1 where profile_id=new.lawyer_id; perform public.release_lawyer_earnings_for_completed_booking(new.id); end if;
 if new.status='ملغي' then new.cancelled_at:=coalesce(new.cancelled_at,now()); end if; return new;
end; $$;

create or replace function public.request_lawyer_payout(p_amount numeric) returns uuid language plpgsql security definer set search_path=public as $$
declare v_lawyer uuid; v_wallet text; v_balance numeric; v_id uuid;
begin
 select id,wallet_number into v_lawyer,v_wallet from profiles where auth_id=auth.uid() and role='lawyer' limit 1;
 if v_lawyer is null then raise exception 'المستخدم ليس محامياً'; end if; if p_amount is null or p_amount<=0 then raise exception 'مبلغ السحب غير صالح'; end if;
 if nullif(trim(coalesce(v_wallet,'')),'') is null then raise exception 'يجب إضافة رقم المحفظة أولاً'; end if;
 select available_balance into v_balance from lawyer_wallets where lawyer_id=v_lawyer for update; if coalesce(v_balance,0)<p_amount then raise exception 'الرصيد المتاح غير كافٍ'; end if;
 if exists(select 1 from lawyer_payout_requests where lawyer_id=v_lawyer and status in ('pending_review','approved','processing')) then raise exception 'لديك طلب سحب قيد المعالجة بالفعل'; end if;
 insert into lawyer_payout_requests(lawyer_id,amount,wallet_number,status) values(v_lawyer,round(p_amount,2),v_wallet,'pending_review') returning id into v_id;
 update lawyer_wallets set available_balance=available_balance-p_amount,pending_balance=pending_balance+p_amount,updated_at=now() where lawyer_id=v_lawyer;
 insert into financial_ledger(lawyer_id,entry_type,amount,currency,reference_id,idempotency_key,metadata) select v_lawyer,'payout',round(p_amount,2),currency,v_id,'payout:'||v_id,jsonb_build_object('status','pending_review') from lawyer_wallets where lawyer_id=v_lawyer on conflict(idempotency_key) do nothing;
 return v_id;
end; $$;

create or replace function public.admin_complete_payout(p_payout_id uuid,p_status text,p_provider_reference text default null,p_rejection_reason text default null) returns void language plpgsql security definer set search_path=public as $$
declare r public.lawyer_payout_requests%rowtype;
begin
 if not exists(select 1 from profiles where auth_id=auth.uid() and role='admin') then raise exception 'غير مصرح'; end if;
 select * into r from lawyer_payout_requests where id=p_payout_id for update; if not found then raise exception 'طلب السحب غير موجود'; end if;
 if p_status not in ('approved','processing','paid','rejected','failed') then raise exception 'حالة غير صالحة'; end if; if r.status='paid' then raise exception 'تم إغلاق طلب السحب مسبقاً'; end if;
 if p_status='approved' then if r.status<>'pending_review' then raise exception 'لا يمكن اعتماد الطلب من حالته الحالية'; end if; update lawyer_payout_requests set status='approved',approved_at=now(),provider_reference=coalesce(p_provider_reference,provider_reference) where id=r.id;
 elsif p_status='processing' then if r.status not in ('approved','pending_review') then raise exception 'لا يمكن بدء التحويل من حالته الحالية'; end if; update lawyer_payout_requests set status='processing',provider_reference=coalesce(p_provider_reference,provider_reference) where id=r.id;
 elsif p_status='paid' then if r.status not in ('approved','processing') then raise exception 'لا يمكن إغلاق التحويل من حالته الحالية'; end if; update lawyer_wallets set pending_balance=greatest(0,pending_balance-r.amount),lifetime_paid_out=lifetime_paid_out+r.amount,updated_at=now() where lawyer_id=r.lawyer_id; update lawyer_payout_requests set status='paid',provider_reference=coalesce(p_provider_reference,provider_reference),processed_at=coalesce(processed_at,now()),completed_at=now() where id=r.id; insert into financial_ledger(lawyer_id,entry_type,amount,currency,reference_id,idempotency_key,metadata) values(r.lawyer_id,'payout',r.amount,r.currency,r.id,'payout:'||r.id||':paid',jsonb_build_object('provider_reference',p_provider_reference,'status','paid')) on conflict(idempotency_key) do nothing;
 elsif p_status in ('rejected','failed') then if r.status not in ('pending_review','approved','processing') then raise exception 'لا يمكن رفض الطلب من حالته الحالية'; end if; update lawyer_wallets set pending_balance=greatest(0,pending_balance-r.amount),available_balance=available_balance+r.amount,updated_at=now() where lawyer_id=r.lawyer_id; update lawyer_payout_requests set status=p_status,rejection_reason=p_rejection_reason,processed_at=now(),rejected_at=now() where id=r.id; end if;
end; $$;

alter table public.payment_financials enable row level security;
alter table public.financial_ledger enable row level security;
revoke insert,update,delete on public.payment_financials from anon,authenticated;
revoke insert,update,delete on public.financial_ledger from anon,authenticated;
revoke insert,update,delete on public.lawyer_wallets from anon,authenticated;
revoke update,delete on public.lawyer_payout_requests from anon,authenticated;
