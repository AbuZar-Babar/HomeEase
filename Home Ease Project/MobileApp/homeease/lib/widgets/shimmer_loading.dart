import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/home_ease_theme.dart';

/// Shimmer Skeleton Block with soft slate gradient
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: const Color(0xFFF8FAFC).withValues(alpha: 0.8),
        );
  }
}

/// Shimmer Skeleton Worker Card Placeholder
class ShimmerWorkerCard extends StatelessWidget {
  const ShimmerWorkerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeEaseTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeEaseTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 54, height: 54, borderRadius: 27),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 130, height: 16, borderRadius: 6),
                const SizedBox(height: 8),
                const ShimmerBox(width: 90, height: 12, borderRadius: 4),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    ShimmerBox(width: 70, height: 14, borderRadius: 4),
                    SizedBox(width: 10),
                    ShimmerBox(width: 50, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const ShimmerBox(width: 60, height: 32, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Shimmer Skeleton Job Card Placeholder
class ShimmerJobCard extends StatelessWidget {
  const ShimmerJobCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeEaseTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeEaseTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 140, height: 16, borderRadius: 6),
              ShimmerBox(width: 70, height: 20, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 10),
          const ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
          const SizedBox(height: 6),
          const ShimmerBox(width: 180, height: 12, borderRadius: 4),
          const SizedBox(height: 14),
          Row(
            children: const [
              ShimmerBox(width: 90, height: 14, borderRadius: 4),
              Spacer(),
              ShimmerBox(width: 80, height: 36, borderRadius: 12),
            ],
          ),
        ],
      ),
    );
  }
}
