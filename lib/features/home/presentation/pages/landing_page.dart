import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';

const _navy = Color(0xFF0D1F3C);
const _navyMid = Color(0xFF162E54);
const _navyLight = Color(0xFF1E3E6E);
const _navyDeep = Color(0xFF08162B);
const _gold = Color(0xFFC9A84C);
const _goldLight = Color(0xFFDFC078);
const _goldMuted = Color(0xFF9F8540);
const _offWhite = Color(0xFFF7F6F3);
const _surface = Color(0xFFEFEEEB);
const _textMid = Color(0xFF4A5A74);

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyers = ref.watch(lawyersListProvider);
    return Scaffold(
      backgroundColor: _offWhite,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const _Header(),
              const _Hero(),
              const _TrustBar(),
              const _HowItWorks(),
              _LawyersSection(data: lawyers),
              const _LawyerCta(),
              const _Faq(),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Material(
      color: _offWhite,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 42 : 16, vertical: 12),
          child: Row(
            children: [
              const _Logo(),
              const Spacer(),
              if (wide) ...[
                _NavButton('الرئيسية', () => context.go('/')),
                _NavButton('كيف تعمل؟', () => context.push('/how-it-works')),
                _NavButton('المحامون', () => context.push('/lawyers')),
                _NavButton('التخصصات', () => context.push('/legal-categories')),
                _NavButton('الأسئلة الشائعة', () => context.push('/faq')),
                const SizedBox(width: 10),
              ],
              OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text('لدي حساب'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => context.go('/signup'),
                style: FilledButton.styleFrom(backgroundColor: _navy),
                child: const Text('إنشاء حساب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/'),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.balance_rounded, color: _gold, size: 25),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('استشارة', style: TextStyle(color: _navy, fontSize: 19, fontWeight: FontWeight.w900)),
              Text('منصة الاستشارات القانونية', style: TextStyle(color: _textMid, fontSize: 9.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _NavButton(this.label, this.onPressed);

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: _textMid),
        child: Text(label),
      );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Container(
      margin: EdgeInsets.fromLTRB(wide ? 32 : 14, 16, wide ? 32 : 14, 10),
      padding: EdgeInsets.all(wide ? 56 : 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [_navy, _navyMid, _navyLight]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: _navy.withValues(alpha: .18), blurRadius: 40, offset: const Offset(0, 18))],
      ),
      child: wide
          ? const Row(children: [Expanded(flex: 6, child: _HeroCopy()), SizedBox(width: 48), Expanded(flex: 5, child: _HeroVisual())])
          : const Column(children: [_HeroCopy(), SizedBox(height: 30), _HeroVisual()]),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _Pill('منصة قانونية عراقية'),
        const SizedBox(height: 14),
        const Text('استشارتك القانونية\nتبدأ من هنا', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 48, height: 1.1, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        const Text('ابحث عن المحامي المناسب، أرسل طلبك، وتابع رحلتك القانونية من منصة واحدة مصممة لتكون واضحة وسهلة.', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFFCBD5E3), fontSize: 16, height: 1.8)),
        const SizedBox(height: 26),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => context.push('/lawyers'),
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _navy, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('اطلب استشارة الآن', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0x55FFFFFF)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              icon: const Icon(Icons.login_rounded),
              label: const Text('لدي حساب'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Wrap(alignment: WrapAlignment.end, spacing: 18, runSpacing: 9, children: [
          _Proof(Icons.verified_user_rounded, 'محامون موثقون'),
          _Proof(Icons.lock_outline_rounded, 'خصوصية وأمان'),
          _Proof(Icons.devices_rounded, 'ويب وموبايل'),
        ]),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(99), border: Border.all(color: _gold.withValues(alpha: .35))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.circle, size: 6, color: _goldLight),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(color: _goldLight, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _Proof extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Proof(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: _goldLight),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Color(0xFFCBD5E3), fontSize: 11, fontWeight: FontWeight.w700)),
      ]);
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) => Container(
        height: 330,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .055), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: .1))),
        child: const Center(
          child: Icon(Icons.balance_rounded, size: 120, color: _gold),
        ),
      );

}

class _TrustBar extends StatelessWidget {
  const _TrustBar();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Wrap(alignment: WrapAlignment.center, spacing: 36, runSpacing: 12, children: const [
          _TrustItem(Icons.verified_rounded, 'محامون موثقون'),
          _TrustItem(Icons.security_rounded, 'منصة آمنة'),
          _TrustItem(Icons.speed_rounded, 'استجابة سريعة'),
          _TrustItem(Icons.support_agent_rounded, 'دعم ومتابعة'),
        ]),
      );
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TrustItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: _goldMuted, size: 19),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(color: _textMid, fontWeight: FontWeight.w700)),
      ]);
}

