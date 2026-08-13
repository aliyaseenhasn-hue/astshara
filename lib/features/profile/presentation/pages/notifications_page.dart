import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  Future<void> _open(BuildContext context, AppNotification item) async {
    final referenceId = item.referenceId;
    final bookingType = item.referenceType == 'booking' || item.referenceType == 'payment' || item.type == 'booking' || item.type == 'payment';

    if (bookingType && referenceId != null && referenceId.isNotEmpty) {
      try {
        Map<String, dynamic>? row;
        row = await SupabaseConfig.client.from('bookings').select().eq('id', referenceId).maybeSingle();

        // Payment notifications may reference a payment row rather than the booking.
        if (row == null && item.referenceType == 'payment') {
          final payment = await SupabaseConfig.client.from('payments').select('booking_id').eq('id', referenceId).maybeSingle();
          final bookingId = payment?['booking_id']?.toString();
          if (bookingId != null && bookingId.isNotEmpty) {
            row = await SupabaseConfig.client.from('bookings').select().eq('id', bookingId).maybeSingle();
          }
        }

        if (row != null && context.mounted) {
          final booking = BookingModel.fromJson(Map<String, dynamic>.from(row)).toEntity();
          context.push('/booking-details', extra: booking);
          return;
        }
      } catch (_) {
        // Fall through to the relevant list if the referenced record cannot be loaded.
      }
    }

    if (!context.mounted) return;
    if (item.type == 'chat' || item.referenceType == 'chat') {
      context.push('/chats');
    } else if (bookingType) {
      context.push('/bookings');
    } else if (item.type == 'profile') {
      context.push('/profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    Future<void> refresh() async {
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('التنبيهات'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                await markAllNotificationsAsRead();
                await refresh();
              },
              child: const Text('قراءة الكل'),
            ),
        ],
      ),
      body: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: scheme.primary)),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_off_rounded, size: 48, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              const Text('تعذر تحميل التنبيهات'),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: refresh, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                children: [
                  const SizedBox(height: 170),
                  const Icon(Icons.notifications_none_rounded, size: 70),
                  const SizedBox(height: 16),
                  Center(child: Text('لا توجد تنبيهات حالياً', style: TextStyle(color: scheme.onSurfaceVariant))),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              itemCount: items.length,
              itemBuilder: (context, index) => _NotificationCard(
                item: items[index],
                onOpen: () => _open(context, items[index]),
                onRefresh: refresh,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final Future<void> Function() onOpen;
  final Future<void> Function() onRefresh;

  const _NotificationCard({required this.item, required this.onOpen, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = !item.isRead;
    final time = DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(item.createdAt.toLocal());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: unread ? scheme.primaryContainer.withValues(alpha: .3) : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: unread ? scheme.primary.withValues(alpha: .3) : scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          if (unread) await markNotificationAsRead(item.id);
          await onRefresh();
          await onOpen();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.notifications_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(item.title, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontWeight: unread ? FontWeight.w800 : FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text(item.body, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 7),
                    Text(time, style: TextStyle(color: scheme.outline, fontSize: 10)),
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
