import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/app_time_format.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../payments/presentation/providers/payments_provider.dart';
import '../../../reviews/presentation/widgets/review_dialog.dart';
import '../../domain/entities/booking.dart';
import '../providers/bookings_provider.dart';

class BookingDetailsPage extends ConsumerWidget {
  final Booking booking;
  const BookingDetailsPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(bookingPaymentProvider(booking.id));
    final detailsAsync = ref.watch(bookingDetailsProvider(booking.id));
    final owner = ref.watch(authStateChangesProvider).value;
    final isLawyer = owner?.role == 'lawyer';
    final isOwner = !isLawyer && owner?.id == booking.userId;
    final contactAsync = ['مؤكد', 'قيد التنفيذ', 'مكتمل'].contains(booking.status)
        ? ref.watch(bookingParticipantContactProvider(booking.id))
        : const AsyncValue.data(null);
    final canReview = isLawyer && !booking.lawyerApproved &&
        ['قيد انتظار الدفع', 'قيد معالجة الدفع', 'قيد مراجعة المحامي'].contains(booking.status);
    final canReportNoShow = _canReportNoShow(isLawyer: isLawyer);

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الاستشارة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _statusHeader(context),
          const SizedBox(height: 20),
          if (isLawyer) ...[
            _section(context, 'بيانات العميل', Icons.person_outline, detailsAsync.when(
              data: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row(context, 'اسم العميل', d?['client_name']?.toString() ?? booking.userName ?? 'غير متوفر'),
                _row(context, 'نوع الحساب', 'طالب خدمة'),
              ]),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => _row(context, 'اسم العميل', booking.userName ?? 'غير متوفر'),
            )),
            const SizedBox(height: 16),
          ],
          _section(context, 'بيانات الحجز', Icons.calendar_month_outlined, detailsAsync.when(
            data: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _row(context, 'الباقة', d?['package_name'] ?? 'استشارة مختلفة'),
              _row(context, 'نوع الاستشارة', d?['consultation_type'] ?? 'غير محددة'),
              _row(context, 'طريقة التنفيذ', _consultationMethod(d?['consultation_type']?.toString())),
              _row(context, 'التاريخ', DateFormat('yyyy-MM-dd').format(booking.scheduledAt)),
              _row(context, 'الوقت', AppTimeFormat.time12(booking.scheduledAt)),
              _row(context, 'المدة', '${d?['package_duration_minutes'] ?? 30} دقيقة'),
              _row(context, 'الرسوم', '${booking.price} د.ع'),
            ]),
            loading: () => const CircularProgressIndicator(), error: (_, __) => const Text('تعذر تحميل تفاصيل الحجز'),
          )),
          const SizedBox(height: 16),
          _section(context, 'وصف الموضوع', Icons.description_outlined, detailsAsync.when(
            data: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d?['description'] ?? 'لا يوجد وصف متاح.'),
              if (d?['document_url'] != null)
                OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse(d!['document_url'] as String)), icon: const Icon(Icons.file_present), label: const Text('فتح المستند المرفق')),
            ]),
            loading: () => const Text('جاري التحميل...'), error: (_, __) => const Text('تعذر تحميل الوصف'),
          )),
          const SizedBox(height: 16),
          _section(context, 'حالة الدفع', Icons.receipt_long_outlined, paymentAsync.when(
            data: (p) => p == null
                ? const Text('لم يتم إرسال الدفع بعد.')
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _row(context, 'الوسيلة', _paymentMethod(p.paymentMethod)),
                    _row(context, 'حالة الدفع', p.status),
                    if (p.transactionNumber != null) _row(context, 'رقم العملية', p.transactionNumber!),
                  ]),
            loading: () => const CircularProgressIndicator(), error: (_, __) => const Text('تعذر تحميل بيانات الدفع'),
          )),
          if (isOwner && booking.status == 'قيد مراجعة المحامي') ...[
            const SizedBox(height: 16),
            _section(context, 'حالة الطلب', Icons.hourglass_top_outlined, const Text('تم استلام الدفع بنجاح، والحجز الآن بانتظار موافقة المحامي. لن تظهر معلومات التواصل ولن تبدأ الاستشارة حتى يوافق المحامي.', style: TextStyle(height: 1.6))),
          ],
          if (isOwner && booking.status == 'بانتظار الاسترداد') ...[
            const SizedBox(height: 16),
            _section(context, 'حالة الاسترداد', Icons.replay_outlined, const Text('رفض المحامي الطلب بعد إتمام الدفع. تم تسجيل الطلب بانتظار استرداد المبلغ، ولن يتم بدء الاستشارة.', style: TextStyle(height: 1.6))),
          ],
          if (['مؤكد', 'قيد التنفيذ', 'مكتمل'].contains(booking.status)) ...[
            const SizedBox(height: 16),
            _section(context, 'معلومات التواصل', Icons.contact_phone_outlined, contactAsync.when(
              data: (c) => c == null ? const Text('لا توجد معلومات تواصل متاحة.') : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (isLawyer) ...[
                  Text('العميل: ${c['client_name'] ?? 'طالب خدمة'}'),
                  if (c['client_phone'] != null) _row(context, 'رقم الهاتف', c['client_phone'].toString()),
                  if (c['client_whatsapp'] != null && booking.status == 'قيد التنفيذ')
                    ElevatedButton.icon(onPressed: () => _openWhatsApp(context, c['client_whatsapp'].toString()), icon: const Icon(Icons.chat), label: const Text('بدء الاستشارة عبر واتساب'), style: _button(context, color: const Color(0xFF25D366))),
                ] else ...[
                  Text('المحامي: ${c['lawyer_name'] ?? 'محامي'}'),
                  if (c['lawyer_phone'] != null) _row(context, 'رقم الهاتف', c['lawyer_phone'].toString()),
                  if (c['lawyer_whatsapp'] != null && booking.status == 'قيد التنفيذ')
                    ElevatedButton.icon(onPressed: () => _openWhatsApp(context, c['lawyer_whatsapp'].toString()), icon: const Icon(Icons.chat), label: const Text('بدء الاستشارة عبر واتساب'), style: _button(context, color: const Color(0xFF25D366))),
                ],
              ]),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text(e.toString().replaceFirst('Exception: ', '')),
            )),
          ],
          if (isOwner && booking.status == 'مؤكد') ...[const SizedBox(height: 12), _sessionInfo(context, 'الحجز مؤكد. ستبدأ الاستشارة في الموعد المحدد، ويمكنك فتح واتساب بعد بدء الجلسة.', Icons.schedule)],
          if (isLawyer && booking.status == 'قيد التنفيذ') ...[const SizedBox(height: 12), _sessionInfo(context, 'الاستشارة قيد التنفيذ. بعد التواصل مع العميل أنهِ الجلسة من زر إنهاء الاستشارة.', Icons.play_circle_outline)],
          if (booking.status == 'بانتظار مراجعة عدم الحضور') ...[const SizedBox(height: 12), _sessionInfo(context, booking.consultationType == null ? 'تم تسجيل عدم الحضور.' : 'تم تسجيل عدم الحضور لهذه الاستشارة. الطلب الآن بانتظار مراجعة الإدارة قبل اتخاذ قرار بشأن الاسترداد.', Icons.report_problem_outlined)],
          const SizedBox(height: 24),
          if (canReview) ...[
            Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF81C7F5).withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Text(booking.status == 'قيد مراجعة المحامي' ? 'تم الدفع لهذا الحجز وأصبح الآن بانتظار قرارك. إذا رفضت الطلب فسيُنقل إلى حالة بانتظار الاسترداد ولن تبدأ الاستشارة.' : 'هذا الطلب بانتظار مراجعتك. يمكنك الموافقة أو رفض الطلب قبل بدء الاستشارة.', textAlign: TextAlign.center)),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => _reviewBooking(context, ref, true), icon: const Icon(Icons.check_circle_outline), label: const Text('الموافقة على الطلب'), style: _button(context, color: const Color(0xFF81C7F5)))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: () => _reviewBooking(context, ref, false), icon: const Icon(Icons.cancel_outlined), label: const Text('رفض الطلب'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 16)))),
            ]),
          ],
          if (isOwner && booking.status == 'قيد انتظار الدفع') ElevatedButton.icon(onPressed: () => context.push('/upload-payment', extra: booking), icon: const Icon(Icons.payment), label: const Text('إكمال الدفع'), style: _button(context)),
          if (isLawyer && booking.status == 'مؤكد') _startButton(context, ref, detailsAsync),
          if (isLawyer && booking.status == 'قيد التنفيذ') ElevatedButton.icon(onPressed: () => _updateStatus(context, ref, 'مكتمل'), icon: const Icon(Icons.check_circle_outline), label: const Text('إنهاء الاستشارة'), style: _button(context, color: AppColors.success)),
          if (canReportNoShow) OutlinedButton.icon(onPressed: () => _reportNoShow(context, ref, isLawyer), icon: const Icon(Icons.report_problem_outlined), label: Text(isLawyer ? 'الإبلاغ عن عدم حضور العميل' : 'الإبلاغ عن عدم حضور المحامي'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 14))),
          if (isOwner && booking.status == 'مكتمل') ElevatedButton.icon(onPressed: () => showDialog(context: context, builder: (_) => ReviewDialog(bookingId: booking.id, lawyerId: booking.lawyerId)), icon: const Icon(Icons.star), label: const Text('تقييم الاستشارة'), style: _button(context)),
        ]),
      ),
    );
  }

  bool _canReportNoShow({required bool isLawyer}) {
    final now = DateTime.now();
    if (isLawyer) {
      if (booking.status == 'مؤكد') return !now.isBefore(booking.scheduledAt.add(const Duration(minutes: 10)));
      if (booking.status == 'قيد التنفيذ' && booking.startedAt != null) return !now.isBefore(booking.startedAt!.add(const Duration(minutes: 10)));
      return false;
    }
    return booking.status == 'مؤكد' && booking.startedAt == null && !now.isBefore(booking.scheduledAt.add(const Duration(minutes: 10)));
  }

  Widget _startButton(BuildContext context, WidgetRef ref, AsyncValue<Map<String, dynamic>?> detailsAsync) {
    final details = detailsAsync.valueOrNull;
    final duration = int.tryParse('${details?['package_duration_minutes'] ?? 30}') ?? 30;
    final now = DateTime.now();
    final opensAt = booking.scheduledAt.subtract(const Duration(minutes: 5));
    final closesAt = booking.scheduledAt.add(Duration(minutes: duration));
    final canStart = !now.isBefore(opensAt) && !now.isAfter(closesAt);
    if (now.isAfter(closesAt)) return Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: const Text('انتهى وقت بدء الاستشارة لهذا الموعد. يمكنك الإبلاغ عن عدم حضور العميل إذا لم تبدأ الجلسة.', textAlign: TextAlign.center));
    if (!canStart) {
      final minutes = opensAt.difference(now).inMinutes + 1;
      return Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Text('يمكن بدء الاستشارة قبل الموعد بـ 5 دقائق. المتاح بعد حوالي $minutes دقيقة.', textAlign: TextAlign.center));
    }
    return ElevatedButton.icon(onPressed: () => _updateStatus(context, ref, 'قيد التنفيذ'), icon: const Icon(Icons.play_arrow), label: const Text('بدء الاستشارة الآن'), style: _button(context, color: const Color(0xFF81C7F5)));
  }

  Future<void> _openWhatsApp(BuildContext context, String value) async {
    var phone = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.startsWith('00')) phone = '+${phone.substring(2)}';
    if (phone.startsWith('07')) phone = '+964${phone.substring(1)}';
    final uri = Uri.parse('https://wa.me/${phone.replaceAll('+', '')}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب')));
  }

  String _consultationMethod(String? type) {
    switch (type) {
      case 'نصية': return 'محادثة نصية عبر واتساب';
      case 'صوتية': return 'تواصل صوتي عبر واتساب';
      case 'فيديو': return 'مكالمة فيديو عبر واتساب';
      default: return 'يحددها النظام حسب نوع الاستشارة';
    }
  }

  Widget _sessionInfo(BuildContext context, String text, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(height: 1.5, color: scheme.onSurface)))]));
  }

  Widget _statusHeader(BuildContext context) {
    final color = switch (booking.status) {
      'قيد انتظار الدفع' => Colors.orange,
      'قيد معالجة الدفع' => Colors.blue,
      'قيد مراجعة المحامي' => Colors.deepPurple,
      'بانتظار الاسترداد' => Colors.orange,
      'بانتظار مراجعة عدم الحضور' => Colors.deepOrange,
      'مؤكد' => AppColors.success,
      'قيد التنفيذ' => AppColors.primary,
      'مكتمل' => AppColors.success,
      'ملغي' => AppColors.error,
      'مسترد' => Colors.grey,
      _ => Colors.grey,
    };
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(booking.status, style: TextStyle(color: color, fontWeight: FontWeight.bold))));
  }

  Widget _section(BuildContext context, String title, IconData icon, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface))]), const Divider(height: 24), child]));
  }

  Widget _row(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Text('$label: ', style: TextStyle(color: scheme.onSurfaceVariant)), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]));
  }

  ButtonStyle _button(BuildContext context, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    final background = color ?? AppColors.primary;
    final foreground = color == null ? scheme.onPrimary : Colors.white;
    return ElevatedButton.styleFrom(backgroundColor: background, foregroundColor: foreground, padding: const EdgeInsets.symmetric(vertical: 16));
  }

  String _paymentMethod(String value) => switch (value) { 'ZainCash' => 'زين كاش', 'Qi Card' => 'كي كارد', 'MasterCard' => 'ماستركارد', _ => value };

  Future<void> _reviewBooking(BuildContext context, WidgetRef ref, bool approved) async {
    try {
      await ref.read(bookingsRepositoryProvider).reviewBooking(booking.id, approved);
      ref.invalidate(lawyerBookingsProvider);
      ref.invalidate(userBookingsProvider);
      ref.invalidate(bookingPaymentProvider(booking.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approved ? 'تمت الموافقة على طلب الحجز' : 'تم رفض الطلب وتحويله إلى بانتظار الاسترداد إذا كان مدفوعاً')));
      Navigator.pop(context);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
    }
  }

  Future<void> _reportNoShow(BuildContext context, WidgetRef ref, bool isLawyer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الإبلاغ'),
        content: Text(isLawyer ? 'سيتم تسجيل أن العميل لم يحضر، وسيبقى الحجز بانتظار مراجعة الإدارة. هل تريد المتابعة؟' : 'سيتم تسجيل أن المحامي لم يحضر، وسيبقى الحجز بانتظار مراجعة الإدارة. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(bookingsRepositoryProvider).reportNoShow(booking.id);
      ref.invalidate(lawyerBookingsProvider);
      ref.invalidate(userBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل البلاغ وإحالته للمراجعة')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
    }
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(bookingsRepositoryProvider).updateBookingStatus(booking.id, status);
      ref.invalidate(lawyerBookingsProvider);
      ref.invalidate(userBookingsProvider);
      ref.invalidate(bookingDetailsProvider(booking.id));
      ref.invalidate(bookingParticipantContactProvider(booking.id));

      if (!context.mounted) return;

      if (status == 'قيد التنفيذ') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بدأت الاستشارة بنجاح. سيتم فتح واتساب للتواصل مع العميل.')));
        try {
          final response = await SupabaseConfig.client.rpc(
            'get_booking_participant_contact_info',
            params: {'p_booking_id': booking.id},
          );
          if (!context.mounted) return;
          if (response is List && response.isNotEmpty) {
            final contact = Map<String, dynamic>.from(response.first as Map);
            final whatsapp = contact['client_whatsapp']?.toString().trim();
            if (whatsapp != null && whatsapp.isNotEmpty) {
              await _openWhatsApp(context, whatsapp);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بدأت الاستشارة، لكن رقم واتساب العميل غير متوفر.')));
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بدأت الاستشارة، لكن تعذر تحميل بيانات تواصل العميل.')));
          }
        } catch (_) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بدأت الاستشارة، لكن تعذر فتح بيانات تواصل العميل.')));
        }
        if (context.mounted) Navigator.pop(context);
        return;
      }

      if (status == 'مكتمل') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنهاء الاستشارة بنجاح.')));
          Navigator.pop(context);
        }
        return;
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error));
    }
  }
}
