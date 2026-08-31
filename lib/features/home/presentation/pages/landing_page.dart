import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';

class _TrustItem {
  final IconData icon;
  final String text;
  const _TrustItem(this.icon, this.text);
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyers = ref.watch(lawyersListProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(wide: wide)),
            SliverToBoxAdapter(child: _Hero(wide: wide)),
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
  final bool wide;
  const _Header({required this.wide});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: wide ? 56 : 18, vertical: 12),
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(bottom: BorderSide(color: s.outlineVariant.withValues(alpha: .6))),
        boxShadow: [BoxShadow(color: s.shadow.withValues(alpha: .04), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [s.primary, s.secondary]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.balance_rounded, color: s.onPrimary, size: 25),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('استشارة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: s.onSurface)),
                Text('منصة الاستشارات القانونية', style: TextStyle(fontSize: 10, color: s.onSurfaceVariant)),
              ],
            ),
          ),
          if (wide) ...[
            TextButton(onPressed: () => context.push('/lawyers'), child: const Text('المحامون')),
            TextButton(onPressed: () => context.push('/legal-categories'), child: const Text('التخصصات')),
            TextButton(onPressed: () => context.push('/faq'), child: const Text('الأسئلة الشائعة')),
            TextButton(onPressed: () => context.push('/login'), child: const Text('دخول')),
            const SizedBox(width: 5),
          ],
          FilledButton.icon(
            onPressed: () => context.push('/signup'),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('إنشاء حساب'),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool wide;
  const _Hero({required this.wide});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: s.surface.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: s.primary.withValues(alpha: .18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: s.primary),
              const SizedBox(width: 6),
              Text('منصة قانونية عراقية', style: TextStyle(color: s.primary, fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 19),
        Text(
          'استشارتك القانونية\nتبدأ من هنا',
          textAlign: TextAlign.right,
          style: TextStyle(color: s.onSurface, fontSize: wide ? 54 : 38, height: 1.08, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 15),
        Text(
          'ابحث عن المحامي المناسب، أرسل طلبك، وتابع رحلتك القانونية من منصة واحدة مصممة لتكون واضحة وسهلة.',
          textAlign: TextAlign.right,
          style: TextStyle(color: s.onSurfaceVariant, fontSize: 15, height: 1.8),
        ),
        const SizedBox(height: 25),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(onPressed: () => context.push('/lawyers'), icon: const Icon(Icons.arrow_back_rounded), label: const Text('اطلب استشارة الآن')),
            OutlinedButton.icon(onPressed: () => context.push('/signup'), icon: const Icon(Icons.gavel_rounded), label: const Text('انضم كمحامٍ')),
          ],
        ),
        const SizedBox(height: 20),
        const Wrap(
          alignment: WrapAlignment.end,
          spacing: 18,
          runSpacing: 8,
          children: [
            _MiniProof(icon: Icons.verified_user_rounded, text: 'محامون موثقون'),
            _MiniProof(icon: Icons.lock_outline_rounded, text: 'خصوصية وأمان'),
            _MiniProof(icon: Icons.devices_rounded, text: 'متاح على الموبايل والويب'),
          ],
        ),
      ],
    );

    return Container(
      margin: EdgeInsets.fromLTRB(wide ? 42 : 12, 18, wide ? 42 : 12, 10),
      padding: EdgeInsets.all(wide ? 52 : 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        gradient: LinearGradient(colors: [s.primaryContainer, s.surfaceContainerHighest]),
        border: Border.all(color: s.outlineVariant.withValues(alpha: .7)),
        boxShadow: [BoxShadow(color: s.primary.withValues(alpha: .10), blurRadius: 45, offset: const Offset(0, 20))],
      ),
      child: wide
          ? Row(textDirection: TextDirection.rtl, children: [Expanded(flex: 6, child: content), const SizedBox(width: 42), const Expanded(flex: 4, child: _HeroVisual())])
          : Column(children: [content, const SizedBox(height: 30), const _HeroVisual()]),
    );
  }
}

