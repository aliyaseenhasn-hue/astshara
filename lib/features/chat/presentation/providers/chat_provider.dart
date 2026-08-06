import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_provider.g.dart';

@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepositoryImpl(SupabaseConfig.client);
}

@riverpod
Stream<List<Message>> chatMessages(ChatMessagesRef ref, String conversationId) {
  return ref.watch(chatRepositoryProvider).subscribeToMessages(conversationId);
}

final chatOtherPartyNameProvider =
    FutureProvider.family<String?, String>((ref, conversationId) async {
  final authState = ref.watch(authStateChangesProvider).value;
  if (authState == null) return null;

  return ref
      .read(chatRepositoryProvider)
      .getOtherPartyName(conversationId, authState.id);
});

@riverpod
class ChatController extends _$ChatController {
  @override
  FutureOr<void> build() {}

  Future<void> send(String conversationId, String content) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    final profileRow = await SupabaseConfig.client
        .from('profiles')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (profileRow == null) return;
    final senderProfileId = profileRow['id'] as String;

    await ref.read(chatRepositoryProvider).sendMessage(
          conversationId,
          senderProfileId,
          content,
        );
  }
}
