import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';
import '../../../lawyers/domain/entities/lawyer_profile.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final lawyers = ref.watch(lawyersListProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(isWide: isWide)),
            SliverToBoxAdapter(child: _Hero(isWide: isWide)),
            SliverToBoxAdapter(child: _TrustStrip()),
            SliverToBoxAdapter(child: _HowItWorks()),
            SliverToBoxAdapter(child: _Specializations(lawyers: lawyers)),
            SliverToBoxAdapter(child: _LawyersPreview(lawyers: lawyers)),
            SliverToBoxAdapter(child: _LawyerCta()),
            SliverToBoxAdapter(child: _Faq()),
            SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isWide;
  const _Header({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 56 : 20, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .92),
        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6))),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.balance_rounded, color: scheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('استشارة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: scheme.onSurface)),
                Text('منصة الاستشارات القانونية', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (isWide) ...[
            TextButton(onPressed: () => context.push('/lawyers'), child: const Text('المحامون')),
            TextButton(onPressed: () => context.push('/legal-categories'), child: const Text('التخصصات')),
            TextButton(onPressed: () => context.push('/login'), child: const Text('تسجيل الدخول')),
            const SizedBox(width: 8),
          ],
          FilledButton(onPressed: () => context.push('/signup'), child: const Text('إنشاء حساب')),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool isWide;
  const _Hero({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWide ? 44 : 14, vertical: 18),
      padding: EdgeInsets.all(isWide ? 56 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [scheme.primaryContainer, scheme.surfaceContainerHighest],
        ),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: .08), blurRadius: 30, offset: const Offset(0, 16))],
      ),
      child: Flex(
        direction: isWide ? Axis.horizontal : Axis.vertical,
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: isWide ? 6 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: scheme.surface.withValues(alpha: .58), borderRadius: BorderRadius.circular(99), border: Border.all(color: scheme.outlineVariant)),
                  child: Text('منصة قانونية عراقية', style: TextStyle(color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 18),
                Text('استشارتك القانونية\nتبدأ من هنا', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: isWide ? 50 : 36, height: 1.12, fontWeight: FontWeight.w900, letterSpacing: -.6)),
                const SizedBox(height: 14),
                Text('اطلب استشارة قانونية وتعرّف على المحامي المناسب لتخصصك، ثم تابع طلبك من مكان واحد.', textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15, height: 1.7)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    FilledButton.icon(onPressed: () => context.push('/lawyers'), icon: const Icon(Icons.arrow_back_rounded), label: const Text('اطلب استشارة الآن')),
                    OutlinedButton.icon(onPressed: () => context.push('/signup'), icon: const Icon(Icons.gavel_rounded), label: const Text('انضم كمحامٍ')),
                  ],
                ),
              ],
            ),
          ),
          if (isWide) const SizedBox(width: 42) else const SizedBox(height: 32),
          Expanded(
            flex: isWide ? 4 : 0,
            child: _HeroVisual(),
          ),
        ],
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: scheme.surface.withValues(alpha: .55),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 24, right: 22, child: _FloatCard(icon: Icons.verified_rounded, text: 'محامون موثقون')),
          Positioned(bottom: 30, left: 18, child: _FloatCard(icon: Icons.lock_outline_rounded, text: 'بياناتك محمية')),
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
              boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .25), blurRadius: 35, spreadRadius: 4)],
            ),
            child: Icon(Icons.balance_rounded, size: 68, color: scheme.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _FloatCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FloatCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: scheme.surface.withValues(alpha: .84), borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outlineVariant)),
      child: Row(children: [Icon(icon, size: 18, color: scheme.primary), const SizedBox(width: 7), Text(text, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 11))]),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = [
      (Icons.search_rounded, 'اختيار واضح'),
      (Icons.verified_user_outlined, 'اعتماد ومراجعة'),
      (Icons.chat_bubble_outline_rounded, 'متابعة الطلب'),
      (Icons.phone_iphone_rounded, 'مصمم للموبايل'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: items.map((item) => Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11), decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(99), border: Border.all(color: scheme.outlineVariant)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(item.$1, size: 17, color: scheme.primary), const SizedBox(width: 7), Text(item.$2, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface, fontSize: 12))]))).toList(),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 310,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(24), border: Border.all(color: scheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(number, style: TextStyle(color: scheme.primary.withValues(alpha: .55), fontSize: 25, fontWeight: FontWeight.w900)), Container(width: 48, height: 48, decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: scheme.primary))]),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(text, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6, fontSize: 12)),
      ]),
    );
  }
}

class _Specializations extends StatelessWidget {
  final AsyncValue<List<LawyerProfile>> lawyers;
  const _Specializations({required this.lawyers});

  @override
  Widget build(BuildContext context) {
    final categories = lawyers.maybeWhen(
      data: (items) => items.expand((l) => l.specializations).map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().take(8).toList(),
      orElse: () => <String>[],
    );
    return _Section(
      eyebrow: 'التخصصات القانونية',
      title: 'اختر المجال الأقرب إلى حاجتك',
      child: categories.isEmpty
          ? _DataState(text: lawyers.isLoading ? 'جاري تحميل التخصصات من المنصة...' : 'لا توجد تخصصات متاحة للعرض حالياً.', icon: Icons.category_outlined)
          : Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: categories.map((category) => ActionChip(avatar: const Icon(Icons.gavel_rounded, size: 17), label: Text(category), onPressed: () { refSafePush(context, '/lawyers'); })).toList()),
    );
  }
}

