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
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data
            .map((json) => MessageModel.fromJson(json).toEntity())
            .toList());
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
          .single();

      final String currentProfileId = currentProfileRow['id'];

      final String otherPartyId = (conversation['user_id'] == currentProfileId)
          ? conversation['lawyer_id']
          : conversation['user_id'];

      final otherProfile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', otherPartyId)
          .single();

      return otherProfile['full_name'] as String?;
    } catch (e) {
      return null;
    }
  }
}
