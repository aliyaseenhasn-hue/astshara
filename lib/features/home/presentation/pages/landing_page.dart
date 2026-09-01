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
    final lawyersAsync = ref.watch(lawyersListProvider);

    return Scaffold(
      backgroundColor: _offWhite,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _navy,
              elevation: 0,
              title: const Text('استشارة', style: TextStyle(fontWeight: FontWeight.w800)),
              actions: [
                TextButton(onPressed: () => context.push('/lawyers'), child: const Text('المحامون', style: TextStyle(color: Colors.white))),
                TextButton(onPressed: () => context.push('/login'), child: const Text('تسجيل الدخول', style: TextStyle(color: _goldLight))),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                color: _navy,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 56),
                child: Column(
                  children: [
                    const Text(
                      '«من لم يشرب من بئر الاستشارة\nيمت عطشًا في صحراء الاجتهادات»',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _goldLight, fontSize: 21, height: 1.6, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'استشارتك القانونية تبدأ من هنا',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 32, height: 1.25, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'تواصل مع محامٍ موثوق واحصل على التوجيه القانوني الذي تحتاجه.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 2)),
                      child: const Icon(Icons.balance, color: _goldLight, size: 92),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: () => context.push('/signup'),
                      style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _navy, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16)),
                      child: const Text('اطلب استشارة الآن', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle('كيف تعمل استشارة؟')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Row(
                  children: const [
                    Expanded(child: _Step(number: '1', title: 'اختر محاميًا', icon: Icons.person_search_outlined)),
                    Expanded(child: _Step(number: '2', title: 'أرسل طلبك', icon: Icons.edit_note_outlined)),
                    Expanded(child: _Step(number: '3', title: 'تابع استشارتك', icon: Icons.chat_bubble_outline)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle('محامون موثوقون')),
            lawyersAsync.when(
              loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (lawyers) {
                final verified = lawyers.where((l) => l.isVerified).take(6).toList();
                if (verified.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('سيظهر المحامون الموثوقون هنا قريبًا.'))));
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ...verified.map((lawyer) => _LawyerCard(lawyer: lawyer)),
                      const SizedBox(height: 12),
                      Center(child: TextButton(onPressed: () => context.push('/lawyers'), child: const Text('عرض جميع المحامين'))),
                    ]),
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 36, 20, 48),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    const Text('لا تترك مسألتك القانونية للاجتهاد', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    const Text('ابدأ الآن واختر المحامي المناسب لك.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: () => context.push('/signup'), style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _navy), child: const Text('ابدأ الآن', style: TextStyle(fontWeight: FontWeight.w800))),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: _navyDeep,
                padding: const EdgeInsets.all(24),
                child: const Center(child: Text('استشارة © جميع الحقوق محفوظة', style: TextStyle(color: Colors.white60))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 18),
        child: Text(title, style: const TextStyle(color: _navy, fontSize: 24, fontWeight: FontWeight.w900)),
      );
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.icon});
  final String number;
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(children: [Icon(icon, color: _goldMuted, size: 30), const SizedBox(height: 8), Text('$number. $title', textAlign: TextAlign.center, style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 13))]),
      );
}

class _LawyerCard extends StatelessWidget {
  const _LawyerCard({required this.lawyer});
  final LawyerProfile lawyer;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/lawyers/${lawyer.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(radius: 30, backgroundImage: lawyer.avatarUrl != null ? NetworkImage(lawyer.avatarUrl!) : null, child: lawyer.avatarUrl == null ? const Icon(Icons.person, color: _navy) : null),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(lawyer.fullName, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 16))), const Icon(Icons.verified, color: _gold, size: 19)]),
                const SizedBox(height: 5),
                Text(lawyer.specialization ?? 'محامٍ', style: const TextStyle(color: _textMid, fontSize: 13)),
              ])),
              const Icon(Icons.chevron_left, color: _textMid),
            ]),
          ),
        ),
      );
}
