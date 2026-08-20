import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _section(context, 'مقدمة', 'نحترم خصوصية مستخدمي منصة استشارة ونلتزم باستخدام البيانات بالقدر اللازم لتقديم خدمات التسجيل، الاستشارات، الحجوزات، الدفع والتواصل.'),
          _section(context, 'البيانات التي قد نجمعها', 'قد تشمل البيانات الاسم ورقم الهاتف ورقم واتساب والمدينة وبيانات الحساب وصورة الملف الشخصي وبيانات الحجز والمستندات التي يختار المستخدم إرفاقها، إضافة إلى بيانات تقنية لازمة لتشغيل التطبيق.'),
          _section(context, 'استخدام البيانات', 'تستخدم البيانات لإنشاء الحساب وإدارته، مطابقة طالب الخدمة مع المحامي، إدارة المواعيد والمدفوعات، تنفيذ التواصل المرتبط بالاستشارة، إرسال الإشعارات، ومنع إساءة استخدام المنصة.'),
          _section(context, 'مشاركة البيانات', 'لا تُعرض بيانات التواصل الخاصة بالاستشارة إلا عندما تسمح حالة الحجز بذلك وفق منطق التطبيق. وقد تُشارك البيانات اللازمة مع مزودي الخدمات التقنية الذين تعتمد عليهم المنصة لتشغيل وظائفها.'),
          _section(context, 'المستندات والملفات', 'المستندات التي يرفعها المستخدم مرتبطة بطلب الاستشارة ولا ينبغي رفع أي معلومات لا يرغب في مشاركتها مع الأطراف المعنية بالحجز.'),
          _section(context, 'الأمان', 'نستخدم ضوابط تقنية وصلاحيات وصول لحماية بيانات الحسابات. ومع ذلك، لا توجد وسيلة نقل أو تخزين إلكترونية يمكن ضمان أمانها بشكل مطلق.'),
          _section(context, 'حقوق المستخدم', 'يمكن للمستخدم مراجعة بياناته وتحديثها وطلب حذف حسابه من خلال وظائف التطبيق، مع مراعاة الالتزامات القانونية والسجلات اللازمة لإدارة الحجوزات والمدفوعات والنزاعات.'),
          _section(context, 'التحديثات', 'قد يتم تحديث هذه السياسة عند إضافة وظائف جديدة أو إجراء تغييرات تنظيمية. سيظهر الإصدار المحدث داخل التطبيق عند اعتماده.'),
          const SizedBox(height: 12),
          Text('هذه الصفحة هي النسخة الحالية المنشورة داخل التطبيق، ويجب اعتماد الصياغة القانونية النهائية قبل الإطلاق التجاري.', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.6)),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, textAlign: TextAlign.right, style: TextStyle(color: scheme.primary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text(body, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 13, height: 1.65)),
        ],
      ),
    );
  }
}
