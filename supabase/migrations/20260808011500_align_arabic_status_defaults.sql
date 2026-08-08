ALTER TABLE public.bookings ALTER COLUMN status SET DEFAULT 'قيد انتظار الدفع';
ALTER TABLE public.payments ALTER COLUMN status SET DEFAULT 'بانتظار الدفع';
