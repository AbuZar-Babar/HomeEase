import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/worker_profile.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/animated_scale_button.dart';
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

  final Set<String> _selectedCompliments = {};

  final List<String> _complimentTags = [
    'Very Punctual',
    'Thorough & Detailed',
    'Polite & Respectful',
    'Honest & Trustworthy',
    'Fast & Efficient',
    'Great Communication',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleCompliment(String tag) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedCompliments.contains(tag)) {
        _selectedCompliments.remove(tag);
      } else {
        _selectedCompliments.add(tag);
      }
    });
  }

  Widget _buildStarSelector(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: HomeEaseTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isSelected = starValue <= value;
            return AnimatedScaleTap(
              scaleFactor: 0.85,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(starValue);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 4),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isSelected ? Colors.amber : HomeEaseTheme.outline,
                  size: 30,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;

    return AppScaffold(
      title: isUrdu ? 'ورکر کی درجہ بندی' : 'Rate Experience',
      subtitle: isUrdu
          ? 'ایبٹ آباد کمیونٹی کے لیے اپنی رائے درج کریں'
          : 'Share verified feedback to help the Abbottabad community.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker Profile Card
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Row(
              children: [
                const WorkerAvatar(circular: true, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.worker.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: HomeEaseTheme.brand,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.worker.role} • ${widget.worker.location}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms),

          const SizedBox(height: 16),

          // Star Criteria Card
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStarSelector(
                  isUrdu ? 'مجموعی سروس کا معیار' : 'Overall Service Quality',
                  _overallRating,
                  (val) => setState(() => _overallRating = val),
                ),
                _buildStarSelector(
                  isUrdu ? 'کام کی کارکردگی اور صفائی' : 'Work Performance & Quality',
                  _performanceRating,
                  (val) => setState(() => _performanceRating = val),
                ),
                _buildStarSelector(
                  isUrdu ? 'وقت کی پابندی' : 'Punctuality & Arrival Time',
                  _punctualityRating,
                  (val) => setState(() => _punctualityRating = val),
                ),
                _buildStarSelector(
                  isUrdu ? 'شائستگی اور پیشہ ورانہ رویہ' : 'Professionalism & Politeness',
                  _behaviorRating,
                  (val) => setState(() => _behaviorRating = val),
                ),
                const Divider(height: 20, color: HomeEaseTheme.outline),
                const SectionLabel('Quick Compliments'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _complimentTags.map((tag) {
                    final isSelected = _selectedCompliments.contains(tag);
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : HomeEaseTheme.brand,
                        ),
                      ),
                      selectedColor: HomeEaseTheme.brand,
                      backgroundColor: HomeEaseTheme.brand.withValues(alpha: 0.06),
                      side: BorderSide(
                        color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline,
                      ),
                      onSelected: (_) => _toggleCompliment(tag),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SectionLabel(isUrdu ? 'تفصیلی رائے (اختیاری)' : 'Detailed Feedback (Optional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe how the service went to help other households hire with confidence.',
                  ),
                ),
                const SizedBox(height: 20),
                HomeEaseButton(
                  label: isUrdu ? 'رائے جمع کروائیں' : 'Submit Review',
                  onPressed: () {
                    final comment = _commentController.text.trim();
                    final combined = _selectedCompliments.isNotEmpty
                        ? '${_selectedCompliments.join(", ")}. $comment'.trim()
                        : comment;
                    widget.onSubmit(_overallRating, combined);
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