class _MiniProof extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniProof({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: s.primary), const SizedBox(width: 5), Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: s.onSurfaceVariant))]);
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      height: 330,
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(colors: [s.surface.withValues(alpha: .88), s.primaryContainer.withValues(alpha: .35)]),
        border: Border.all(color: s.outlineVariant.withValues(alpha: .8)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 26, left: 24, child: _FloatingCard(icon: Icons.search_rounded, title: 'ابحث', subtitle: 'عن تخصصك')),
          const Positioned(bottom: 27, right: 20, child: _FloatingCard(icon: Icons.forum_rounded, title: 'تابع', subtitle: 'طلبك بسهولة')),
          Positioned(
            child: Container(
              width: 156,
              height: 156,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [s.primary, s.secondary]), boxShadow: [BoxShadow(color: s.primary.withValues(alpha: .28), blurRadius: 42, spreadRadius: 5)]),
              child: Icon(Icons.balance_rounded, size: 72, color: s.onPrimary),
            ),
          ),
          Positioned(
            bottom: 62,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.circular(99), border: Border.all(color: s.outlineVariant)),
              child: Text('قانونك • بوضوح', style: TextStyle(color: s.onSurface, fontWeight: FontWeight.w900, fontSize: 12)),
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
  const _FloatingCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(color: s.surface.withValues(alpha: .94), borderRadius: BorderRadius.circular(17), border: Border.all(color: s.outlineVariant)),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 18, color: s.primary)),
          const SizedBox(width: 9),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: s.onSurface, fontSize: 12)), Text(subtitle, style: TextStyle(color: s.onSurfaceVariant, fontSize: 9))]),
        ],
      ),
    );
  }
}

