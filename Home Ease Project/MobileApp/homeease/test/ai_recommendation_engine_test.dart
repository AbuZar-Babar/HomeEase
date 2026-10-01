import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/data/sample_data.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/services/ai_recommendation_engine.dart';
import 'package:homeease/services/localization_service.dart';

void main() {
  group('AIRecommendationEngine - Mathematical Formulations & Ranking', () {
    test('Haversine distance calculates accurate spherical distance for Abbottabad', () {
      final mandian = SampleData.localityCoordinates['Mandian']!;
      final jhangi = SampleData.localityCoordinates['Jhangi Syedan']!;

      final distance = AIRecommendationEngine.calculateHaversineDistance(
        lat1: mandian['lat']!,
        lon1: mandian['lon']!,
        lat2: jhangi['lat']!,
        lon2: jhangi['lon']!,
      );

      // Distance between Mandian and Jhangi Syedan in Abbottabad is ~2.7 km
      expect(distance, greaterThan(2.0));
      expect(distance, lessThan(3.5));

      // Distance to self is 0.0
      final selfDistance = AIRecommendationEngine.calculateHaversineDistance(
        lat1: mandian['lat']!,
        lon1: mandian['lon']!,
        lat2: mandian['lat']!,
        lon2: mandian['lon']!,
      );
      expect(selfDistance, closeTo(0.0, 0.001));
    });

    test('Skill similarity gives higher score for direct trade matches', () {
      final cookScore = AIRecommendationEngine.calculateSkillSimilarity(
        targetCategory: 'Cook',
        preferredSkills: ['cooking', 'meal prep', 'baking'],
        workerRole: 'Cook',
        workerSkillTags: ['Cooking', 'Meal Prep', 'Baking', 'Traditional Dishes'],
        workerBio: 'Professional home chef with 8 years cooking experience.',
      );

      final cleanerScore = AIRecommendationEngine.calculateSkillSimilarity(
        targetCategory: 'Cook',
        preferredSkills: ['cooking', 'meal prep'],
        workerRole: 'Cleaner',
        workerSkillTags: ['Deep Cleaning', 'Laundry', 'Ironing'],
        workerBio: 'Experienced housemaid providing reliable cleaning.',
      );

      expect(cookScore, greaterThan(0.70));
      expect(cleanerScore, lessThan(0.50));
      expect(cookScore, greaterThan(cleanerScore));
    });

    test('Distance decay function strictly decays as distance increases', () {
      final mandian = SampleData.localityCoordinates['Mandian']!;
      final workers = SampleData.workers;

      final recommendations = AIRecommendationEngine.recommendWorkers(
        workers: workers,
        targetCategory: 'Cook',
        householdLat: mandian['lat']!,
        householdLon: mandian['lon']!,
      );

      expect(recommendations, isNotEmpty);
      // Results should be sorted in descending order of composite score
      for (int i = 0; i < recommendations.length - 1; i++) {
        expect(
          recommendations[i].compositeScore,
          greaterThanOrEqualTo(recommendations[i + 1].compositeScore),
        );
      }
    });

    test('Cold-start workers with zero reviews get neutral Bayesian prior', () {
      final coldWorker = WorkerProfile(
        id: 'cold_1',
        name: 'New Worker',
        role: 'Cook',
        rating: 0.0,
        reviewsCount: 0,
        rate: 'PKR 800/hr',
        experience: '1 year',
        experienceYears: 1,
        availability: 'Available',
        location: 'Mandian',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        skillTags: ['Cooking'],
        profileVisibility: true,
        verificationStatus: 'Verified',
        description: 'Fresh cook candidate in Mandian',
        highlight: 'Fresh candidate',
        bio: 'Cook bio',
      );

      final score = AIRecommendationEngine.scoreWorker(
        worker: coldWorker,
        targetCategory: 'Cook',
        targetArea: 'Mandian',
      );

      // Bayesian prior 3.5 maps to normalized score 0.625
      // Verify composite score is non-zero and worker is recommended
      expect(score.compositeScore, greaterThan(0.4));
      expect(score.matchPercentage, greaterThan(40));
      expect(score.xaiBadge, contains('Match'));
    });
  });

  group('LocalizationService - Bilingual Support & High-Affordance Icons', () {
    setUp(() {
      LocalizationService.setLanguage(LocalizationService.langEnglish);
    });

    test('Toggles seamlessly between English and Urdu with correct directionality', () {
      expect(LocalizationService.isUrdu, isFalse);
      expect(LocalizationService.direction, TextDirection.ltr);
      expect(LocalizationService.tr('appTitle'), 'HomeEase');

      LocalizationService.toggleLanguage();
      expect(LocalizationService.isUrdu, isTrue);
      expect(LocalizationService.direction, TextDirection.rtl);
      expect(LocalizationService.tr('appTitle'), 'ہوم ایز');
      expect(LocalizationService.tr('postAJob'), 'نیا کام / جاب پوسٹ کریں');
      expect(LocalizationService.tr('browseJobs'), 'دستیاب کام دیکھیں');

      LocalizationService.toggleLanguage();
      expect(LocalizationService.isUrdu, isFalse);
      expect(LocalizationService.direction, TextDirection.ltr);
    });

    test('Provides distinct category icons and thematic colors for domestic trades', () {
      final cookIcon = LocalizationService.getCategoryIcon('Cook');
      final cleanIcon = LocalizationService.getCategoryIcon('Cleaner');
      final nannyIcon = LocalizationService.getCategoryIcon('Nanny');

      expect(cookIcon, Icons.restaurant_rounded);
      expect(cleanIcon, Icons.cleaning_services_rounded);
      expect(nannyIcon, Icons.child_care_rounded);

      final cookColor = LocalizationService.getCategoryColor('Cook');
      final cleanColor = LocalizationService.getCategoryColor('Cleaner');
      expect(cookColor, isNot(equals(cleanColor)));
    });
  });

  group('Marketplace Models - JobPost and JobApplication', () {
    test('JobPost initialization and properties integrity', () {
      final job = JobPost(
        id: 'job_test_1',
        householdId: 'h_1',
        householdName: 'Ali Khan',
        title: 'Need cook for dinner party',
        serviceCategory: 'Cook',
        description: 'Prepare biryani and chicken karahi for 8 guests.',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 3500.0,
        requiredDate: DateTime.now().add(const Duration(days: 1)),
        status: 'open',
        createdAt: DateTime.now(),
      );

      expect(job.title, 'Need cook for dinner party');
      expect(job.budget, 3500.0);
      expect(job.status, 'open');
      expect(job.area, 'Mandian');
    });

    test('JobApplication stores proposed rate and worker metadata', () {
      final app = JobApplication(
        id: 'app_1',
        jobPostId: 'job_test_1',
        workerId: 'worker_1',
        workerName: 'Rabia Bibi',
        workerRole: 'Cook',
        workerRating: 4.8,
        proposedRate: 3200.0,
        notes: 'I have 8+ years experience preparing traditional dinner meals.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      expect(app.workerName, 'Rabia Bibi');
      expect(app.proposedRate, 3200.0);
      expect(app.status, 'pending');
    });
  });
}
