import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
part 'chat_provider.g.dart';

@riverpod ChatRepository chatRepository(ChatRepositoryRef ref)=>ChatRepositoryImpl(SupabaseConfig.client);
@riverpod Stream<List<Message>> chatMessages(ChatMessagesRef ref,String conversationId)=>ref.watch(chatRepositoryProvider).subscribeToMessages(conversationId);
final chatOtherPartyNameProvider=FutureProvider.family<String?,String>((ref,conversationId) async {final authState=ref.watch(authStateChangesProvider).value;if(authState==null)return null;return ref.read(chatRepositoryProvider).getOtherPartyName(conversationId,authState.id);});

@riverpod
class ChatController extends _$ChatController {
  @override FutureOr<void> build() {}
  Future<String?> _profileId() async {final user=ref.read(authStateChangesProvider).value;if(user==null)return null;final row=await SupabaseConfig.client.from('profiles').select('id').eq('auth_id',user.id).maybeSingle();return row?['id'] as String?;}
  Future<void> markRead(String conversationId) async {final id=await _profileId();if(id==null)return;await ref.read(chatRepositoryProvider).markConversationRead(conversationId,id);}
  Future<void> send(String conversationId,String content) async {final id=await _profileId();if(id==null)return;await ref.read(chatRepositoryProvider).sendMessage(conversationId,id,content);}
}
