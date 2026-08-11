import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final conversations = ref.watch(conversationsListProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('المحادثات'),
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: conversations.when(
        loading: () => Center(child: CircularProgressIndicator(color: scheme.primary)),
        error: (error, _) => _StateView(
          icon: Icons.cloud_off_rounded,
          title: 'تعذر تحميل المحادثات',
          message: error.toString().replaceFirst('Exception: ', ''),
          action: TextButton.icon(
            onPressed: () => ref.invalidate(conversationsListProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _StateView(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'لا توجد محادثات حالياً',
              message: 'ستظهر هنا المحادثات بعد بدء الاستشارة.',
            );
          }

          return RefreshIndicator(
            color: scheme.primary,
            onRefresh: () async => ref.invalidate(conversationsListProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final conversation = items[index];
                final id = conversation['id']?.toString();
                if (id == null) return const SizedBox.shrink();

                return Consumer(
                  builder: (context, ref, _) {
                    final name = ref.watch(chatOtherPartyNameProvider(id));
                    final lastMessage = conversation['last_message']?.toString().trim();
                    final displayName = name.maybeWhen(
                      data: (value) => value?.trim().isNotEmpty == true ? value! : 'المحادثة',
                      orElse: () => 'جاري تحميل الاسم...',
                    );

                    return Material(
                      color: scheme.surfaceContainerHighest.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => context.push('/chat/$id'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: scheme.primaryContainer,
                                child: Icon(Icons.person_outline_rounded, color: scheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      lastMessage?.isNotEmpty == true ? lastMessage! : 'لا توجد رسائل بعد',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
                            ],
                          ),
                        ),
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

class _StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
