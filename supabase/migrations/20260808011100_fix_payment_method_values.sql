ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_payment_method_check;
ALTER TABLE public.payments ADD CONSTRAINT payments_payment_method_check CHECK (
  payment_method IN (
    'زين كاش','آسيا حوالة','كي كارد','بطاقة مصرفية',
    'zaincash','fatoora','cash','bank_transfer',
    'ZainCash','Asia Hawala','Qi Card','MasterCard'
  )
);
