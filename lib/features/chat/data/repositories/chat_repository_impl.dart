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
    
    return (response as List).map((json) => MessageModel.fromJson(json).toEntity()).toList();
  }

  @override
  Future<void> sendMessage(String conversationId, String senderId, String content) async {
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
        .map((data) => data.map((json) => MessageModel.fromJson(json).toEntity()).toList());
  }
}
