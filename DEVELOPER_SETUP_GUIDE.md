# 🚀 دليل إعداد وتطوير مشروع استشارة (LawConnect)

هذا الدليل مخصص لإعداد بيئة التطوير وضمان مزامنة قاعدة البيانات مع الكود البرمجي.

## 1. إعداد متغيرات البيئة (.env)
يجب عدم رفع ملف `.env` إلى مستودع Git. لاتمام الإعداد:
1. انسخ ملف `.env.example` وقم بتسميته إلى `.env`.
2. ضع رابط مشروعك `SUPABASE_URL`.
3. استخدم مفتاح `SUPABASE_ANON_KEY` فقط. **ممنوع استخدام `service_role` key نهائياً**.

## 2. تحديثات قاعدة البيانات الضرورية (SQL)
إذا كنت تبدأ بمشروع جديد أو حدثت الكود، يجب تنفيذ الأوامر التالية في Supabase SQL Editor:

### أ. دعم التخصصات المتعددة للمحامين
```sql
-- تحويل التخصص لمصفوفة ودعم البحث السريع
ALTER TABLE public.lawyer_profiles 
ALTER COLUMN specialization TYPE TEXT[] USING ARRAY[specialization];

DROP INDEX IF EXISTS idx_lawyer_profiles_specialization;
CREATE INDEX idx_lawyer_profiles_specialization ON public.lawyer_profiles USING GIN (specialization);
```

### ب. نظام التقييم التلقائي
```sql
-- وظيفة تحديث التقييم تلقائياً
CREATE OR REPLACE FUNCTION update_lawyer_rating()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE lawyer_profiles SET
    rating = (SELECT ROUND(AVG(rating)::numeric, 2) FROM reviews WHERE lawyer_id = NEW.lawyer_id),
    review_count = (SELECT COUNT(*) FROM reviews WHERE lawyer_id = NEW.lawyer_id)
  WHERE profile_id = NEW.lawyer_id;
  RETURN NEW;
END; $$;

-- تفعيل الـ Trigger
DROP TRIGGER IF EXISTS on_review_added ON public.reviews;
CREATE TRIGGER on_review_added AFTER INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION update_lawyer_rating();
```

## 3. توليد الكود (Code Generation)
بعد أي تعديل على الـ Models أو الـ Providers، يجب تشغيل الأمر التالي لمزامنة الملفات:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 4. القواعد الذهبية
- **الأمن:** لا تضع أرقام هواتف أو مفاتيح سرية ثابتة في الكود.
- **التصميم:** التزم بنظام الألوان (Navy #0f1d3a, Gold #C9A84C) لضمان هوية بصرية موحدة.
- **التوجيه:** المحامي الموثق يذهب إلى `/lawyer-home` والعميل يذهب إلى `/`.
