import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/chat_provider.dart';

final conversationsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final authUser = SupabaseConfig.client.auth.currentUser;
  if (authUser == null) return const [];

  final profile = await SupabaseConfig.client
      .from('profiles')
      .select('id')
      .eq('auth_id', authUser.id)
      .maybeSingle();
  final profileId = profile?['id']?.toString();
  if (profileId == null) return const [];

  final rows = await SupabaseConfig.client
      .from('conversations')
      .select('id,user_id,lawyer_id,last_message,last_message_at')
      .or('user_id.eq.$profileId,lawyer_id.eq.$profileId')
      .order('last_message_at', ascending: false);

  return (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
});

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المحادثات'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تعذر تحميل المحادثات\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.outline),
                  SizedBox(height: 12),
                  Text('لا توجد محادثات حالياً'),
                  SizedBox(height: 6),
                  Text('ستظهر هنا المحادثات بعد بدء الاستشارة.'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(conversationsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final conversation = items[index];
                final id = conversation['id']?.toString();
                if (id == null) return const SizedBox.shrink();

                return Consumer(
                  builder: (context, ref, _) {
                    final name = ref.watch(chatOtherPartyNameProvider(id));
                    final lastMessage = conversation['last_message']?.toString().trim();
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.surfaceVariant,
                          child: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                        ),
                        title: Text(
                          name.maybeWhen(
                            data: (value) => value?.trim().isNotEmpty == true ? value! : 'المحادثة',
                            orElse: () => 'جاري تحميل الاسم...',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lastMessage?.isNotEmpty == true ? lastMessage! : 'لا توجد رسائل بعد',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () => context.push('/chat/$id'),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
