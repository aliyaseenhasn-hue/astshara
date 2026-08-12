import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final paymentAsync = ref.watch(bookingPaymentProvider(booking.id));
    final detailsAsync = ref.watch(bookingDetailsProvider(booking.id));
    final owner = ref.watch(authStateChangesProvider).value;
    final isLawyer = owner?.role == 'lawyer';
    final isOwner = !isLawyer && owner?.id == booking.userId;
    final contactAsync = ['مؤكد', 'قيد التنفيذ', 'مكتمل'].contains(booking.status)
        ? ref.watch(bookingParticipantContactProvider(booking.id))
        : const AsyncValue.data(null);
    final canReview = isLawyer && !booking.lawyerApproved && ['قيد انتظار الدفع', 'قيد معالجة الدفع', 'قيد مراجعة المحامي'].contains(booking.status);
    final canReportNoShow = _canReportNoShow(isLawyer);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('تفاصيل الاستشارة'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _hero(context),
          const SizedBox(height: 14),
          if (isLawyer) _section(context, 'بيانات العميل', Icons.person_outline_rounded, detailsAsync.when(data: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_row(context, 'اسم العميل', d?['client_name']?.toString() ?? booking.userName ?? 'غير متوفر'), _row(context, 'نوع الحساب', 'طالب خدمة')]), loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => _row(context, 'اسم العميل', booking.userName ?? 'غير متوفر'))),
          if (isLawyer) const SizedBox(height: 12),
          _section(context, 'بيانات الحجز', Icons.calendar_month_outlined, detailsAsync.when(data: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (isOwner) _row(context, 'اسم المحامي', d?['lawyer_name']?.toString() ?? 'غير متوفر'), _row(context, 'الباقة', d?['package_name']?.toString() ?? 'استشارة مختلفة'), _row(context, 'نوع الاستشارة', d?['consultation_type']?.toString() ?? 'غير محددة'), _row(context, 'طريقة التنفيذ', _consultationMethod(d?['consultation_type']?.toString(), d?['consultation_mode']?.toString())), _row(context, 'التاريخ', DateFormat('yyyy/MM/dd').format(booking.scheduledAt)), _row(context, 'الوقت', AppTimeFormat.time12(booking.scheduledAt)), _row(context, 'المدة', '${d?['package_duration_minutes'] ?? 30} دقيقة'), _row(context, 'الرسوم', '${booking.price} د.ع')]), loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => const Text('تعذر تحميل تفاصيل الحجز'))),
          const SizedBox(height: 12),
          _section(context, 'وصف الموضوع', Icons.description_outlined, detailsAsync.when(data: (d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d?['description']?.toString() ?? 'لا يوجد وصف متاح.', style: TextStyle(color: scheme.onSurface, height: 1.6)), if (d?['document_url'] != null) Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse(d!['document_url'] as String)), icon: const Icon(Icons.file_present_outlined), label: const Text('فتح المستند المرفق')))]), loading: () => const Text('جاري التحميل...'), error: (_, __) => const Text('تعذر تحميل الوصف'))),
          const SizedBox(height: 12),
          _section(context, 'حالة الدفع', Icons.receipt_long_outlined, paymentAsync.when(data: (p) => p == null ? const Text('لم يتم إرسال الدفع بعد.') : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_row(context, 'الوسيلة', _paymentMethod(p.paymentMethod)), _row(context, 'حالة الدفع', _paymentStatus(p.status)), if (p.transactionNumber != null) _row(context, 'رقم العملية', p.transactionNumber!)]), loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => const Text('تعذر تحميل بيانات الدفع'))),
          if (isOwner && booking.status == 'قيد مراجعة المحامي') ...[const SizedBox(height: 12), _infoCard(context, 'تم استلام الدفع بنجاح. الحجز بانتظار موافقة المحامي، ولن تظهر معلومات التواصل قبل تأكيد الحجز.', Icons.hourglass_top_rounded)],
          if (isOwner && booking.status == 'بانتظار الاسترداد') ...[const SizedBox(height: 12), _infoCard(context, 'رفض المحامي الطلب بعد إتمام الدفع. الحجز بانتظار الاسترداد ولن تبدأ الاستشارة.', Icons.replay_outlined)],
          if (['مؤكد', 'قيد التنفيذ', 'مكتمل'].contains(booking.status)) ...[const SizedBox(height: 12), _section(context, 'معلومات التواصل', Icons.contact_phone_outlined, contactAsync.when(data: (c) => c == null ? const Text('لا توجد معلومات تواصل متاحة.') : _contactContent(context, c, isLawyer), loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Text(e.toString().replaceFirst('Exception: ', ''))))],
          if (isOwner && booking.status == 'مؤكد') ...[const SizedBox(height: 12), _infoCard(context, 'الحجز مؤكد. ستبدأ الاستشارة في الموعد المحدد، وسيظهر زر التواصل عند بدء الجلسة.', Icons.schedule_rounded)],
          if (isLawyer && booking.status == 'قيد التنفيذ') ...[const SizedBox(height: 12), _infoCard(context, 'الاستشارة قيد التنفيذ. بعد التواصل مع العميل أنهِ الجلسة من زر إنهاء الاستشارة.', Icons.play_circle_outline_rounded)],
          if (booking.status == 'بانتظار مراجعة عدم الحضور') ...[const SizedBox(height: 12), _infoCard(context, 'تم تسجيل عدم الحضور. الطلب بانتظار مراجعة الإدارة.', Icons.report_problem_outlined)],
          const SizedBox(height: 20),
          if (canReview) ...[_infoCard(context, booking.status == 'قيد مراجعة المحامي' ? 'تم الدفع لهذا الحجز وأصبح بانتظار قرارك.' : 'هذا الطلب بانتظار مراجعتك. يمكنك الموافقة أو رفض الطلب قبل بدء الاستشارة.', Icons.rule_rounded), const SizedBox(height: 10), Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () => _reviewBooking(context, ref, true), icon: const Icon(Icons.check_circle_outline), label: const Text('الموافقة'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: () => _reviewBooking(context, ref, false), icon: const Icon(Icons.cancel_outlined), label: const Text('رفض الطلب')))])],
          if (isOwner && booking.status == 'قيد انتظار الدفع') ElevatedButton.icon(onPressed: () => context.push('/upload-payment', extra: booking), icon: const Icon(Icons.payment_rounded), label: const Text('إكمال الدفع')),
          if (isLawyer && booking.status == 'مؤكد') _startButton(context, ref, detailsAsync),
          if (isLawyer && booking.status == 'قيد التنفيذ') ElevatedButton.icon(onPressed: () => _updateStatus(context, ref, 'مكتمل'), icon: const Icon(Icons.check_circle_outline), label: const Text('إنهاء الاستشارة')),
          if (canReportNoShow) OutlinedButton.icon(onPressed: () => _reportNoShow(context, ref, isLawyer), icon: const Icon(Icons.report_problem_outlined), label: Text(isLawyer ? 'الإبلاغ عن عدم حضور العميل' : 'الإبلاغ عن عدم حضور المحامي')),
          if (isOwner && booking.status == 'مكتمل') ElevatedButton.icon(onPressed: () => showDialog(context: context, builder: (_) => ReviewDialog(bookingId: booking.id, lawyerId: booking.lawyerId)), icon: const Icon(Icons.star_outline_rounded), label: const Text('تقييم الاستشارة')),
        ]),
      ),
    );
  }

  Widget _hero(BuildContext context) { final scheme = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [scheme.primaryContainer, scheme.surfaceContainerHighest]), borderRadius: BorderRadius.circular(22), border: Border.all(color: scheme.outline)), child: Row(textDirection: TextDirection.rtl, children: [Container(width: 52, height: 52, decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16)), child: Icon(Icons.gavel_rounded, color: scheme.primary, size: 28)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('استشارة قانونية', style: TextStyle(color: scheme.onSurface, fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(30)), child: Text(booking.status, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 12))) ]))]); }
  Widget _contactContent(BuildContext context, Map<String, dynamic> c, bool isLawyer) { final scheme = Theme.of(context).colorScheme; final name = isLawyer ? c['client_name'] ?? 'طالب خدمة' : c['lawyer_name'] ?? 'المحامي'; final phone = isLawyer ? c['client_phone'] : c['lawyer_phone']; final whatsapp = isLawyer ? c['client_whatsapp'] : c['lawyer_whatsapp']; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)), const SizedBox(height: 10), if (phone != null) _row(context, 'رقم الهاتف', phone.toString()), if (whatsapp != null && booking.status == 'قيد التنفيذ') SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _openWhatsApp(context, whatsapp.toString()), icon: const Icon(Icons.chat_rounded), label: const Text('بدء الاستشارة عبر واتساب'))]); }
  bool _canReportNoShow(bool isLawyer) { final now = DateTime.now(); if (isLawyer) { if (booking.status == 'مؤكد') return !now.isBefore(booking.scheduledAt.add(const Duration(minutes: 10))); if (booking.status == 'قيد التنفيذ' && booking.startedAt != null) return !now.isBefore(booking.startedAt!.add(const Duration(minutes: 10))); return false; } return booking.status == 'مؤكد' && booking.startedAt == null && !now.isBefore(booking.scheduledAt.add(const Duration(minutes: 10))); }
  Widget _startButton(BuildContext context, WidgetRef ref, AsyncValue<Map<String, dynamic>?> detailsAsync) { final now = DateTime.now(); final duration = int.tryParse('${detailsAsync.valueOrNull?['package_duration_minutes'] ?? 30}') ?? 30; final opensAt = booking.scheduledAt.subtract(const Duration(minutes: 5)); final closesAt = booking.scheduledAt.add(Duration(minutes: duration)); if (now.isAfter(closesAt)) return _infoCard(context, 'انتهى وقت بدء الاستشارة لهذا الموعد.', Icons.timer_off_outlined); if (now.isBefore(opensAt)) return _infoCard(context, 'يمكن بدء الاستشارة قبل الموعد بـ 5 دقائق.', Icons.schedule_rounded); return ElevatedButton.icon(onPressed: () => _updateStatus(context, ref, 'قيد التنفيذ'), icon: const Icon(Icons.play_arrow_rounded), label: const Text('بدء الاستشارة الآن')); }
  Future<void> _openWhatsApp(BuildContext context, String value) async { var phone = value.replaceAll(RegExp(r'[^0-9+]'), ''); if (phone.startsWith('00')) phone = '+${phone.substring(2)}'; if (phone.startsWith('07')) phone = '+964${phone.substring(1)}'; final opened = await launchUrl(Uri.parse('https://wa.me/${phone.replaceAll('+', '')}'), mode: LaunchMode.externalApplication); if (!opened && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب'))); }
  String _consultationMethod(String? type, String? mode) { if (mode == 'في المكتب') return 'حضور في مكتب المحامي'; return switch (type) {'نصية' => 'محادثة نصية عبر واتساب', 'صوتية' => 'تواصل صوتي عبر واتساب', 'فيديو' => 'مكالمة فيديو عبر واتساب', _ => 'عن بعد'}; }
  String _paymentStatus(String value) => switch (value) {'pending' || 'قيد الانتظار' => 'قيد الانتظار', 'submitted' || 'قيد المعالجة' => 'قيد المعالجة', 'processing' => 'قيد المراجعة', 'approved' || 'مقبول' || 'paid' => 'تمت الموافقة', 'rejected' || 'مرفوض' => 'مرفوض', 'refunded' || 'مسترد' => 'مسترد', 'cancelled' || 'ملغي' => 'ملغي', _ => value};
  String _paymentMethod(String value) => value.trim().isEmpty ? 'غير محددة' : value;
  Widget _section(BuildContext context, String title, IconData icon, Widget child) { final scheme = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outline), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .025), blurRadius: 14, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(textDirection: TextDirection.rtl, children: [Icon(icon, color: scheme.primary, size: 21), const SizedBox(width: 8), Expanded(child: Text(title, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)))]), const SizedBox(height: 13), child]); }
  Widget _row(BuildContext context, String label, String value) { final scheme = Theme.of(context).colorScheme; return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(textDirection: TextDirection.rtl, children: [Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600))), const SizedBox(width: 14), Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))])); }
  Widget _infoCard(BuildContext context, String text, IconData icon) { final scheme = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: .55), borderRadius: BorderRadius.circular(15)), child: Row(textDirection: TextDirection.rtl, crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: scheme.primary), const SizedBox(width: 10), Expanded(child: Text(text, textAlign: TextAlign.right, style: TextStyle(color: scheme.onSurface, height: 1.55)))])); }
  Future<void> _reviewBooking(BuildContext context, WidgetRef ref, bool approve) async { try { await ref.read(bookingsControllerProvider.notifier).reviewBooking(booking.id, approve); if (context.mounted) context.pop(); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); } }
  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async { try { await ref.read(bookingsControllerProvider.notifier).updateBookingStatus(booking.id, status); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); } }
  Future<void> _reportNoShow(BuildContext context, WidgetRef ref, bool isLawyer) async { try { await ref.read(bookingsControllerProvider.notifier).reportNoShow(booking.id, isLawyer: isLawyer); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); } }
}
