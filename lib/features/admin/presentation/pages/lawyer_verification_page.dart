import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/lawyer_verification_provider.dart';

class LawyerVerificationPage extends ConsumerWidget {
  const LawyerVerificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingLawyersAsync = ref.watch(lawyerVerificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات توثيق المحامين'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: pendingLawyersAsync.when(
        data: (lawyers) => lawyers.isEmpty
            ? const Center(child: Text('لا توجد طلبات معلقة حالياً'))
            : ListView.builder(
                padding: const EdgeInsets.all(AppSizes.p20),
                itemCount: lawyers.length,
                itemBuilder: (context, index) {
                  final lawyer = lawyers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.surfaceVariant,
                                child: Icon(Icons.person,
                                    color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lawyer.fullName ?? 'محامي جديد',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    Text('رقم الإجازة: ${lawyer.licenseNumber}',
                                        style: const TextStyle(
                                            color: AppColors.outline,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text('الخبرة: ${lawyer.yearsExperience} سنوات',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('السعر: ${lawyer.consultationPrice} د.ع',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('النبذة: ${lawyer.bio}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => ref
                                      .read(lawyerVerificationProvider.notifier)
                                      .approveLawyer(lawyer.profileId),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white),
                                  child: const Text('موافقة وتوثيق'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => ref
                                      .read(lawyerVerificationProvider.notifier)
                                      .rejectLawyer(lawyer.profileId),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(
                                          color: AppColors.error)),
                                  child: const Text('رفض الطلب'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
    );
  }
}
