import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/message.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class MessageModel with _$MessageModel {
  const MessageModel._();

  const factory MessageModel({
    required String id,
    @JsonKey(name: 'conversation_id') required String conversationId,
    @JsonKey(name: 'sender_id') required String senderId,
    required String content,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Message toEntity() => Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        isRead: isRead,
        createdAt: createdAt,
      );
}
