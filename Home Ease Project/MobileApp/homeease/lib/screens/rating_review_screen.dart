import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class RatingReviewScreen extends StatefulWidget {
  const RatingReviewScreen({
    super.key,
    required this.booking,
    required this.worker,
    required this.onBack,
    required this.onSubmit,
  });

  final Booking booking;
  final WorkerProfile worker;
  final VoidCallback onBack;
  final Function(int rating, String comment) onSubmit;

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _overallRating = 5;
  int _performanceRating = 5;
  int _punctualityRating = 5;
  int _behaviorRating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildStarSelector(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: HomeEaseTheme.text),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isSelected = starValue <= value;
            return IconButton(
              icon: Icon(
                isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 28,
              ),
              onPressed: () => onChanged(starValue),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            );
          }),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Rate worker',
      subtitle: 'Share your service experience with the community.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeEaseCard(
            color: HomeEaseTheme.cardDark,
            child: Row(
              children: [
                const WorkerAvatar(circular: true, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.worker.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: HomeEaseTheme.brand),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.worker.role,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStarSelector('Overall Service Quality', _overallRating, (val) {
                  setState(() => _overallRating = val);
                }),
                _buildStarSelector('Work Performance', _performanceRating, (val) {
                  setState(() => _performanceRating = val);
                }),
                _buildStarSelector('Punctuality & Arrival Time', _punctualityRating, (val) {
                  setState(() => _punctualityRating = val);
                }),
                _buildStarSelector('Professionalism & Behavior', _behaviorRating, (val) {
                  setState(() => _behaviorRating = val);
                }),
                const SizedBox(height: 8),
                const SectionLabel('Write a review (optional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Share feedback about the service to help others hire.',
                  ),
                ),
                const SizedBox(height: 20),
                HomeEaseButton(
                  label: 'Submit Feedback',
                  onPressed: () {
                    widget.onSubmit(_overallRating, _commentController.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
