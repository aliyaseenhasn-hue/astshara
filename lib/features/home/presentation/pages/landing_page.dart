import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';

const _navy = Color(0xFF0D1F3C);
const _navyMid = Color(0xFF162E54);
const _navyLight = Color(0xFF1E3E6E);
const _gold = Color(0xFFC9A84C);
const _goldLight = Color(0xFFDFC078);
const _offWhite = Color(0xFFF7F6F3);
const _surface = Color(0xFFEFEEEB);
const _textMid = Color(0xFF4A5A74);
const _textMuted = Color(0xFF8494A8);

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
              _Specializations(data: lawyers),
              _Lawyers(data: lawyers),
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

  void _login(BuildContext context) => context.go('/login');
  void _signup(BuildContext context) => context.go('/signup');

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
                OutlinedButton(
                  onPressed: () => _login(context),
                  child: const Text('لدي حساب'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _signup(context),
                  style: FilledButton.styleFrom(backgroundColor: _navy),
                  child: const Text('إنشاء حساب'),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () => _login(context),
                  child: const Text('لدي حساب'),
                ),
                const SizedBox(width: 7),
                FilledButton(
                  onPressed: () => _signup(context),
                  style: FilledButton.styleFrom(backgroundColor: _navy),
                  child: const Text('إنشاء حساب'),
                ),
              ],
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
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(12),
            ),
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
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: _textMid),
      child: Text(label),
    );
  }
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
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_navy, _navyMid, _navyLight],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: wide
          ? const Row(
              children: [
                Expanded(flex: 6, child: _HeroCopy()),
                SizedBox(width: 48),
                Expanded(flex: 5, child: _HeroVisual()),
              ],
            )
          : const Column(
              children: [
                _HeroCopy(),
                SizedBox(height: 30),
                _HeroVisual(),
              ],
            ),
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
        const Text(
          'استشارتك القانونية\nتبدأ من هنا',
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.white, fontSize: 48, height: 1.1, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        const Text(
          'ابحث عن المحامي المناسب، أرسل طلبك، وتابع رحلتك القانونية من منصة واحدة مصممة لتكون واضحة وسهلة.',
          textAlign: TextAlign.right,
          style: TextStyle(color: Color(0xFFCBD5E3), fontSize: 16, height: 1.8),
        ),
        const SizedBox(height: 26),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => context.push('/lawyers'),
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _navy,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('اطلب استشارة الآن', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x55FFFFFF)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text('لدي حساب'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Wrap(
          alignment: WrapAlignment.end,
          spacing: 18,
          runSpacing: 9,
          children: [
            _Proof(Icons.verified_user_rounded, 'محامون موثقون'),
            _Proof(Icons.lock_outline_rounded, 'خصوصية وأمان'),
            _Proof(Icons.devices_rounded, 'ويب وموبايل'),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 6, color: _goldLight),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(color: _goldLight, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Proof extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Proof(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _goldLight),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Color(0xFFCBD5E3), fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 22, left: 18, child: _FloatingCard(Icons.search_rounded, 'ابحث', 'عن تخصصك')),
          const Positioned(bottom: 22, right: 18, child: _FloatingCard(Icons.forum_rounded, 'تابع', 'طلبك بسهولة')),
          Container(
            width: 154,
            height: 154,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_goldLight, _gold]),
              boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.3), blurRadius: 42, spreadRadius: 5)],
            ),
            child: const Icon(Icons.balance_rounded, size: 70, color: _navy),
          ),
          Positioned(
            bottom: 54,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
              child: const Text('قانونك • بوضوح', style: TextStyle(color: _navy, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FloatingCard(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: const Color(0xFFE8EDF4), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _navy, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title, style: const TextStyle(color: _navy, fontWeight: FontWeight.w900, fontSize: 12)),
              Text(subtitle, style: const TextStyle(color: _textMid, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustBar extends StatelessWidget {
  const _TrustBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 36,
        runSpacing: 12,
        children: const [
          _TrustItem(Icons.verified_rounded, 'محامون موثقون'),
          _TrustItem(Icons.security_rounded, 'منصة آمنة'),
          _TrustItem(Icons.speed_rounded, 'استجابة سريعة'),
          _TrustItem(Icons.support_agent_rounded, 'دعم ومتابعة'),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _goldMuted, size: 19),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(color: _textMid, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return _Section(
      eyebrow: 'كيف تعمل المنصة؟',
      title: 'ثلاث خطوات بسيطة للوصول إلى الاستشارة',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 850;
          final items = const [
            _Step('01', Icons.search_rounded, 'ابحث', 'اختر التخصص والمحامي المناسب لاحتياجك.'),
            _Step('02', Icons.send_rounded, 'أرسل طلبك', 'أدخل تفاصيل القضية وأرسل طلب الاستشارة.'),
            _Step('03', Icons.forum_rounded, 'تابع الاستشارة', 'تواصل وتابع حالة طلبك من حسابك.'),
          ];
          return columns
              ? Row(children: items.map((item) => Expanded(child: item)).toList())
              : Column(children: items);
        },
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;

  const _Step(this.number, this.icon, this.title, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _navy.withValues(alpha: 0.07))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(number, style: const TextStyle(color: _goldMuted, fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: _goldLight),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(color: _navy, fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.right, style: const TextStyle(color: _textMid, height: 1.7)),
        ],
      ),
    );
  }
}

class _Specializations extends StatelessWidget {
  final AsyncValue<List<LawyerProfile>> data;

  const _Specializations({required this.data});

  @override
  Widget build(BuildContext context) {
    final categories = <String>{};
    data.whenData((lawyers) {
      for (final lawyer in lawyers) {
        categories.addAll(lawyer.specializations);
      }
    });
    final items = categories.take(8).toList();
    if (items.isEmpty) {
      items.addAll(const ['القانون المدني', 'القانون الجزائي', 'الأحوال الشخصية', 'القانون التجاري', 'القضايا الإدارية', 'العقود']);
    }

    return _Section(
      eyebrow: 'التخصصات القانونية',
      title: 'اختر المجال الذي تحتاجه',
      action: TextButton(onPressed: () => context.push('/legal-categories'), child: const Text('عرض جميع التخصصات')),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items.map((item) {
          return InkWell(
            onTap: () => context.push('/lawyers'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 190,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _navy.withValues(alpha: 0.07))),
              child: Text(item, textAlign: TextAlign.right, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Lawyers extends StatelessWidget {
  final AsyncValue<List<LawyerProfile>> data;

  const _Lawyers({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Section(
      eyebrow: 'محامون على المنصة',
      title: 'تعرّف على نخبة من المحامين',
      action: TextButton(onPressed: () => context.push('/lawyers'), child: const Text('عرض جميع المحامين')),
      child: data.when(
        loading: () => const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()),
        error: (_, __) => const _EmptyState(text: 'تعذر تحميل المحامين حالياً.'),
        data: (lawyers) {
          if (lawyers.isEmpty) return const _EmptyState(text: 'سيظهر المحامون هنا بعد اعتماد ملفاتهم.');
          final visible = lawyers.take(4).toList();
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 850 ? 4 : constraints.maxWidth >= 550 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visible.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 2.4 : 0.95,
                ),
                itemBuilder: (context, index) => _LawyerCard(lawyer: visible[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final LawyerProfile lawyer;

  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName! : 'محامٍ';
    final specialty = lawyer.specializations.isEmpty ? 'محامٍ' : lawyer.specializations.take(2).join(' • ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _navy.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: _navy.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.person_rounded, color: _goldLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navy, fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(specialty, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _textMid, fontSize: 12)),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.star_rounded, color: _goldMuted, size: 17),
              const SizedBox(width: 4),
              Text(lawyer.rating.toStringAsFixed(1), style: const TextStyle(color: _textMid, fontSize: 12, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (lawyer.verified) const Icon(Icons.verified_rounded, color: _goldMuted, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/lawyers/${lawyer.id}'),
              child: const Text('عرض الملف'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LawyerCta extends StatelessWidget {
  const _LawyerCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(26)),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 18,
        children: [
          const SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('هل أنت محامٍ؟', textAlign: TextAlign.right, style: TextStyle(color: _goldLight, fontSize: 14, fontWeight: FontWeight.w800)),
                SizedBox(height: 7),
                Text('انضم إلى استشارة وعرّف العملاء بخبرتك القانونية.', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => context.go('/signup'),
            style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _navy, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15)),
            child: const Text('انضم كمحامٍ', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq();

  @override
  Widget build(BuildContext context) {
    const faqs = [
      ('كيف أطلب استشارة قانونية؟', 'اختر المحامي أو التخصص المناسب، ثم أرسل تفاصيل طلبك من خلال المنصة.'),
      ('هل يمكنني متابعة حالة الطلب؟', 'نعم، يمكنك متابعة حالة طلبك والتواصل من خلال حسابك.'),
      ('هل يمكن للمحامي الانضمام إلى المنصة؟', 'نعم، يمكن للمحامي إنشاء حساب واستكمال ملفه المهني وفق متطلبات المنصة.'),
      ('هل بياناتي محمية؟', 'تطبق المنصة ضوابط الوصول والحماية المتاحة في النظام للحفاظ على بيانات المستخدمين.'),
    ];

    return _Section(
      eyebrow: 'الأسئلة الشائعة',
      title: 'أسئلة قبل أن تبدأ',
      child: Column(
        children: faqs.map((faq) {
          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              title: Text(faq.$1, textAlign: TextAlign.right, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800)),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              children: [Text(faq.$2, textAlign: TextAlign.right, style: const TextStyle(color: _textMid, height: 1.7))],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget child;
  final Widget? action;

  const _Section({required this.eyebrow, required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (action != null) action!,
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(eyebrow, style: const TextStyle(color: _goldMuted, fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 7),
                      Text(title, textAlign: TextAlign.right, style: const TextStyle(color: _navy, fontSize: 28, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18)),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: _textMid)),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _navyDeep,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
      child: Column(
        children: [
          const _LogoFooter(),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton(onPressed: () => context.push('/lawyers'), child: const Text('المحامون', style: TextStyle(color: Colors.white70))),
              TextButton(onPressed: () => context.push('/legal-categories'), child: const Text('التخصصات', style: TextStyle(color: Colors.white70))),
              TextButton(onPressed: () => context.push('/faq'), child: const Text('الأسئلة الشائعة', style: TextStyle(color: Colors.white70))),
              TextButton(onPressed: () => context.go('/login'), child: const Text('لدي حساب', style: TextStyle(color: Colors.white70))),
              TextButton(onPressed: () => context.go('/signup'), child: const Text('إنشاء حساب', style: TextStyle(color: Colors.white70))),
            ],
          ),
          const SizedBox(height: 12),
          const Text('استشارة — منصة الاستشارات القانونية', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LogoFooter extends StatelessWidget {
  const _LogoFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.balance_rounded, color: _navy),
        ),
        const SizedBox(width: 10),
        const Text('استشارة', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
