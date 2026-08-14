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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تقييم المحامي', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => IconButton(
              onPressed: () => setState(() => _rating = index + 1.0),
              icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: AppColors.secondaryLight, size: 32),
            )),
          ),
          const SizedBox(height: AppSizes.p16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(hintText: 'اكتب رأيك هنا...', border: OutlineInputBorder()),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            await ref.read(reviewControllerProvider.notifier).submitReview(bookingId: widget.bookingId, lawyerId: widget.lawyerId, rating: _rating, comment: _commentController.text);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('إرسال التقييم'),
        ),
      ],
    );
  }
}
