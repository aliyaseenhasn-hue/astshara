import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient _supabase;

  ChatRepositoryImpl(this._supabase);

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => MessageModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<void> sendMessage(
      String conversationId, String senderId, String content) async {
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
    });
  }

  @override
  Stream<List<Message>> subscribeToMessages(String conversationId) {
    late final StreamController<List<Message>> controller;
    RealtimeChannel? channel;

    Future<void> fetchAndEmit() async {
      try {
        final data = await _supabase
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: true);
        final messages = (data as List)
            .map((json) => MessageModel.fromJson(json).toEntity())
            .toList();
        if (!controller.isClosed) controller.add(messages);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<Message>>(
      onListen: () async {
        await fetchAndEmit();
        channel = _supabase
            .channel('messages:$conversationId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value: conversationId,
              ),
              callback: (_) => fetchAndEmit(),
            )
            .subscribe();
      },
      onCancel: () async {
        await channel?.unsubscribe();
        await controller.close();
      },
    );

    return controller.stream;
  }

  @override
  Future<String?> getOtherPartyName(
      String conversationId, String currentAuthId) async {
    try {
      final conversation = await _supabase
          .from('conversations')
          .select('user_id, lawyer_id')
          .eq('id', conversationId)
          .single();

      final currentProfileRow = await _supabase
          .from('profiles')
          .select('id')
          .eq('auth_id', currentAuthId)
          .maybeSingle();

      if (currentProfileRow == null) return null;

      final String currentProfileId = currentProfileRow['id'] as String;
      final String? userId = conversation['user_id'] as String?;
      final String? lawyerId = conversation['lawyer_id'] as String?;

      // تحديد هوية الطرف الآخر ودوره
      String? otherPartyId;
      bool otherPartyIsLawyer = false;

      if (currentProfileId == userId) {
        // المستخدم الحالي هو الموكّل → الطرف الآخر محامٍ
        otherPartyId = lawyerId;
        otherPartyIsLawyer = true;
      } else if (currentProfileId == lawyerId) {
        // المستخدم الحالي هو المحامي → الطرف الآخر موكّل
        otherPartyId = userId;
        otherPartyIsLawyer = false;
      } else {
        return null;
      }

      if (otherPartyId == null) return null;

      String? name;

      if (otherPartyIsLawyer) {
        // البحث في جدول lawyers أولاً
        final lawyerRow = await _supabase
            .from('lawyers')
            .select('full_name')
            .eq('profile_id', otherPartyId)
            .maybeSingle();

        name = lawyerRow?['full_name'] as String?;

        // إذا لم يوجد → البحث في profiles
        if (name == null) {
          final profileRow = await _supabase
              .from('profiles')
              .select('full_name')
              .eq('id', otherPartyId)
              .maybeSingle();
          name = profileRow?['full_name'] as String?;
        }

        if (name == null) return null;
        return 'المحامي / $name';
      } else {
        // البحث في profiles
        final profileRow = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', otherPartyId)
            .maybeSingle();

        name = profileRow?['full_name'] as String?;
        if (name == null) return null;
        return 'موكّل / $name';
      }
    } catch (e) {
      return null;
    }
  }
}