void refSafePush(BuildContext context, String route) => context.push(route);

class _LawyersPreview extends StatelessWidget {
  final AsyncValue<List<LawyerProfile>> lawyers;
  const _LawyersPreview({required this.lawyers});

  @override
  Widget build(BuildContext context) {
    final items = lawyers.maybeWhen(data: (value) => value.take(4).toList(), orElse: () => <LawyerProfile>[]);
    return _Section(
      eyebrow: 'المحامون',
      title: 'محامون من الدليل العام للمنصة',
      action: TextButton(onPressed: () => context.push('/lawyers'), child: const Text('عرض جميع المحامين')),
      child: lawyers.isLoading
          ? const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())
          : items.isEmpty
              ? const _DataState(text: 'لا توجد بيانات محامين متاحة للعرض حالياً.', icon: Icons.person_search_outlined)
              : Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: items.map((lawyer) => _LawyerCard(lawyer: lawyer)).toList()),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final LawyerProfile lawyer;
  const _LawyerCard({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = lawyer.fullName?.trim().isNotEmpty == true ? lawyer.fullName!.trim() : 'محامٍ';
    return InkWell(
      onTap: () => context.push('/lawyers/${lawyer.profileId}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(20), border: Border.all(color: scheme.outlineVariant)),
        child: Row(textDirection: TextDirection.rtl, children: [
          CircleAvatar(radius: 25, backgroundColor: scheme.primaryContainer, backgroundImage: lawyer.avatarUrl?.isNotEmpty == true ? NetworkImage(lawyer.avatarUrl!) : null, child: lawyer.avatarUrl?.isNotEmpty == true ? null : Icon(Icons.person_outline_rounded, color: scheme.primary)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(lawyer.specializations.take(2).join('، '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)), const SizedBox(height: 5), Row(mainAxisAlignment: MainAxisAlignment.end, children: [const Icon(Icons.star_rounded, size: 14), const SizedBox(width: 3), Text(lawyer.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))])]))
        ]),
      ),
    );
  }
}

class _LawyerCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: scheme.inverseSurface, border: Border.all(color: scheme.outlineVariant)),
      child: Wrap(alignment: WrapAlignment.spaceBetween, runAlignment: WrapAlignment.center, runSpacing: 20, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('هل أنت محامٍ؟', style: TextStyle(color: scheme.onInverseSurface, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text('انضم إلى المنصة وأرسل طلبك للمراجعة والاعتماد.', style: TextStyle(color: scheme.onInverseSurface.withValues(alpha: .72), height: 1.5))]),
        FilledButton.tonalIcon(onPressed: () => context.push('/signup'), icon: const Icon(Icons.gavel_rounded), label: const Text('سجّل كمحامٍ')),
      ]),
    );
  }
}

class _Faq extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const faqs = [
      ('هل أحتاج إلى حساب لطلب الاستشارة؟', 'تحتاج إلى تسجيل الدخول عند تنفيذ الخدمة وإرسال الطلب، بينما يمكنك تصفح المعلومات العامة دون حساب.'),
      ('هل يمكنني التسجيل كمحامٍ؟', 'نعم، اختر نوع الحساب محامٍ عند التسجيل وأكمل بيانات الملف المطلوبة وفق إجراءات المنصة.'),
      ('هل بيانات المحامين عامة؟', 'يتم عرض البيانات المهنية العامة المسموح بها فقط، ولا تُعرض البيانات الخاصة أو الحساسة للزوار.'),
      ('هل الاستشارة تتم بواسطة الذكاء الاصطناعي؟', 'لا. المنصة مخصصة لربط طالب الاستشارة بالمحامي، ولا تقدم استشارات قانونية آلية بالذكاء الاصطناعي.'),
    ];
    return _Section(eyebrow: 'الأسئلة الشائعة', title: 'قبل أن تبدأ', child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Column(children: faqs.map((faq) => Card(color: scheme.surfaceContainerLowest, child: ExpansionTile(title: Text(faq.$1, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)), childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18), children: [Text(faq.$2, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6))])).toList())));
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.fromLTRB(24, 36, 24, 28), decoration: BoxDecoration(color: scheme.surfaceContainerHighest, border: Border(top: BorderSide(color: scheme.outlineVariant))), child: Column(children: [Text('استشارة', style: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text('منصة للاستشارات القانونية في العراق', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)), const SizedBox(height: 18), Wrap(alignment: WrapAlignment.center, spacing: 8, children: [TextButton(onPressed: () => context.push('/help-center'), child: const Text('مركز المساعدة')), TextButton(onPressed: () => context.push('/signup'), child: const Text('إنشاء حساب')), TextButton(onPressed: () => context.push('/login'), child: const Text('تسجيل الدخول'))]), const SizedBox(height: 12), Text('© ${DateTime.now().year} استشارة. جميع الحقوق محفوظة.', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10))]));
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.fromLTRB(20, 26, 20, 35), child: Column(children: [Text(eyebrow, style: TextStyle(color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Row(mainAxisAlignment: MainAxisAlignment.center, children: [Flexible(child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface, fontSize: 27, fontWeight: FontWeight.w900))), if (action != null) action!]), const SizedBox(height: 22), child]));
  }
}

class _DataState extends StatelessWidget {
  final String text;
  final IconData icon;
  const _DataState({required this.text, required this.icon});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)), child: Column(children: [Icon(icon, size: 30), const SizedBox(height: 8), Text(text, textAlign: TextAlign.center)]) );
}
