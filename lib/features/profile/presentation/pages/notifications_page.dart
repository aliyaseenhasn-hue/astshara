import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
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
              child: Text('قراءة الكل', style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_off_rounded, size: 52, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('تعذر تحميل التنبيهات', style: TextStyle(color: scheme.onSurface)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => ref.invalidate(notificationsProvider), child: const Text('إعادة المحاولة')),
            ]),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async { ref.invalidate(notificationsProvider); ref.invalidate(unreadNotificationsCountProvider); },
              child: ListView(children: [const SizedBox(height: 180), Icon(Icons.notifications_none_rounded, size: 72, color: scheme.onSurfaceVariant), const SizedBox(height: 16), Center(child: Text('لا توجد تنبيهات حالياً', style: TextStyle(color: scheme.onSurfaceVariant)))]),
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
                  _GroupTitle('اليوم', scheme: scheme),
                  ...today.map((item) => _NotificationCard(item: item, iconForType: _iconForType, onChanged: () { ref.invalidate(notificationsProvider); ref.invalidate(unreadNotificationsCountProvider); })),
                ],
                if (previous.isNotEmpty) ...[
                  _GroupTitle('سابقاً', scheme: scheme),
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
  final ColorScheme scheme;
  const _GroupTitle(this.title, {required this.scheme});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 10), child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: scheme.onSurfaceVariant)));
}

class _NotificationCard extends StatelessWidget {
  final dynamic item;
  final IconData Function(String) iconForType;
  final VoidCallback onChanged;
  const _NotificationCard({required this.item, required this.iconForType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = DateFormat('HH:mm', 'ar').format(item.createdAt.toLocal());
    final unread = !item.isRead;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unread ? scheme.secondary.withValues(alpha: .45) : scheme.outline),
        boxShadow: [if (unread) BoxShadow(color: scheme.secondary.withValues(alpha: .08), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: unread ? () async { await markNotificationAsRead(item.id); onChanged(); } : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: unread ? scheme.secondaryContainer : scheme.surface, borderRadius: BorderRadius.circular(14)), child: Icon(iconForType(item.type), color: unread ? scheme.onSecondaryContainer : scheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: scheme.onSurface))), if (unread) Container(width: 8, height: 8, decoration: BoxDecoration(color: scheme.secondary, shape: BoxShape.circle))]),
              if (item.body.isNotEmpty) ...[const SizedBox(height: 5), Text(item.body, style: TextStyle(fontSize: 12, height: 1.5, color: scheme.onSurfaceVariant))],
              const SizedBox(height: 7),
              Text(date, style: TextStyle(fontSize: 10, color: scheme.outline)),
            ])),
          ]),
        ),
      ),
    );
  }
}