class _Section extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget child;
  const _Section({required this.eyebrow, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(eyebrow, style: const TextStyle(color: _goldMuted, fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(title, textAlign: TextAlign.right, style: const TextStyle(color: _navy, fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            child,
          ]),
        ),
      );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) => _Section(
        eyebrow: 'كيف تعمل المنصة؟',
        title: 'ثلاث خطوات بسيطة للوصول إلى الاستشارة',
        child: LayoutBuilder(builder: (context, constraints) {
          final items = const [
            _Step('01', Icons.search_rounded, 'ابحث', 'اختر التخصص والمحامي المناسب لاحتياجك.'),
            _Step('02', Icons.send_rounded, 'أرسل طلبك', 'أدخل تفاصيل القضية وأرسل طلب الاستشارة.'),
            _Step('03', Icons.check_circle_outline_rounded, 'تابع طلبك', 'تابع حالة الطلب والتواصل من المنصة.'),
          ];
          if (constraints.maxWidth >= 850) return Row(children: items.map((item) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7), child: item))).toList());
          return Column(children: items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: item)).toList());
        }),
      );
}

class _Step extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;
  const _Step(this.number, this.icon, this.title, this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _navy.withValues(alpha: .07))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(children: [Text(number, style: const TextStyle(color: _goldMuted, fontWeight: FontWeight.w900)), const Spacer(), Container(width: 48, height: 48, decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: _goldLight))]),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.right, style: const TextStyle(color: _textMid, height: 1.7)),
        ]),
      );
}

class _LawyersSection extends StatelessWidget {
  final AsyncValue<List<LawyerProfile>> data;
  const _LawyersSection({required this.data});

  @override
  Widget build(BuildContext context) => _Section(
        eyebrow: 'المحامون',
        title: 'محامون لمساعدتك',
        child: data.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
          error: (error, stack) => _EmptyState(text: 'تعذر تحميل قائمة المحامين حالياً.'),
          data: (lawyers) {
            if (lawyers.isEmpty) return const _EmptyState(text: 'سيظهر المحامون الموثقون هنا قريباً.');
            final shown = lawyers.take(6).toList();
            return LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000 ? 3 : constraints.maxWidth >= 650 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shown.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: columns == 1 ? 2.0 : 1.55),
                itemBuilder: (context, index) => _LawyerCard(lawyer: shown[index]),
              );
            });
          },
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20)), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: _textMid)));
}

class _LawyerCard extends StatelessWidget {
  final LawyerProfile lawyer;
  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final name = (lawyer.fullName ?? '').trim().isEmpty ? 'محامٍ' : lawyer.fullName!.trim();
    final specialties = lawyer.specializations.take(2).join(' • ');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _navy.withValues(alpha: .08)), boxShadow: [BoxShadow(color: _navy.withValues(alpha: .04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.person_rounded, color: _goldLight)),
          const SizedBox(width: 12),
          Expanded(child: Text(name, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navy, fontWeight: FontWeight.w900, fontSize: 15))),
          if (lawyer.verified) const Icon(Icons.verified_rounded, color: _goldMuted, size: 20),
        ]),
        const SizedBox(height: 14),
        Text(specialties.isEmpty ? 'محامٍ' : specialties, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _textMid, fontSize: 12)),
        const Spacer(),
        Row(children: [
          Text('${lawyer.rating.toStringAsFixed(1)} ★', style: const TextStyle(color: _goldMuted, fontWeight: FontWeight.w800)),
          const Spacer(),
          OutlinedButton(onPressed: () => context.push('/lawyers/${lawyer.id}'), child: const Text('عرض الملف')),
        ]),
      ]),
    );
  }
}

class _LawyerCta extends StatelessWidget {
  const _LawyerCta();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(26)),
        child: Row(children: [
          FilledButton(onPressed: () => context.go('/signup'), style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _navy), child: const Text('ابدأ الآن', style: TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(width: 18),
          const Expanded(child: Text('هل أنت محامٍ؟ انضم إلى استشارة وقدّم خدماتك القانونية للعملاء.', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
        ]),
      );
}

class _Faq extends StatelessWidget {
  const _Faq();

  @override
  Widget build(BuildContext context) {
    const faqs = [
      ('كيف أطلب استشارة؟', 'اختر المحامي أو التخصص، ثم أرسل تفاصيل طلبك من المنصة.'),
      ('هل يمكنني متابعة حالة الطلب؟', 'نعم، يمكنك متابعة حالة الطلب والتحديثات من حسابك.'),
      ('كيف ينضم المحامي إلى المنصة؟', 'ينشئ المحامي حساباً ويكمل البيانات المهنية المطلوبة للمراجعة.'),
    ];
    return _Section(
      eyebrow: 'الأسئلة الشائعة',
      title: 'أسئلة قبل أن تبدأ',
      child: Column(children: faqs.map((faq) => Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              title: Text(faq.$1, textAlign: TextAlign.right, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800)),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              children: [Text(faq.$2, textAlign: TextAlign.right, style: const TextStyle(color: _textMid, height: 1.7))],
            ),
          )).toList()),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: _navyDeep,
        padding: const EdgeInsets.all(28),
        child: Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 18, children: [
          const Text('© استشارة — منصة الاستشارات القانونية', style: TextStyle(color: Color(0xFFCBD5E3))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            TextButton(onPressed: () => context.go('/login'), child: const Text('لدي حساب', style: TextStyle(color: Colors.white))),
            TextButton(onPressed: () => context.go('/signup'), child: const Text('إنشاء حساب', style: TextStyle(color: _goldLight))),
          ]),
        ]),
      );
}
