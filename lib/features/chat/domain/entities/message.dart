import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    @Default(false) bool isRead,
    DateTime? createdAt,
  }) = _Message;
}
