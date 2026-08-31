import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';

const _navy = Color(0xFF0D1F3C);
const _navyDeep = Color(0xFF071428);
const _navyMid = Color(0xFF162E54);
const _navyLight = Color(0xFF1E3E6E);
const _gold = Color(0xFFC9A84C);
const _goldLight = Color(0xFFDFC078);
const _goldMuted = Color(0xFFA88838);
const _offWhite = Color(0xFFF7F6F3);
const _surface = Color(0xFFEFEEEB);
const _textMid = Color(0xFF4A5A74);
const _textMuted = Color(0xFF8494A8);

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem(this.question, this.answer);
}

class _TrustItem {
  final IconData icon;
  final String text;

  const _TrustItem(this.icon, this.text);
}

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyers = ref.watch(lawyersListProvider);

    return Scaffold(
      backgroundColor: _offWhite,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(child: _Trust()),
            const SliverToBoxAdapter(child: _HowItWorks()),
            SliverToBoxAdapter(child: _Specializations(data: lawyers)),
            SliverToBoxAdapter(child: _Lawyers(data: lawyers)),
            const SliverToBoxAdapter(child: _LawyerCta()),
            const SliverToBoxAdapter(child: _Faq()),
            const SliverToBoxAdapter(child: _Footer()),
          ],
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
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    return Material(
      color: _offWhite.withValues(alpha: 0.97),
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _navy, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('لدي حساب'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _signup(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إنشاء حساب'),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () => _login(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _navy),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: const Text('لدي حساب'),
                ),
                const SizedBox(width: 7),
                FilledButton(
                  onPressed: () => _signup(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
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
              Text(
                'استشارة',
                style: TextStyle(color: _navy, fontSize: 19, fontWeight: FontWeight.w900),
              ),
              Text(
                'منصة الاستشارات القانونية',
                style: TextStyle(color: _textMid, fontSize: 9.5),
              ),
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
      margin: EdgeInsets.fromLTRB(wide ? 32 : 14, 16, wide ? 32 : 14, 8),
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
        const SizedBox(height: 4),
        const Text(
          'استشارتك القانونية\nتبدأ من هنا',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
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
            _MiniProof(Icons.verified_user_rounded, 'محامون موثقون'),
            _MiniProof(Icons.lock_outline_rounded, 'خصوصية وأمان'),
            _MiniProof(Icons.devices_rounded, 'ويب وموبايل'),
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
          Text(
            text,
            style: const TextStyle(color: _goldLight, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MiniProof extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniProof(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _goldLight),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(color: Color(0xFFCBD5E3), fontSize: 11, fontWeight: FontWeight.w700),
        ),
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
          const Positioned(
            top: 22,
            left: 18,
            child: _FloatingCard(Icons.search_rounded, 'ابحث', 'عن تخصصك'),
          ),
          const Positioned(
            bottom: 22,
            right: 18,
            child: _FloatingCard(Icons.forum_rounded, 'تابع', 'طلبك بسهولة'),
          ),
          Container(
            width: 154,
            height: 154,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_goldLight, _gold]),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.3),
                  blurRadius: 42,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.balance_rounded, size: 70, color: _navy),
          ),
          Positioned(
            bottom: 54,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'قانونك • بوضوح',
                style: TextStyle(color: _navy, fontWeight: FontWeight.w900, fontSize: 12),
              ),
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
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _navy, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(color: _navy, fontWeight: FontWeight.w900, fontSize: 12),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: _textMid, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Trust extends StatelessWidget {
  const _Trust();

  @override
  Widget build(BuildContext context) {
    const items = [
      _TrustItem(Icons.search_rounded, 'اختيار واضح'),
      _TrustItem(Icons.verified_user_outlined, 'محامون موثقون'),
      _TrustItem(Icons.chat_bubble_outline_rounded, 'متابعة الطلب'),
      _TrustItem(Icons.phone_iphone_rounded, 'تجربة متجاوبة'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _navy.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 17, color: _gold),
                    const SizedBox(width: 7),
                    Text(
                      item.text,
                      style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return _Section(
      eyebrow: 'كيف تعمل المنصة؟',
      title: 'ثلاث خطوات وتبدأ رحلتك',
      subtitle: 'تجربة قانونية بسيطة من الطلب إلى المتابعة.',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 14,
        children: const [
          _Step('01', Icons.edit_note_rounded, 'اطلب استشارة', 'سجّل طلبك وأدخل تفاصيل الموضوع القانوني.'),
          _Step('02', Icons.manage_search_rounded, 'اختر المحامي', 'استعرض التخصصات والملفات المهنية المتاحة.'),
          _Step('03', Icons.forum_outlined, 'تواصل وتابع', 'تابع حالة طلبك واستكمل خطواتك من مكان واحد.'),
        ],
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
      width: 310,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _navy.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                number,
                style: const TextStyle(color: Color(0x35C9A84C), fontSize: 28, fontWeight: FontWeight.w900),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: _navy),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            title,
            style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.right,
            style: const TextStyle(color: _textMid, fontSize: 12, height: 1.65),
          ),
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
    final categories = data.maybeWhen(
      data: (items) => items
          .expand((lawyer) => lawyer.specializations)
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .take(10)
          .toList(),
      orElse: () => <String>[],
    );

    const fallback = [
      'القانون المدني',
      'القانون الجزائي',
      'الأحوال الشخصية',
      'القانون التجاري',
      'القانون الإداري',
      'العقارات',
    ];

    final list = categories.isEmpty ? fallback : categories;

    return _Section(
      eyebrow: 'تخصصات قانونية',
      title: 'اعثر على التخصص المناسب',
      subtitle: 'مجموعة متنوعة من التخصصات لتصل إلى المحامي الأنسب لاحتياجك.',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: list
            .map(
              (item) => ActionChip(
                label: Text(item),
                avatar: const Icon(Icons.gavel_rounded, size: 17),
                onPressed: () => context.push('/legal-categories'),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Lawyers extends StatelessWidget {
  final AsyncValue<List<LawyerProfile>> data;

  const _Lawyers({required this.data});

  @override
  Widget build(BuildContext context) {
    final lawyers = data.maybeWhen(
      data: (items) => items.take(6).toList(),
      orElse: () => <LawyerProfile>[],
    );

    return _Section(
      eyebrow: 'محامون',
      title: 'اختر محاميك بثقة',
      subtitle: 'تصفح الملفات المهنية وتعرّف على التخصصات المتاحة.',
      child: lawyers.isEmpty
          ? Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                'سيظهر المحامون المتاحون هنا عند توفر ملفات موثقة.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textMid),
              ),
            )
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: lawyers.map((lawyer) => _LawyerCard(lawyer)).toList(),
            ),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final LawyerProfile lawyer;

  const _LawyerCard(this.lawyer);

  @override
  Widget build(BuildContext context) {
    final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName! : 'محامٍ';
    final specialties = lawyer.specializations.isEmpty
        ? 'محامٍ'
        : lawyer.specializations.take(2).join(' • ');

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _navy.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _navy, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_rounded, color: _goldLight),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            specialties,
            textAlign: TextAlign.right,
            style: const TextStyle(color: _textMid, fontSize: 12),
          ),
          const SizedBox(height: 16),
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
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 60),
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(28),
      ),
      child: wide
          ? Row(
              children: [
                Expanded(child: _CtaCopy()),
                const SizedBox(width: 24),
                _LawyerJoinButton(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CtaCopy(),
                const SizedBox(height: 20),
                _LawyerJoinButton(),
              ],
            ),
    );
  }
}

class _CtaCopy extends StatelessWidget {
  const _CtaCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        Text(
          'هل أنت محامٍ؟',
          style: TextStyle(color: _goldLight, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 7),
        Text(
          'أنشئ ملفك المهني ووسّع حضورك القانوني.',
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 8),
        Text(
          'انضم إلى استشارة وابدأ باستقبال طلبات الاستشارة المناسبة لتخصصك.',
          textAlign: TextAlign.right,
          style: TextStyle(color: Color(0xFFB9C5D5), height: 1.6),
        ),
      ],
    );
  }
}

class _LawyerJoinButton extends StatelessWidget {
  const _LawyerJoinButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => context.go('/signup'),
      style: FilledButton.styleFrom(
        backgroundColor: _gold,
        foregroundColor: _navy,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      child: const Text('انضم كمحامٍ', style: TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq();

  @override
  Widget build(BuildContext context) {
    const faqs = [
      _FaqItem(
        'كيف أطلب استشارة قانونية؟',
        'أنشئ حساباً، ثم اختر المحامي أو التخصص المناسب وأرسل طلبك مع تفاصيل الموضوع.',
      ),
      _FaqItem(
        'هل يمكنني التسجيل برقم الهاتف؟',
        'نعم، يمكنك التسجيل والتحقق من رقم الهاتف عبر Telegram، كما يتوفر التسجيل باستخدام Google.',
      ),
      _FaqItem(
        'هل يمكن للمحامي إنشاء ملف مهني؟',
        'نعم، يمكن للمحامي إكمال بياناته المهنية وتخصصاته وإدارة ملفه من لوحة المحامي.',
      ),
      _FaqItem(
        'هل بياناتي محمية؟',
        'تُدار بيانات الحساب والطلبات ضمن صلاحيات النظام وبنية مخصصة للخصوصية والأمان.',
      ),
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
              title: Text(
                faq.question,
                textAlign: TextAlign.right,
                style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              children: [
                Text(
                  faq.answer,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: _textMid, height: 1.7),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget child;

  const _Section({
    this.eyebrow,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 64, 18, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _goldMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 32,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textMid, fontSize: 15, height: 1.7),
                ),
              ],
              const SizedBox(height: 34),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _navyDeep,
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
      child: Column(
        children: [
          const Icon(Icons.balance_rounded, color: _gold, size: 34),
          const SizedBox(height: 10),
          const Text(
            'استشارة',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'منصة الاستشارات القانونية',
            style: TextStyle(color: Color(0xFF9AA9BD), fontSize: 11),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              TextButton(onPressed: () => context.push('/privacy'), child: const Text('الخصوصية')),
              TextButton(onPressed: () => context.push('/terms'), child: const Text('الشروط')),
              TextButton(onPressed: () => context.push('/contact'), child: const Text('تواصل معنا')),
              TextButton(onPressed: () => context.go('/login'), child: const Text('لدي حساب')),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0x22FFFFFF)),
          const SizedBox(height: 14),
          const Text(
            '© استشارة — جميع الحقوق محفوظة',
            style: TextStyle(color: Color(0x668FA0B6), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
