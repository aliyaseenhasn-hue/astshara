import 'package:riverpod_annotation/riverpod_annotation.dart';
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

@riverpod
class ChatController extends _$ChatController {
  @override
  FutureOr<void> build() {}

  Future<void> send(String conversationId, String content) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return;

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      throw StateError('يجب تسجيل الدخول لإرسال رسالة');
    }

    if (conversationId.trim().isEmpty) {
      throw ArgumentError('معرّف المحادثة غير صالح');
    }

    // AppUser.id is the profiles.id from DB.
    final profileId = user.id;

    await ref.read(chatRepositoryProvider).sendMessage(
          conversationId,
          profileId,
          trimmedContent,
        );
  }
}
