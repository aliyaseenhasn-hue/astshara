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
      case 'booking':
        return Icons.calendar_month_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'admin':
        return Icons.verified_user_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                await markAllNotificationsAsRead();
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationsCountProvider);
              },
              child: const Text('قراءة الكل'),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_off_rounded, size: 52, color: AppColors.outline),
                const SizedBox(height: 12),
                const Text('تعذر تحميل الإشعارات'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(notificationsProvider),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationsCountProvider);
              },
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.notifications_none_rounded, size: 72, color: AppColors.outline),
                  SizedBox(height: 16),
                  Center(child: Text('لا توجد إشعارات حالياً')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.p16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final date = DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(item.createdAt.toLocal());
                return Card(
                  color: item.isRead
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.secondaryContainer,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: item.isRead
                        ? null
                        : () async {
                            await markNotificationAsRead(item.id);
                            ref.invalidate(notificationsProvider);
                            ref.invalidate(unreadNotificationsCountProvider);
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: item.isRead ? AppColors.primaryLight : AppColors.gold,
                            foregroundColor: AppColors.secondaryDark,
                            child: Icon(_iconForType(item.type)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    if (!item.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.goldDark,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                if (item.body.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(item.body),
                                ],
                                const SizedBox(height: 8),
                                Text(date, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
