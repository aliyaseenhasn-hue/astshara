import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatPage({super.key, required this.conversationId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _send() {
    if (_messageController.text.trim().isNotEmpty) {
      ref.read(chatControllerProvider.notifier).send(
            widget.conversationId,
            _messageController.text.trim(),
          );
      _messageController.clear();
      setState(() {}); // لتحديث أيقونة الإرسال
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.conversationId));
    final currentUser = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              child: Icon(Icons.person, size: 20, color: AppColors.primary),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('أحمد العبيدي',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Colors.green),
                    SizedBox(width: 4),
                    Text('متصل الآن',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.outline)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.videocam_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) => ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.p20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.id;
                    return _MessageBubble(
                        message: msg.content, isMe: isMe, time: '10:00 ص');
                  },
                ),
                loading: () => const LoadingWidget(),
                error: (err, stack) => Center(child: Text('خطأ: $err')),
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.surfaceVariant)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file,
                          color: AppColors.outline)),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: TextField(
                      controller: _messageController,
                      onChanged: (v) => setState(() {}),
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: IconButton(
                onPressed: _send,
                icon: Icon(
                  _messageController.text.isEmpty ? Icons.mic : Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;
  const _MessageBubble(
      {required this.message, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? Radius.zero : const Radius.circular(16),
                bottomRight: isMe ? const Radius.circular(16) : Radius.zero,
              ),
              boxShadow: [
                if (!isMe)
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black, fontSize: 14),
            ),
          ),
          const SizedBox(height: 4),
          Text(time,
              style: const TextStyle(fontSize: 10, color: AppColors.outline)),
        ],
      ),
    );
  }
}
