import 'dart:math' as math;
import '../data/sample_data.dart';
import '../models/worker_profile.dart';

/// Content-Based AI Recommendation Engine for HomeEase.
/// Implements the mathematical formulations specified in Chapter 5 of the 60% Thesis:
/// 1. Cosine Similarity across skill vectors: Sim_skills(u, w)
/// 2. Spherical Haversine distance decay: S_geo = 1 / (1 + 0.2 * d)
/// 3. Min-Max Bayesian rating normalization: S_rating = (R - 1) / 4 (neutral 3.5 for cold start)
/// 4. Explainable AI (XAI) transparent badge generation.
class AIRecommendationEngine {
  // Calibrated weights satisfying sum(w) = 1.0
  static const double skillWeight = 0.50;
  static const double geoWeight = 0.35;
  static const double ratingWeight = 0.15;
  static const double geoDecayAlpha = 0.2; // km^-1

  // Earth's mean radius in kilometers
  static const double earthRadiusKm = 6371.0;

  /// Recommends and ranks domestic workers for a household requirement.
  static List<AIRecommendationResult> recommendWorkers({
    required List<WorkerProfile> workers,
    required String targetCategory,
    String? targetArea,
    double householdLat = 34.1983,
    double householdLon = 73.2425,
    List<String> preferredSkills = const [],
    double maxDistanceKm = 30.0,
  }) {
    if (targetArea != null && SampleData.localityCoordinates.containsKey(targetArea)) {
      householdLat = SampleData.localityCoordinates[targetArea]!['lat']!;
      householdLon = SampleData.localityCoordinates[targetArea]!['lon']!;
    }
    final List<AIRecommendationResult> results = [];

    for (final worker in workers) {
      if (!worker.profileVisibility) continue;

      // 1. Skill & Category Cosine Similarity
      final double simSkill = calculateSkillSimilarity(
        targetCategory: targetCategory,
        preferredSkills: preferredSkills,
        workerRole: worker.role,
        workerSkillTags: worker.skillTags,
        workerBio: worker.bio,
      );

      // 2. Geospatial Haversine Distance in Kilometers
      final double distKm = calculateHaversineDistance(
        lat1: householdLat,
        lon1: householdLon,
        lat2: worker.latitude,
        lon2: worker.longitude,
      );

      if (distKm > maxDistanceKm) continue;

      // Distance decay function: S_geo = 1 / (1 + alpha * d)
      final double sGeo = 1.0 / (1.0 + (geoDecayAlpha * distKm));

      // 3. Min-Max Rating Normalization with Bayesian Cold-Start Prior
      final double sRating = worker.reviewsCount > 0
          ? ((worker.rating.clamp(1.0, 5.0) - 1.0) / 4.0)
          : ((3.5 - 1.0) / 4.0); // Neutral Bayesian prior R=3.5 for cold start

      // 4. Weighted Composite Linear Score
      final double compositeScore = (skillWeight * simSkill) +
          (geoWeight * sGeo) +
          (ratingWeight * sRating);

      final int matchPercentage = (compositeScore.clamp(0.0, 1.0) * 100).round();

      // 5. Explainable AI (XAI) Reason Synthesis
      final List<String> reasons = [];
      if (simSkill >= 0.7) {
        reasons.add('Strong ${worker.role} specialization fit');
      } else if (simSkill >= 0.4) {
        reasons.add('Compatible trade skills');
      }

      if (distKm <= 2.0) {
        reasons.add('${distKm.toStringAsFixed(1)} km away in ${worker.area}');
      } else {
        reasons.add('${distKm.toStringAsFixed(1)} km from your location');
      }

      if (worker.rating >= 4.7) {
        reasons.add('${worker.rating}★ top-rated reputation');
      } else if (worker.verificationStatus == 'Verified') {
        reasons.add('Identity verified');
      }

      final String xaiBadge = '$matchPercentage% AI Match • ${distKm.toStringAsFixed(1)} km • ${worker.area}';

      results.add(AIRecommendationResult(
        worker: worker,
        compositeScore: compositeScore,
        matchPercentage: matchPercentage,
        distanceKm: distKm,
        xaiBadge: xaiBadge,
        matchReasons: reasons,
      ));
    }

    // Sort descending by composite score
    results.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));
    return results;
  }

  /// Computes vector similarity between requirement and worker capabilities.
  static double calculateSkillSimilarity({
    required String targetCategory,
    required List<String> preferredSkills,
    required String workerRole,
    required List<String> workerSkillTags,
    required String workerBio,
  }) {
    // If category is generic or matches role directly
    final categoryLower = targetCategory.toLowerCase();
    final roleLower = workerRole.toLowerCase();

    double baseScore = 0.3;
    if (roleLower.contains(categoryLower) || categoryLower.contains(roleLower)) {
      baseScore = 0.7;
    }

    if (preferredSkills.isEmpty) {
      return baseScore;
    }

    // Binary vector overlap on specific skill tags
    int matchCount = 0;
    final allWorkerTokens = {
      ...workerSkillTags.map((e) => e.toLowerCase()),
      ...roleLower.split(' '),
      ...workerBio.toLowerCase().split(' '),
    };

    for (final skill in preferredSkills) {
      if (allWorkerTokens.contains(skill.toLowerCase())) {
        matchCount++;
      }
    }

    final double skillRatio = matchCount / preferredSkills.length;
    // Blended cosine proxy
    return ((baseScore * 0.4) + (skillRatio * 0.6)).clamp(0.0, 1.0);
  }

  /// Calculates the spherical surface distance between two coordinates using Haversine formula.
  static double calculateHaversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final double phi1 = lat1 * (math.pi / 180.0);
    final double phi2 = lat2 * (math.pi / 180.0);
    final double deltaPhi = (lat2 - lat1) * (math.pi / 180.0);
    final double deltaLambda = (lon2 - lon1) * (math.pi / 180.0);

    final double a = math.sin(deltaPhi / 2.0) * math.sin(deltaPhi / 2.0) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2.0) *
            math.sin(deltaLambda / 2.0);

    final double c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return earthRadiusKm * c;
  }

  /// Evaluates and scores an individual worker profile against requirements.
  static AIRecommendationResult scoreWorker({
    required WorkerProfile worker,
    required String targetCategory,
    String? targetArea,
    double householdLat = 34.1983,
    double householdLon = 73.2425,
    List<String> preferredSkills = const [],
  }) {
    if (targetArea != null && SampleData.localityCoordinates.containsKey(targetArea)) {
      householdLat = SampleData.localityCoordinates[targetArea]!['lat']!;
      householdLon = SampleData.localityCoordinates[targetArea]!['lon']!;
    }

    final double simSkill = calculateSkillSimilarity(
      targetCategory: targetCategory,
      preferredSkills: preferredSkills,
      workerRole: worker.role,
      workerSkillTags: worker.skillTags,
      workerBio: worker.bio,
    );

    final double distKm = calculateHaversineDistance(
      lat1: householdLat,
      lon1: householdLon,
      lat2: worker.latitude,
      lon2: worker.longitude,
    );

    final double sGeo = 1.0 / (1.0 + (geoDecayAlpha * distKm));

    final double sRating = worker.reviewsCount > 0
        ? ((worker.rating.clamp(1.0, 5.0) - 1.0) / 4.0)
        : ((3.5 - 1.0) / 4.0);

    final double compositeScore = (skillWeight * simSkill) +
        (geoWeight * sGeo) +
        (ratingWeight * sRating);

    final int matchPercentage = (compositeScore.clamp(0.0, 1.0) * 100).round();
    final String xaiBadge = '$matchPercentage% Match • ${distKm.toStringAsFixed(1)} km';

    return AIRecommendationResult(
      worker: worker,
      compositeScore: compositeScore,
      matchPercentage: matchPercentage,
      distanceKm: distKm,
      xaiBadge: xaiBadge,
      matchReasons: ['Specialization: ${(simSkill * 100).round()}%', '${distKm.toStringAsFixed(1)} km away'],
    );
  }
}
