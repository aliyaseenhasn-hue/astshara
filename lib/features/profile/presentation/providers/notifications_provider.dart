import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceId;
  final String? referenceType;

  const AppNotification({required this.id, required this.title, required this.body, required this.type, required this.isRead, required this.createdAt, this.referenceId, this.referenceType});
  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(id: map['id'].toString(), title: (map['title'] ?? 'إشعار جديد').toString(), body: (map['body'] ?? '').toString(), type: (map['type'] ?? 'system').toString(), isRead: map['is_read'] == true, createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(), referenceId: map['reference_id']?.toString(), referenceType: map['reference_type']?.toString());
}

Future<String?> _currentProfileId() async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return null;
  final profile = await SupabaseConfig.client.from('profiles').select('id').eq('auth_id', user.id).maybeSingle();
  return profile?['id']?.toString();
}

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final profileId = await _currentProfileId();
  if (profileId == null) return const [];
  final rows = await SupabaseConfig.client.from('notifications').select('id,title,body,type,is_read,created_at,reference_id,reference_type').eq('user_id', profileId).order('created_at', ascending: false).limit(100);
  return (rows as List).map((row) => AppNotification.fromMap(Map<String, dynamic>.from(row as Map))).toList();
});

/// Emits only newly-created notifications for the signed-in profile.
/// Used by the app shell to surface immediate in-app/local notifications.
final realtimeNotificationsProvider = StreamProvider.autoDispose<AppNotification>((ref) {
  late final StreamController<AppNotification> controller;
  RealtimeChannel? channel;
  String? profileId;

  Future<void> start() async {
    profileId = await _currentProfileId();
    if (profileId == null || controller.isClosed) return;
    channel = SupabaseConfig.client
        .channel('notifications:${profileId!}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: profileId!,
          ),
          callback: (payload) {
            if (controller.isClosed) return;
            controller.add(AppNotification.fromMap(Map<String, dynamic>.from(payload.newRecord)));
          },
        )
        .subscribe();
  }

  controller = StreamController<AppNotification>(
    onListen: start,
    onCancel: () async {
      await channel?.unsubscribe();
      await controller.close();
    },
  );
  ref.onDispose(() async {
    await channel?.unsubscribe();
    if (!controller.isClosed) await controller.close();
  });
  return controller.stream;
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final profileId = await _currentProfileId();
  if (profileId == null) return 0;
  final rows = await SupabaseConfig.client.from('notifications').select('id').eq('user_id', profileId).eq('is_read', false);
  return (rows as List).length;
});

Future<void> markNotificationAsRead(String id) async {
  final profileId = await _currentProfileId();
  if (profileId == null) return;
  await SupabaseConfig.client.from('notifications').update({'is_read': true}).eq('id', id).eq('user_id', profileId);
}

Future<void> markAllNotificationsAsRead() async {
  final profileId = await _currentProfileId();
  if (profileId == null) return;
  await SupabaseConfig.client.from('notifications').update({'is_read': true}).eq('user_id', profileId).eq('is_read', false);
}
