import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class CustomConsultationRequestsPage extends StatefulWidget {
  const CustomConsultationRequestsPage({super.key});

  @override
  State<CustomConsultationRequestsPage> createState() => _CustomConsultationRequestsPageState();
}

class _CustomConsultationRequestsPageState extends State<CustomConsultationRequestsPage> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _loadRequests();
  }

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    final authUser = SupabaseConfig.client.auth.currentUser;
    if (authUser == null) return [];
    final profile = await SupabaseConfig.client
        .from('profiles')
        .select('id')
        .eq('auth_id', authUser.id)
        .maybeSingle();
    if (profile == null) return [];

    final response = await SupabaseConfig.client
        .from('custom_consultation_requests')
        .select()
        .eq('lawyer_id', profile['id'])
        .order('created_at', ascending: false);
    return (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _changeStatus(String id, String status) async {
    try {
      await SupabaseConfig.client.rpc('change_custom_consultation_request_status', params: {
        'p_request_id': id,
        'p_new_status': status,
      });
      if (!mounted) return;
      setState(() => _requestsFuture = _loadRequests());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تحديث حالة الطلب إلى: $status')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث حالة الطلب')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الاستشارة المخصصة'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('تعذر تحميل الطلبات'));
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('لا توجد طلبات استشارة مخصصة حالياً'));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _requestsFuture = _loadRequests()),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.p20),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _RequestCard(request: requests[index], onChangeStatus: _changeStatus),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final Future<void> Function(String id, String status) onChangeStatus;

  const _RequestCard({required this.request, required this.onChangeStatus});

  @override
  Widget build(BuildContext context) {
    final status = request['status']?.toString() ?? 'جديد';
    final createdAt = DateTime.tryParse(request['created_at']?.toString() ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(request['subject']?.toString() ?? 'طلب استشارة', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary))),
            _StatusChip(status),
          ]),
          const SizedBox(height: 10),
          Text(request['description']?.toString() ?? '', style: const TextStyle(height: 1.5)),
          const SizedBox(height: 10),
          Text('طريقة التواصل: ${request['consultation_type'] ?? 'غير محددة'}', style: const TextStyle(color: AppColors.textSecondary)),
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            Text('تاريخ الطلب: ${createdAt.day}/${createdAt.month}/${createdAt.year}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (status == 'جديد') ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => onChangeStatus(request['id'].toString(), 'مرفوض'), child: const Text('رفض'))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () => onChangeStatus(request['id'].toString(), 'مقبول'), child: const Text('قبول الطلب'))),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
