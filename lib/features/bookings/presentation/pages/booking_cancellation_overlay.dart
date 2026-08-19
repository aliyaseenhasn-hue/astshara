import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/entities/booking.dart';
import 'booking_details_page.dart';

class BookingDetailsWithCancellation extends ConsumerStatefulWidget {
  final Booking booking;
  const BookingDetailsWithCancellation({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailsWithCancellation> createState() => _BookingDetailsWithCancellationState();
}

class _BookingDetailsWithCancellationState extends ConsumerState<BookingDetailsWithCancellation> {
  bool _pending = false;
  bool _loading = true;
  Map<String, dynamic>? _credit;

  @override
  void initState() {
    super.initState();
    _loadCancellationState();
  }

  Future<void> _loadCancellationState() async {
    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) return;
      if (user.role == 'lawyer') {
        final rows = await SupabaseConfig.client.rpc('get_my_cancellation_requests');
        final list = rows is List ? rows : const [];
        _pending = list.any((row) {
          final map = Map<String, dynamic>.from(row as Map);
          return map['booking_id']?.toString() == widget.booking.id && map['status'] == 'بانتظار مراجعة الإدارة';
        });
      } else if (user.id == widget.booking.userId) {
        final row = await SupabaseConfig.client.from('client_credits').select('amount,currency,status,created_at').eq('booking_id', widget.booking.id).maybeSingle();
        _credit = row == null ? null : Map<String, dynamic>.from(row);
      }
    } catch (_) {
      // The primary booking page remains usable even if the optional status query fails.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _eligible {
    final status = widget.booking.status;
    if (status == 'ملغي' || status == 'مسترد' || status == 'مكتمل' || status == 'قيد التنفيذ') return false;
    if (widget.booking.scheduledAt.isBefore(DateTime.now())) return false;
    return ['قيد انتظار الدفع', 'قيد معالجة الدفع', 'بانتظار التأكيد', 'قيد مراجعة المحامي', 'مؤكد'].contains(status);
  }

  Future<void> _showRequestDialog() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طلب إلغاء الحجز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('يرجى توضيح سبب إلغاء الحجز. سيتم إرسال الطلب إلى الإدارة للمراجعة.'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'سبب الإلغاء', hintText: 'اكتب سبب الإلغاء هنا'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سبب الإلغاء إلزامي')));
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('إرسال طلب الإلغاء'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    try {
      await SupabaseConfig.client.rpc('request_booking_cancellation', params: {'p_booking_id': widget.booking.id, 'p_reason': reason});
      if (!mounted) return;
      setState(() => _pending = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب إلغاء الحجز إلى الإدارة للمراجعة.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;
    final isLawyer = user?.role == 'lawyer';
    final isClient = user?.id == widget.booking.userId && !isLawyer;
    return Stack(
      children: [
        BookingDetailsPage(booking: widget.booking),
        if (isLawyer && !_loading && !_pending && _eligible)
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SafeArea(
              child: OutlinedButton.icon(
                onPressed: _showRequestDialog,
                icon: const Icon(Icons.event_busy_outlined),
                label: const Text('طلب إلغاء الحجز'),
              ),
            ),
          ),
        if (isLawyer && !_loading && _pending)
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [Icon(Icons.hourglass_top_rounded), SizedBox(width: 10), Expanded(child: Text('طلب إلغاء الحجز بانتظار مراجعة الإدارة.'))]),
              ),
            ),
          ),
        if (isClient && _credit != null && _credit!['status'] == 'مستحق')
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [const Icon(Icons.account_balance_wallet_outlined), const SizedBox(width: 10), Expanded(child: Text('تعويض مستحق لك: ${_credit!['amount']} ${_credit!['currency']}'))]),
              ),
            ),
          ),
      ],
    );
  }
}
