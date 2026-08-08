import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/reviews_provider.dart';

class ReviewDialog extends ConsumerStatefulWidget {
  final String bookingId;
  final String lawyerId;

  const ReviewDialog({super.key, required this.bookingId, required this.lawyerId});

  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  double _rating = 5.0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(reviewControllerProvider.notifier).submitReview(
          bookingId: widget.bookingId,
          lawyerId: widget.lawyerId,
          rating: _rating,
          comment: _commentController.text,
        );

    if (!mounted) return;
    final state = ref.read(reviewControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال التقييم: ${state.error}')),
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);
    return AlertDialog(
      title: const Text('كيف كانت تجربتك؟', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => IconButton(
              onPressed: state.isLoading ? null : () => setState(() => _rating = index + 1.0),
              icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
            )),
          ),
          const SizedBox(height: AppSizes.p16),
          TextField(
            controller: _commentController,
            enabled: !state.isLoading,
            decoration: const InputDecoration(hintText: 'اكتب رأيك هنا...', border: OutlineInputBorder()),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: state.isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: state.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: state.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('إرسال التقييم'),
        ),
      ],
    );
  }
}
