import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking': return Icons.calendar_month_rounded;
      case 'payment': return Icons.payments_rounded;
      case 'chat': return Icons.chat_bubble_rounded;
      case 'admin': return Icons.verified_user_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('التنبيهات'),
        leading: const BackButton(),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                await markAllNotificationsAsRead();
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationsCountProvider);
              },
              child: const Text('قراءة الكل', style: TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Padding(padding: const EdgeInsets.all(AppSizes.p20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.notifications_off_rounded, size: 52, color: AppColors.outline),
          const SizedBox(height: 12),
          const Text('تعذر تحميل التنبيهات'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => ref.invalidate(notificationsProvider), child: const Text('إعادة المحاولة')),
        ]))),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async { ref.invalidate(notificationsProvider); ref.invalidate(unreadNotificationsCountProvider); },
              child: ListView(children: const [SizedBox(height: 180), Icon(Icons.notifications_none_rounded, size: 72, color: AppColors.outline), SizedBox(height: 16), Center(child: Text('لا توجد تنبيهات حالياً', style: TextStyle(color: AppColors.textSecondary)))])
            );
          }

          final now = DateTime.now();
          final today = <dynamic>[];
          final previous = <dynamic>[];
          for (final item in items) {
            final date = item.createdAt.toLocal();
            if (date.year == now.year && date.month == now.month && date.day == now.day) {
              today.add(item);
            } else {
              previous.add(item);
            }
          }

          return RefreshIndicator(
            onRefresh: () async { ref.invalidate(notificationsProvider); ref.invalidate(unreadNotificationsCountProvider); },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (today.isNotEmpty) ...[
                  const _GroupTitle('اليوم'),
                  ...today.map((item) => _NotificationCard(item: item, iconForType: _iconForType, onChanged: () { ref.invalidate(notificationsProvider); ref.invalidate(unreadNotificationsCountProvider); })),
                ],
                if (previous.isNotEmpty) ...[
                  const _GroupTitle('سابقاً'),
                  ...previous.map((item) => _NotificationCard(item: item, iconForType: _iconForType, onChanged: () { ref.invalidate(notificationsProvider); ref.invalidate(unreadNotificationsCountProvider); })),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String title;
  const _GroupTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 10), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)));
}

class _NotificationCard extends StatelessWidget {
  final dynamic item;
  final IconData Function(String) iconForType;
  final VoidCallback onChanged;
  const _NotificationCard({required this.item, required this.iconForType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('HH:mm', 'ar').format(item.createdAt.toLocal());
    final unread = !item.isRead;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: unread ? AppColors.surface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unread ? AppColors.gold.withValues(alpha: .35) : AppColors.outline),
        boxShadow: [if (unread) BoxShadow(color: AppColors.gold.withValues(alpha: .08), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: unread ? () async { await markNotificationAsRead(item.id); onChanged(); } : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: unread ? AppColors.gold.withValues(alpha: .16) : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)), child: Icon(iconForType(item.type), color: unread ? AppColors.goldDark : AppColors.primaryDark)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary))), if (unread) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.goldDark, shape: BoxShape.circle))]),
              if (item.body.isNotEmpty) ...[const SizedBox(height: 5), Text(item.body, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary))],
              const SizedBox(height: 7),
              Text(date, style: const TextStyle(fontSize: 10, color: AppColors.outline)),
            ])),
          ]),
        ),
      ),
    );
  }
}
