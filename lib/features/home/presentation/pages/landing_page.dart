import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';

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
            SliverToBoxAdapter(child: const _Trust()),
            SliverToBoxAdapter(child: const _HowItWorks()),
            SliverToBoxAdapter(child: _Specializations(data: lawyers)),
            SliverToBoxAdapter(child: _Lawyers(data: lawyers)),
            SliverToBoxAdapter(child: const _LawyerCta()),
            SliverToBoxAdapter(child: const _Faq()),
            SliverToBoxAdapter(child: const _Footer()),
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
      padding: EdgeInsets.symmetric(horizontal: wide ? 56 : 18, vertical: 13),
      decoration: BoxDecoration(
        color: s.surface.withValues(alpha: .95),
        border: Border(bottom: BorderSide(color: s.outlineVariant)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [s.primary, s.secondary]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.balance_rounded, color: s.onPrimary),
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
            TextButton(onPressed: () => context.push('/login'), child: const Text('دخول')),
            const SizedBox(width: 6),
          ],
          FilledButton(onPressed: () => context.push('/signup'), child: const Text('إنشاء حساب')),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: s.surface.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: s.outlineVariant),
          ),
          child: Text('منصة قانونية عراقية', style: TextStyle(color: s.primary, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
        const SizedBox(height: 18),
        Text(
          'استشارتك القانونية\nتبدأ من هنا',
          textAlign: TextAlign.right,
          style: TextStyle(color: s.onSurface, fontSize: wide ? 50 : 36, height: 1.12, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Text(
          'اطلب استشارة قانونية وتعرّف على المحامي المناسب لتخصصك، ثم تابع طلبك من مكان واحد.',
          textAlign: TextAlign.right,
          style: TextStyle(color: s.onSurfaceVariant, fontSize: 15, height: 1.7),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => context.push('/lawyers'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('اطلب استشارة الآن'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/signup'),
              icon: const Icon(Icons.gavel_rounded),
              label: const Text('انضم كمحامٍ'),
            ),
          ],
        ),
      ],
    );

    final visual = const _HeroVisual();
    return Container(
      margin: EdgeInsets.symmetric(horizontal: wide ? 44 : 12, vertical: 18),
      padding: EdgeInsets.all(wide ? 52 : 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [s.primaryContainer, s.surfaceContainerHighest],
        ),
        border: Border.all(color: s.outlineVariant),
        boxShadow: [BoxShadow(color: s.shadow.withValues(alpha: .08), blurRadius: 30, offset: const Offset(0, 16))],
      ),
      child: wide
          ? Row(textDirection: TextDirection.rtl, children: [Expanded(flex: 6, child: content), const SizedBox(width: 40), Expanded(flex: 4, child: visual)])
          : Column(children: [content, const SizedBox(height: 30), visual]),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      height: 290,
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: s.surface.withValues(alpha: .55),
        border: Border.all(color: s.outlineVariant),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 22, right: 18, child: _Badge(icon: Icons.verified_rounded, text: 'محامون موثقون')),
          Positioned(bottom: 25, left: 16, child: _Badge(icon: Icons.lock_outline_rounded, text: 'بياناتك محمية')),
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [s.primary, s.secondary]),
              boxShadow: [BoxShadow(color: s.primary.withValues(alpha: .25), blurRadius: 35)],
            ),
            child: Icon(Icons.balance_rounded, size: 68, color: s.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Badge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: s.surface.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: s.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: s.primary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: s.onSurface)),
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
    final items = [
      (Icons.search_rounded, 'اختيار واضح'),
      (Icons.verified_user_outlined, 'اعتماد ومراجعة'),
      (Icons.chat_bubble_outline_rounded, 'متابعة الطلب'),
      (Icons.phone_iphone_rounded, 'مصمم للموبايل'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 35),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: items
            .map((item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: s.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: s.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(item.$1, size: 17, color: s.primary), const SizedBox(width: 6), Text(item.$2, style: TextStyle(fontWeight: FontWeight.w700, color: s.onSurface, fontSize: 12))],
                  ),
                ))
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
      title: 'رحلة بسيطة من الطلب إلى المتابعة',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 14,
        children: const [
          _Step(number: '01', icon: Icons.edit_note_rounded, title: 'اطلب استشارة', text: 'سجّل طلبك وأدخل تفاصيل الموضوع القانوني.'),
          _Step(number: '02', icon: Icons.manage_search_rounded, title: 'اختر التخصص', text: 'استعرض المحامين والتخصصات المتاحة.'),
          _Step(number: '03', icon: Icons.forum_outlined, title: 'تواصل وتابع', text: 'تابع حالة طلبك واستخدم المحادثة عند توفرها.'),
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
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(color: s.surfaceContainerLowest, borderRadius: BorderRadius.circular(23), border: Border.all(color: s.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(number, style: TextStyle(color: s.primary.withValues(alpha: .55), fontSize: 24, fontWeight: FontWeight.w900)), Container(width: 46, height: 46, decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: s.primary))]),
          const SizedBox(height: 17),
          Text(title, textAlign: TextAlign.right, style: TextStyle(color: s.onSurface, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.right, style: TextStyle(color: s.onSurfaceVariant, height: 1.6, fontSize: 12)),
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
      title: 'اختر المجال الأقرب إلى حاجتك',
      child: cats.isEmpty
          ? _StateCard(icon: Icons.category_outlined, text: data.isLoading ? 'جاري تحميل التخصصات من المنصة...' : 'لا توجد تخصصات متاحة للعرض حالياً.')
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 9,
              runSpacing: 9,
              children: cats.map((c) => ActionChip(avatar: const Icon(Icons.gavel_rounded, size: 16), label: Text(c), onPressed: () => context.push('/lawyers'))).toList(),
            ),
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
      eyebrow: 'المحامون',
      title: 'محامون من الدليل العام للمنصة',
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: s.surfaceContainerLowest, borderRadius: BorderRadius.circular(20), border: Border.all(color: s.outlineVariant)),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: s.primaryContainer,
              backgroundImage: lawyer.avatarUrl?.isNotEmpty == true ? NetworkImage(lawyer.avatarUrl!) : null,
              child: lawyer.avatarUrl?.isNotEmpty == true ? null : Icon(Icons.person_outline_rounded, color: s.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: s.onSurface, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(lawyer.specializations.take(2).join('، '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: s.onSurfaceVariant, fontSize: 10)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [const Icon(Icons.star_rounded, size: 14), const SizedBox(width: 3), Text(lawyer.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))]),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: s.inverseSurface, borderRadius: BorderRadius.circular(28)),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('هل أنت محامٍ؟', style: TextStyle(color: s.onInverseSurface, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text('انضم إلى المنصة وأرسل طلبك للمراجعة والاعتماد.', textAlign: TextAlign.right, style: TextStyle(color: s.onInverseSurface.withValues(alpha: .72))),
              ],
            ),
          ),
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
    const faqs = <(String, String)>[
      ('هل أحتاج إلى حساب لطلب الاستشارة؟', 'تحتاج إلى تسجيل الدخول عند تنفيذ الخدمة وإرسال الطلب، بينما يمكنك تصفح المعلومات العامة دون حساب.'),
      ('هل يمكنني التسجيل كمحامٍ؟', 'نعم. يمكنك بدء التسجيل وإرسال بياناتك للمراجعة وفق متطلبات المنصة الحالية.'),
      ('هل بيانات المحامين العامة متاحة للجميع؟', 'يعرض الموقع فقط البيانات العامة المسموح بها من نظام المنصة.'),
      ('كيف أتابع طلب الاستشارة؟', 'بعد تسجيل الدخول يمكنك متابعة طلباتك وحالتها من واجهة المستخدم.'),
    ];

    return _Section(
      eyebrow: 'الأسئلة الشائعة',
      title: 'قبل أن تبدأ',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          children: faqs.map<Widget>((faq) {
            return Card(
              child: ExpansionTile(
                title: Text(faq.$1, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                children: [Text(faq.$2, textAlign: TextAlign.right, style: const TextStyle(height: 1.6))],
              ),
            );
          }).toList(),
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
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(eyebrow, textAlign: TextAlign.center, style: TextStyle(color: s.primary, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Expanded(child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: s.onSurface, fontSize: 25, fontWeight: FontWeight.w900))), if (action != null) action!]),
          const SizedBox(height: 18),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: s.outlineVariant)),
      child: Column(children: [Icon(icon, size: 30, color: s.primary), const SizedBox(height: 8), Text(text, textAlign: TextAlign.center)]),
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
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      color: s.surfaceContainerHighest,
      child: Column(
        children: [
          Text('استشارة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: s.onSurface)),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 14, children: [TextButton(onPressed: () => context.push('/legal-categories'), child: const Text('التخصصات')), TextButton(onPressed: () => context.push('/lawyers'), child: const Text('المحامون')), TextButton(onPressed: () => context.push('/login'), child: const Text('تسجيل الدخول'))]),
          const SizedBox(height: 8),
          Text('© استشارة — منصة الاستشارات القانونية', style: TextStyle(color: s.onSurfaceVariant, fontSize: 11)),
        ],
      ),
    );
  }
}
