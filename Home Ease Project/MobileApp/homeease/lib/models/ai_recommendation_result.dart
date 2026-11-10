import 'worker_profile.dart';

class AIRecommendationResult {
  final WorkerProfile worker;
  final double compositeScore;
  final int matchPercentage;
  final double distanceKm;
  final String xaiBadge;
  final List<String> matchReasons;

  const AIRecommendationResult({
    required this.worker,
    required this.compositeScore,
    required this.matchPercentage,
    required this.distanceKm,
    required this.xaiBadge,
    required this.matchReasons,
  });

  double get score => compositeScore;
}
