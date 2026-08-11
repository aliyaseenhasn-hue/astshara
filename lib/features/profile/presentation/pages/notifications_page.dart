import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  IconData _iconForType(String type) => switch (type) {
        'booking' => Icons.calendar_month_rounded,
        'payment' => Icons.payments_rounded,
        'chat' => Icons.chat_bubble_rounded,
        'admin' => Icons.verified_user_rounded,
        _ => Icons.notifications_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final scheme = Theme.of(context).colorScheme;

    Future<void> refresh() async {
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('التنبيهات'),
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                await markAllNotificationsAsRead();
                await refresh();
              },
              child: Text(
                'قراءة الكل',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: scheme.primary),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_off_rounded,
                  size: 52,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'تعذر تحميل التنبيهات',
                  style: TextStyle(color: scheme.onSurface),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: refresh,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 150),
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 76,
                    color: scheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'لا توجد تنبيهات حالياً',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'سنخبرك هنا عند وصول أي تحديث جديد.',
                      style: TextStyle(
                        color: scheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final today = <dynamic>[];
          final previous = <dynamic>[];
          for (final item in items) {
            final date = item.createdAt.toLocal();
            if (date.year == now.year &&
                date.month == now.month &&
                date.day == now.day) {
              today.add(item);
            } else {
              previous.add(item);
            }
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (today.isNotEmpty) ...[
                  _GroupTitle('اليوم', scheme: scheme),
                  ...today.map(
                    (item) => _NotificationCard(
                      item: item,
                      iconForType: _iconForType,
                      onChanged: refresh,
                    ),
                  ),
                ],
                if (previous.isNotEmpty) ...[
                  _GroupTitle('سابقاً', scheme: scheme),
                  ...previous.map(
                    (item) => _NotificationCard(
                      item: item,
                      iconForType: _iconForType,
                      onChanged: refresh,
                    ),
                  ),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Text(
          title,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  final dynamic item;
  final IconData Function(String) iconForType;
  final Future<void> Function() onChanged;

  const _NotificationCard({
    required this.item,
    required this.iconForType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = DateFormat('HH:mm', 'ar').format(item.createdAt.toLocal());
    final unread = !item.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: unread
            ? scheme.primaryContainer.withValues(alpha: .28)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unread
              ? scheme.primary.withValues(alpha: .35)
              : scheme.outlineVariant.withValues(alpha: .7),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: unread
            ? () async {
                await markNotificationAsRead(item.id);
                await onChanged();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: unread
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  iconForType(item.type),
                  color: unread
                      ? scheme.onPrimaryContainer
                      : scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.body,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        date,
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
