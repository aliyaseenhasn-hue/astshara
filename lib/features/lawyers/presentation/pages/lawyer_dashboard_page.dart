import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../domain/entities/lawyer_profile.dart';
import '../providers/lawyers_provider.dart';

class LawyerDashboardPage extends ConsumerWidget {
  const LawyerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final bookings = ref.watch(lawyerBookingsProvider);
    final profileIdAsync = ref.watch(currentProfileIdProvider);
    final profileAsync = profileIdAsync.when(
      data: (id) => id == null ? const AsyncValue<LawyerProfile?>.data(null) : ref.watch(ownLawyerProfileProvider(id)),
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الرئيسية', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تعديل الملف المهني',
            onPressed: () => context.push('/lawyer-profile-edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('تعذر تحميل البيانات')),
        data: (items) {
          final completed = items.where((b) => b.status == 'مكتمل').length;
          final active = items.where((b) => b.status == 'مؤكد' || b.status == 'قيد التنفيذ').length;
          final total = items.fold<double>(0, (sum, booking) => sum + booking.price);
          final profile = profileAsync.value;
          final registeredName = user?.fullName?.trim();
          final profileName = profile?.fullName?.trim();
          final name = registeredName != null && registeredName.isNotEmpty
              ? registeredName
              : (profileName != null && profileName.isNotEmpty ? profileName : 'أستاذ قانون');
          final specialization = profile?.specializations.isNotEmpty == true ? profile!.specializations.join('، ') : 'محامي ومستشار قانوني';
          final license = profile?.practiceLicenseClass;
          final avatar = user?.avatarUrl;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(lawyerBookingsProvider);
              if (profileIdAsync.value != null) ref.invalidate(ownLawyerProfileProvider(profileIdAsync.value!));
              await Future<void>.delayed(const Duration(milliseconds: 250));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                _ProfileHero(
                  name: name,
                  specialization: specialization,
                  license: license,
                  avatarUrl: avatar,
                  onTap: () => context.push('/lawyer-profile-edit'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _MetricCard(value: '$active', label: 'استشارات نشطة', icon: Icons.forum_rounded, background: AppColors.tertiary, foreground: Colors.white)),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricCard(value: '$completed', label: 'استشارات مكتملة', icon: Icons.task_alt_rounded, background: AppColors.success, foreground: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                _MoneyCard(total: total),
                const SizedBox(height: 22),
                Card(
                  elevation: 0,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.outlineVariant)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/lawyer-profile-edit'),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.badge_outlined, color: AppColors.onSecondaryContainer)),
                          const SizedBox(width: 12),
                          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('ملفي المهني', textAlign: TextAlign.right, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('تعديل البيانات والتخصص والباقات وأوقات التوفر', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 12))])),
                          const Icon(Icons.chevron_left_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [const Expanded(child: Text('طلبات الاستشارة الواردة', textAlign: TextAlign.right, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), Text('${items.length} طلب', style: const TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.w800))]),
                const SizedBox(height: 10),
                if (items.isEmpty) const _EmptyState() else ...items.take(5).map((b) => _BookingCard(booking: b)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String name;
  final String specialization;
  final String? license;
  final String? avatarUrl;
  final VoidCallback onTap;
  const _ProfileHero({required this.name, required this.specialization, required this.license, required this.avatarUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x22082B49), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.goldLight, border: Border.all(color: AppColors.ctaGold, width: 3)),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceContainerHighest,
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null || avatarUrl!.isEmpty ? Text(name.substring(0, 1), style: const TextStyle(color: AppColors.primary, fontSize: 40, fontWeight: FontWeight.w900)) : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('محامي', textAlign: TextAlign.center, style: TextStyle(color: AppColors.goldLight, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(specialization, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.goldLight, fontSize: 13, fontWeight: FontWeight.w700, height: 1.4)),
          if (license != null && license!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(14)),
              child: Text('الصلاحية: ${license == 'مطلقة' ? 'مطلقة' : 'الفئة $license'}', style: const TextStyle(color: AppColors.onSecondaryContainer, fontSize: 12, fontWeight: FontWeight.w900)),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(onPressed: onTap, icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18), label: const Text('عرض وتعديل الملف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  const _MetricCard({required this.value, required this.label, required this.icon, required this.background, required this.foreground});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 10),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [Icon(icon, color: foreground, size: 25), const SizedBox(height: 7), Text(value, style: TextStyle(color: foreground, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(label, textAlign: TextAlign.center, style: TextStyle(color: foreground.withValues(alpha: .9), fontSize: 11, fontWeight: FontWeight.w700))]),
      );
}

class _MoneyCard extends StatelessWidget {
  final double total;
  const _MoneyCard({required this.total});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.secondaryContainer, AppColors.goldLight]), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 27)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('إجمالي مبالغ الاستشارات', textAlign: TextAlign.right, style: TextStyle(color: AppColors.onSecondaryContainer, fontSize: 12, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${total.toStringAsFixed(0)} د.ع', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.onSecondaryContainer, fontSize: 25, fontWeight: FontWeight.w900))]))]),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)), child: const Column(children: [Icon(Icons.event_available_rounded, color: AppColors.tertiary, size: 34), SizedBox(height: 8), Text('لا توجد طلبات استشارة حالياً', style: TextStyle(fontWeight: FontWeight.w700))]));
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientNameAsync = ref.watch(bookingClientNameProvider(booking.id));
    final clientName = clientNameAsync.value?.trim();
    final title = clientName != null && clientName.isNotEmpty ? clientName : 'اسم طالب الاستشارة غير متوفر';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => context.push('/booking-details', extra: booking),
        title: Text(title, textDirection: TextDirection.rtl, textAlign: TextAlign.right),
        subtitle: Text(booking.status, textDirection: TextDirection.rtl, textAlign: TextAlign.right),
        trailing: const Icon(Icons.chevron_left_rounded),
      ),
    );
  }
}
