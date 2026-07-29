import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_provider.g.dart';

@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  // للاتصال بـ Supabase الحقيقي، اجعل هذه القيمة false
  const bool useMock = false;
  if (useMock) {
    return MockChatRepository();
  }
  return ChatRepositoryImpl(SupabaseConfig.client);
}

class MockChatRepository implements ChatRepository {
  final List<Message> _messages = [
    Message(
      id: 'm1',
      conversationId: 'b2',
      senderId: 'p2',
      content: 'مرحباً بك، كيف يمكنني مساعدتك اليوم؟',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    return _messages.where((m) => m.conversationId == conversationId).toList();
  }

  @override
  Future<void> sendMessage(
      String conversationId, String senderId, String content) async {
    _messages.add(Message(
      id: DateTime.now().toString(),
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Stream<List<Message>> subscribeToMessages(String conversationId) {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return _messages
          .where((m) => m.conversationId == conversationId)
          .toList();
    }).asBroadcastStream();
  }
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
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    await ref.read(chatRepositoryProvider).sendMessage(
          conversationId,
          user.id,
          content,
        );
  }
}