class _Trust extends StatelessWidget {
  const _Trust();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    const items = [
      _TrustItem(Icons.search_rounded, 'اختيار واضح'),
      _TrustItem(Icons.verified_user_outlined, 'محامون موثقون'),
      _TrustItem(Icons.chat_bubble_outline_rounded, 'متابعة الطلب'),
      _TrustItem(Icons.phone_iphone_rounded, 'تجربة متجاوبة'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: items.map((item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(color: s.surfaceContainerLowest, borderRadius: BorderRadius.circular(99), border: Border.all(color: s.outlineVariant)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(item.icon, size: 17, color: s.primary), const SizedBox(width: 7), Text(item.text, style: TextStyle(fontWeight: FontWeight.w800, color: s.onSurface, fontSize: 12))]),
        )).toList(),
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
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 14,
        children: const [
          _Step(number: '01', icon: Icons.edit_note_rounded, title: 'اطلب استشارة', text: 'سجّل طلبك وأدخل تفاصيل الموضوع القانوني.'),
          _Step(number: '02', icon: Icons.manage_search_rounded, title: 'اختر المحامي', text: 'استعرض التخصصات والملفات المهنية المتاحة.'),
          _Step(number: '03', icon: Icons.forum_outlined, title: 'تواصل وتابع', text: 'تابع حالة طلبك واستكمل خطواتك من مكان واحد.'),
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
  const _Step({required this.number, required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      width: 310,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: s.surfaceContainerLowest, borderRadius: BorderRadius.circular(24), border: Border.all(color: s.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(number, style: TextStyle(color: s.primary.withValues(alpha: .35), fontSize: 27, fontWeight: FontWeight.w900)), Container(width: 48, height: 48, decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: s.primary))]),
          const SizedBox(height: 17),
          Text(title, textAlign: TextAlign.right, style: TextStyle(color: s.onSurface, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.right, style: TextStyle(color: s.onSurfaceVariant, height: 1.65, fontSize: 12)),
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
    final cats = data.maybeWhen(
      data: (items) => items.expand((l) => l.specializations).map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().take(10).toList(),
      orElse: () => <String>[],
    );
    return _Section(
      eyebrow: 'التخصصات القانونية',
      title: 'ابحث حسب المجال الذي تحتاجه',
      child: cats.isEmpty
          ? _StateCard(icon: Icons.category_outlined, text: data.isLoading ? 'جاري تحميل التخصصات...' : 'لا توجد تخصصات متاحة للعرض حالياً.')
          : Wrap(alignment: WrapAlignment.center, spacing: 9, runSpacing: 9, children: cats.map((c) => ActionChip(avatar: const Icon(Icons.gavel_rounded, size: 16), label: Text(c), onPressed: () => context.push('/lawyers'))).toList()),
    );
  }
}

class _Lawyers extends StatelessWidget {
  final AsyncValue<List<LawyerProfile>> data;
  const _Lawyers({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data.maybeWhen(data: (v) => v.take(4).toList(), orElse: () => <LawyerProfile>[]);
    return _Section(
      eyebrow: 'دليل المحامين',
      title: 'تعرّف على المحامين المتاحين',
      action: TextButton(onPressed: () => context.push('/lawyers'), child: const Text('عرض الكل')),
      child: data.isLoading
          ? const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())
          : items.isEmpty
              ? const _StateCard(icon: Icons.person_search_outlined, text: 'لا توجد بيانات محامين متاحة للعرض حالياً.')
              : Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: items.map((l) => _LawyerCard(lawyer: l)).toList()),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final LawyerProfile lawyer;
  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName!.trim() : 'محامٍ';
    return InkWell(
      onTap: () => context.push('/lawyers/${lawyer.profileId}'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 285,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: s.surfaceContainerLowest, borderRadius: BorderRadius.circular(22), border: Border.all(color: s.outlineVariant)),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            CircleAvatar(radius: 27, backgroundColor: s.primaryContainer, backgroundImage: lawyer.avatarUrl?.isNotEmpty == true ? NetworkImage(lawyer.avatarUrl!) : null, child: lawyer.avatarUrl?.isNotEmpty == true ? null : Icon(Icons.person_outline_rounded, color: s.primary)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: s.onSurface, fontWeight: FontWeight.w900))), const SizedBox(width: 5), Icon(Icons.verified_rounded, size: 15, color: s.primary)]),
                  const SizedBox(height: 5),
                  Text(lawyer.specializations.take(2).join('، '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: s.onSurfaceVariant, fontSize: 10)),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [Icon(Icons.star_rounded, size: 15, color: s.secondary), const SizedBox(width: 3), Text(lawyer.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LawyerCta extends StatelessWidget {
  const _LawyerCta();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [s.inverseSurface, s.primary.withValues(alpha: .86)]), borderRadius: BorderRadius.circular(30)),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('هل أنت محامٍ؟', style: TextStyle(color: s.onInverseSurface, fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text('أنشئ ملفك المهني، أضف نبذتك وإنجازاتك، وقدّم طلبك للمراجعة والاعتماد.', textAlign: TextAlign.right, style: TextStyle(color: s.onInverseSurface.withValues(alpha: .78), height: 1.6))])),
          const SizedBox(width: 18),
          FilledButton.tonalIcon(onPressed: () => context.push('/signup'), icon: const Icon(Icons.gavel_rounded), label: const Text('سجّل كمحامٍ')),
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
      _FaqItem('هل أحتاج إلى حساب لطلب الاستشارة؟', 'تحتاج إلى تسجيل الدخول عند تنفيذ الخدمة وإرسال الطلب، بينما يمكنك تصفح المعلومات العامة دون حساب.'),
      _FaqItem('هل يمكنني التسجيل كمحامٍ؟', 'نعم. يمكنك بدء التسجيل وإرسال بياناتك للمراجعة وفق متطلبات المنصة الحالية.'),
      _FaqItem('هل بيانات المحامين العامة متاحة للجميع؟', 'يعرض الموقع فقط البيانات العامة المسموح بها من نظام المنصة.'),
      _FaqItem('كيف أتابع طلب الاستشارة؟', 'بعد تسجيل الدخول يمكنك متابعة طلباتك وحالتها من واجهة المستخدم.'),
    ];
    return _Section(
      eyebrow: 'الأسئلة الشائعة',
      title: 'كل ما تحتاج معرفته قبل البدء',
      action: TextButton(onPressed: () => context.push('/faq'), child: const Text('كل الأسئلة')),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          children: faqs.map<Widget>((faq) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(faq.question, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              children: [Text(faq.answer, textAlign: TextAlign.right, style: const TextStyle(height: 1.6))],
            ),
          )).toList(),
        ),
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
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(eyebrow, textAlign: TextAlign.center, style: TextStyle(color: s.primary, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 7),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Expanded(child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: s.onSurface, fontSize: 26, fontWeight: FontWeight.w900))), if (action != null) action!]),
          const SizedBox(height: 19),
          child,
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StateCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: s.surfaceContainerLowest, borderRadius: BorderRadius.circular(22), border: Border.all(color: s.outlineVariant)),
      child: Column(children: [Icon(icon, size: 31, color: s.primary), const SizedBox(height: 9), Text(text, textAlign: TextAlign.center)]),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
      decoration: BoxDecoration(color: s.surfaceContainerHighest, border: Border(top: BorderSide(color: s.outlineVariant))),
      child: Column(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [s.primary, s.secondary]), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.balance_rounded, color: s.onPrimary)),
          const SizedBox(height: 10),
          Text('استشارة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: s.onSurface)),
          const SizedBox(height: 5),
          Text('منصة الاستشارات القانونية', style: TextStyle(color: s.onSurfaceVariant, fontSize: 11)),
          const SizedBox(height: 13),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              TextButton(onPressed: () => context.push('/how-it-works'), child: const Text('كيف تعمل')),
              TextButton(onPressed: () => context.push('/legal-categories'), child: const Text('التخصصات')),
              TextButton(onPressed: () => context.push('/lawyers'), child: const Text('المحامون')),
              TextButton(onPressed: () => context.push('/faq'), child: const Text('الأسئلة الشائعة')),
              TextButton(onPressed: () => context.push('/privacy'), child: const Text('الخصوصية')),
              TextButton(onPressed: () => context.push('/terms'), child: const Text('الشروط')),
              TextButton(onPressed: () => context.push('/contact'), child: const Text('تواصل معنا')),
            ],
          ),
          const SizedBox(height: 12),
          Text('© استشارة — منصة الاستشارات القانونية', style: TextStyle(color: s.onSurfaceVariant, fontSize: 11)),
        ],
      ),
    );
  }
}
