import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مركز المساعدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'كيف يمكننا مساعدتك اليوم؟',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 24),
            _buildContactCard(
              Icons.support_agent_rounded,
              'تحدث مع الدعم الفني',
              'متاحون على مدار الساعة',
              () => _launchUrl('https://wa.me/9647XXXXXXXX'), // مثال
            ),
            _buildContactCard(
              Icons.email_outlined,
              'راسلنا عبر البريد',
              'support@astshara.iq',
              () => _launchUrl('mailto:support@astshara.iq'),
            ),
            const SizedBox(height: 32),
            const Text(
              'أسئلة شائعة (FAQ)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildFaqItem('كيف يتم توثيق حساب المحامي؟',
                'يتم ذلك عن طريق رفع هوية النقابة ومراجعتها من قبل الإدارة.'),
            _buildFaqItem('ما هي طرق الدفع المتاحة؟',
                'نوفر حالياً زين كاش وآسيا حوالة لضمان سهولة المعاملات.'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
