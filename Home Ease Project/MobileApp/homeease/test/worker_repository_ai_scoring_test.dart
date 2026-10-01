import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/data/sample_data.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/services/ai_recommendation_engine.dart';
import 'package:homeease/services/worker_repository.dart';

void main() {
  // Abbottabad coordinate reference landmarks
  final mandian = SampleData.localityCoordinates['Mandian']!;
  final jhangi = SampleData.localityCoordinates['Jhangi Syedan']!;
  final supply = SampleData.localityCoordinates['Supply Bazaar']!;
  final nawanShehr = SampleData.localityCoordinates['Nawan Shehr']!;
  final pmaRoad = SampleData.localityCoordinates['PMA Kakul Road']!;

  // ===========================================================================
  // TIER 1: CORE FEATURE & UNIT COVERAGE (>=5 tests)
  // ===========================================================================
  group('Tier 1: Worker Repository & AI Scoring - Feature Coverage', () {
    test('AI-T1-01: Haversine distance calculates accurate spherical distance for Abbottabad', () {
      // Mandian (34.1983, 73.2425) to Jhangi Syedan (34.1750, 73.2280) is ~2.7 km
      final distMandianJhangi = AIRecommendationEngine.calculateHaversineDistance(
        lat1: mandian['lat']!,
        lon1: mandian['lon']!,
        lat2: jhangi['lat']!,
        lon2: jhangi['lon']!,
      );
      expect(distMandianJhangi, greaterThan(2.0));
      expect(distMandianJhangi, lessThan(3.5));

      // Mandian to Supply Bazaar (34.1580, 73.2190) is ~4.8 km
      final distMandianSupply = AIRecommendationEngine.calculateHaversineDistance(
        lat1: mandian['lat']!,
        lon1: mandian['lon']!,
        lat2: supply['lat']!,
        lon2: supply['lon']!,
      );
      expect(distMandianSupply, greaterThan(4.0));
      expect(distMandianSupply, lessThan(5.5));
    });

    test('AI-T1-02: Skill similarity gives high score for direct trade specialization', () {
      final electricianScore = AIRecommendationEngine.calculateSkillSimilarity(
        targetCategory: 'Electrician',
        preferredSkills: ['wiring', 'ups installation', 'circuit breakers'],
        workerRole: 'Electrician',
        workerSkillTags: ['Wiring', 'UPS Installation', 'Circuit Breakers', 'Fan Repair'],
        workerBio: 'Licensed domestic electrician for distribution boards and home wiring.',
      );

      final cleanerScore = AIRecommendationEngine.calculateSkillSimilarity(
        targetCategory: 'Electrician',
        preferredSkills: ['wiring', 'ups installation'],
        workerRole: 'Cleaner',
        workerSkillTags: ['Deep Cleaning', 'Sanitation', 'Floor Polishing'],
        workerBio: 'Housemaid providing cleaning services.',
      );

      expect(electricianScore, greaterThan(0.70));
      expect(cleanerScore, lessThan(0.50));
      expect(electricianScore, greaterThan(cleanerScore));
    });

    test('AI-T1-03: Rating score normalization calculates accurately for experienced workers', () {
      final worker = WorkerProfile(
        id: 'w_test_1',
        name: 'Tariq Mehmood',
        role: 'Electrician',
        rating: 4.8,
        reviewsCount: 28,
        rate: 'PKR 1,800/hr',
        experience: '6 years',
        experienceYears: 6,
        availability: 'Available',
        location: 'Mandian',
        area: 'Mandian',
        latitude: mandian['lat']!,
        longitude: mandian['lon']!,
        skillTags: ['Wiring', 'Lighting'],
        description: 'Master electrician',
        highlight: 'Verified',
        bio: 'Electrician bio',
      );

      final result = AIRecommendationEngine.scoreWorker(
        worker: worker,
        targetCategory: 'Electrician',
        targetArea: 'Mandian',
      );

      // (4.8 - 1.0) / 4.0 = 0.95 rating score
      expect(result.compositeScore, greaterThan(0.75));
      expect(result.matchPercentage, greaterThanOrEqualTo(75));
      expect(result.xaiBadge, contains('Match'));
    });

    test('AI-T1-04: Composite score ranking orders candidates monotonically', () {
      final recommendations = AIRecommendationEngine.recommendWorkers(
        workers: SampleData.workers,
        targetCategory: 'Cleaner',
        householdLat: supply['lat']!,
        householdLon: supply['lon']!,
      );

      expect(recommendations, isNotEmpty);
      for (int i = 0; i < recommendations.length - 1; i++) {
        expect(
          recommendations[i].compositeScore,
          greaterThanOrEqualTo(recommendations[i + 1].compositeScore),
          reason: 'Worker at index $i must have score >= worker at index ${i + 1}',
        );
      }
    });

    test('AI-T1-05: Explainable AI badge formats transparent reasoning tokens', () {
      final cookWorker = SampleData.workers.firstWhere((w) => w.role == 'Cook');
      final result = AIRecommendationEngine.scoreWorker(
        worker: cookWorker,
        targetCategory: 'Cook',
        householdLat: jhangi['lat']!,
        householdLon: jhangi['lon']!,
      );

      expect(result.xaiBadge, contains('% Match'));
      expect(result.xaiBadge, contains('km'));
      expect(result.matchReasons, isNotEmpty);
      expect(
        result.matchReasons.any((r) => r.contains('Cook specialization fit') || r.contains('Specialization')),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // TIER 2: BOUNDARY, CORNER & ADVERSARIAL CASES (>=5 tests)
  // ===========================================================================
  group('Tier 2: Worker Repository & AI Scoring - Boundary & Corner Cases', () {
    test('AI-T2-01: Self-distance with identical coordinates strictly equals 0.0 with no zero-division', () {
      final dist = AIRecommendationEngine.calculateHaversineDistance(
        lat1: mandian['lat']!,
        lon1: mandian['lon']!,
        lat2: mandian['lat']!,
        lon2: mandian['lon']!,
      );

      expect(dist, closeTo(0.0, 0.0001));

      // Test distance decay at zero distance: 1 / (1 + 0.2 * 0) = 1.0
      final worker = SampleData.workers.firstWhere((w) => w.area == 'Mandian');
      final scoreAtZero = AIRecommendationEngine.scoreWorker(
        worker: worker,
        targetCategory: worker.role,
        householdLat: mandian['lat']!,
        householdLon: mandian['lon']!,
      );

      expect(scoreAtZero.distanceKm, closeTo(0.0, 0.01));
      expect(scoreAtZero.compositeScore, greaterThan(0.50));
    });

    test('AI-T2-02: Cold-start worker with zero reviews gets neutral Bayesian prior (3.5)', () {
      final coldWorker = WorkerProfile(
        id: 'cold_worker_99',
        name: 'Fresh Plumber',
        role: 'Plumber',
        rating: 0.0,
        reviewsCount: 0, // Zero reviews
        rate: 'PKR 1,500/hr',
        experience: '2 years',
        experienceYears: 2,
        availability: 'Available today',
        location: 'Supply Bazaar',
        area: 'Supply Bazaar',
        latitude: supply['lat']!,
        longitude: supply['lon']!,
        skillTags: ['Pipe Leakage', 'Water Pump Repair'],
        description: 'New verified plumber',
        highlight: 'Fresh candidate',
        bio: 'Reliable plumbing expert',
      );

      final result = AIRecommendationEngine.scoreWorker(
        worker: coldWorker,
        targetCategory: 'Plumber',
        targetArea: 'Supply Bazaar',
      );

      // Bayesian neutral prior = 3.5 -> (3.5 - 1.0) / 4.0 = 0.625
      // Composite score should NOT drop to zero
      expect(result.compositeScore, greaterThan(0.50));
      expect(result.matchPercentage, greaterThan(50));
      expect(result.xaiBadge, contains('Match'));
    });

    test('AI-T2-03: Distant candidate (> 50 km) decays smoothly without negative score', () {
      // Islamabad coordinates (~75 km from Abbottabad)
      const islamabadLat = 33.6844;
      const islamabadLon = 73.0479;

      final dist = AIRecommendationEngine.calculateHaversineDistance(
        lat1: mandian['lat']!,
        lon1: mandian['lon']!,
        lat2: islamabadLat,
        lon2: islamabadLon,
      );

      expect(dist, greaterThan(50.0));

      final worker = SampleData.workers.first;
      final result = AIRecommendationEngine.scoreWorker(
        worker: worker,
        targetCategory: worker.role,
        householdLat: islamabadLat,
        householdLon: islamabadLon,
      );

      // Score should decay heavily due to distance, but stay >= 0
      expect(result.compositeScore, greaterThan(0.0));
      expect(result.distanceKm, greaterThan(50.0));
      expect(result.matchPercentage, lessThan(80));
    });

    test('AI-T2-04: Worker profile with empty skills and empty bio evaluates safely', () {
      final emptyWorker = WorkerProfile(
        id: 'empty_worker_1',
        name: 'Minimal Worker',
        role: 'Nanny',
        rating: 4.0,
        reviewsCount: 5,
        rate: 'PKR 2,000/visit',
        experience: '1 year',
        experienceYears: 1,
        availability: 'Available',
        location: 'Nawan Shehr',
        area: 'Nawan Shehr',
        latitude: nawanShehr['lat']!,
        longitude: nawanShehr['lon']!,
        skillTags: const [], // Empty list
        description: '',
        highlight: '',
        bio: '', // Empty bio
      );

      final result = AIRecommendationEngine.scoreWorker(
        worker: emptyWorker,
        targetCategory: 'Nanny',
        targetArea: 'Nawan Shehr',
      );

      expect(result.compositeScore, greaterThan(0.3));
      expect(result.matchPercentage, greaterThan(30));
    });

    test('AI-T2-05: Rating normalization extremes: 5.0 maps to 1.0, 1.0 maps to 0.0', () {
      final perfectWorker = WorkerProfile(
        id: 'perfect_1',
        name: 'Perfect Worker',
        role: 'Caregiver',
        rating: 5.0,
        reviewsCount: 50,
        rate: 'PKR 3,500/day',
        experience: '8 years',
        experienceYears: 8,
        availability: 'Available',
        location: 'Mandian',
        area: 'Mandian',
        latitude: mandian['lat']!,
        longitude: mandian['lon']!,
        skillTags: ['Elderly Care'],
        description: 'Top caregiver',
        highlight: '5-star',
      );

      final lowestWorker = WorkerProfile(
        id: 'lowest_1',
        name: 'Lowest Worker',
        role: 'Caregiver',
        rating: 1.0,
        reviewsCount: 10,
        rate: 'PKR 1,500/day',
        experience: '1 year',
        experienceYears: 1,
        availability: 'Available',
        location: 'Mandian',
        area: 'Mandian',
        latitude: mandian['lat']!,
        longitude: mandian['lon']!,
        skillTags: ['Elderly Care'],
        description: 'New caregiver',
        highlight: 'Basic',
      );

      final scorePerfect = AIRecommendationEngine.scoreWorker(
        worker: perfectWorker,
        targetCategory: 'Caregiver',
        targetArea: 'Mandian',
      );

      final scoreLowest = AIRecommendationEngine.scoreWorker(
        worker: lowestWorker,
        targetCategory: 'Caregiver',
        targetArea: 'Mandian',
      );

      expect(scorePerfect.compositeScore, greaterThan(scoreLowest.compositeScore));
      // Difference in rating contribution is (1.0 - 0.0) * 0.15 = 0.15
      expect(scorePerfect.compositeScore - scoreLowest.compositeScore, closeTo(0.15, 0.02));
    });
  });

  // ===========================================================================
  // TIER 3: PAIRWISE COMBINATORIAL TESTING (Trades x Localities)
  // ===========================================================================
  group('Tier 3: Worker Repository & AI Scoring - Pairwise Combinations (6 Trades x 5 Localities)', () {
    final trades = ['Cook', 'Cleaner', 'Nanny', 'Caregiver', 'Maid', 'Electrician'];
    final localities = ['Mandian', 'Jhangi Syedan', 'Supply Bazaar', 'Nawan Shehr', 'PMA Kakul Road'];

    for (final trade in trades) {
      for (final locality in localities) {
        test('AI-T3: Pairwise ranking stability for trade $trade in locality $locality', () {
          final locCoords = SampleData.localityCoordinates[locality]!;

          final ranked = AIRecommendationEngine.recommendWorkers(
            workers: SampleData.workers,
            targetCategory: trade,
            householdLat: locCoords['lat']!,
            householdLon: locCoords['lon']!,
          );

          expect(ranked, isNotEmpty);
          // Verify top score is bounded between 0 and 1
          expect(ranked.first.compositeScore, inInclusiveRange(0.0, 1.0));
          expect(ranked.first.matchPercentage, inInclusiveRange(0, 100));
          expect(ranked.first.xaiBadge, isNotEmpty);
        });
      }
    }
  });

  // ===========================================================================
  // TIER 4: REAL-WORLD SCENARIOS / E2E USER JOURNEYS
  // ===========================================================================
  group('Tier 4: Worker Repository & AI Scoring - Real-World End-to-End Search Journeys', () {
    test('AI-T4-01: Household in Mandian searches for a Cook with AI explainable recommendations', () {
      // 1. Household initiates search for Cook from COMSATS/Mandian
      final searchResults = AIRecommendationEngine.recommendWorkers(
        workers: SampleData.workers,
        targetCategory: 'Cook',
        preferredSkills: ['biryani', 'meal prep', 'family dinner'],
        householdLat: mandian['lat']!,
        householdLon: mandian['lon']!,
      );

      expect(searchResults, isNotEmpty);

      // 2. Top candidate should be a Cook
      final topMatch = searchResults.first;
      expect(topMatch.worker.role, 'Cook');
      expect(topMatch.matchPercentage, greaterThanOrEqualTo(55));

      // 3. Transparent XAI badge contains distance and trade fit
      expect(topMatch.xaiBadge, contains('% AI Match'));
      expect(topMatch.distanceKm, lessThan(4.0)); // In Abbottabad radius

      // 4. Verify match reasons contain specialization details or trade skills
      expect(
        topMatch.matchReasons.any((r) => r.contains('specialization fit') || r.contains('trade skills')),
        isTrue,
      );

      // 5. Worker profile attributes are fully accessible for detail navigation
      expect(topMatch.worker.name, isNotEmpty);
      expect(topMatch.worker.rate, isNotEmpty);
      expect(topMatch.worker.rating, greaterThan(4.0));
    });

    test('AI-T4-02: Household in Supply Bazaar searches for deep home cleaning', () {
      final cleanerResults = AIRecommendationEngine.recommendWorkers(
        workers: SampleData.workers,
        targetCategory: 'Cleaner',
        preferredSkills: ['deep cleaning', 'floor polishing', 'sanitation'],
        householdLat: supply['lat']!,
        householdLon: supply['lon']!,
      );

      expect(cleanerResults, isNotEmpty);
      final topCleaner = cleanerResults.first;

      // Sana Gul is located in Supply Bazaar and is a Cleaner
      expect(topCleaner.worker.role, 'Cleaner');
      expect(topCleaner.distanceKm, lessThan(1.5));
      expect(topCleaner.compositeScore, greaterThan(0.80));
    });
  });

  // ===========================================================================
  // TIER 5: WORKER REPOSITORY & MODEL DESERIALIZATION COVERAGE
  // ===========================================================================
  group('Tier 5: Worker Repository & Model Deserialization Coverage', () {
    test('WR-T5-01: WorkerProfile.fromMap cleanly deserializes joined PostgREST response with profiles table', () {
      final postgrestRow = {
        'id': '00000000-0000-0000-0000-000000000010',
        'skills': ['Desi Cooking', 'Meal Prep', 'Baking', 'Traditional Biryani', 'Family Meals', 'Cook'],
        'experience_years': 4,
        'hourly_rate': 3000.0,
        'locality': 'Jhangi Syedan',
        'bio': 'Professional home cook with 4 years of experience preparing traditional Pakistani dishes.',
        'rating': 4.80,
        'reviews_count': 24,
        'verified': true,
        'availability': {
          'status': 'Available today',
          'slots': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        },
        'latitude': 34.1750,
        'longitude': 73.2280,
        'profile_visibility': true,
        'profiles': {
          'id': '00000000-0000-0000-0000-000000000010',
          'full_name': 'Rabia Bibi',
          'email': 'worker@homeease.com',
          'phone': '+923111234567',
          'avatar_url': 'https://example.com/avatar1.jpg',
          'role': 'worker',
        },
      };

      final worker = WorkerProfile.fromMap(postgrestRow);

      expect(worker.id, '00000000-0000-0000-0000-000000000010');
      expect(worker.name, 'Rabia Bibi');
      expect(worker.phone, '+923111234567');
      expect(worker.avatarUrl, 'https://example.com/avatar1.jpg');
      expect(worker.role, 'Cook');
      expect(worker.hourlyRate, 3000.0);
      expect(worker.rate, contains('3000'));
      expect(worker.experienceYears, 4);
      expect(worker.experience, contains('4'));
      expect(worker.rating, 4.80);
      expect(worker.reviewsCount, 24);
      expect(worker.area, 'Jhangi Syedan');
      expect(worker.verificationStatus, 'Verified');
      expect(worker.highlight, 'Verified');
      expect(worker.availabilityStatus, 'Available today');
      expect(worker.latitude, 34.1750);
      expect(worker.longitude, 73.2280);
      expect(worker.skillTags, contains('Desi Cooking'));
    });

    test('WR-T5-02: WorkerProfile.fromMap handles list-wrapped joined profiles and missing optional attributes gracefully', () {
      final listJoinedRow = {
        'id': '00000000-0000-0000-0000-000000000011',
        'skills': ['Toddler Care', 'Nanny'],
        'experience_years': 3,
        'hourly_rate': 2500,
        'locality': 'Mandian',
        'rating': 4.7,
        'reviews_count': 18,
        'verified': true,
        'latitude': 34.1983,
        'longitude': 73.2425,
        'profiles': [
          {
            'id': '00000000-0000-0000-0000-000000000011',
            'full_name': 'Amina Noor',
            'email': 'amina.noor@homeease.com',
            'role': 'worker',
          }
        ],
      };

      final worker = WorkerProfile.fromMap(listJoinedRow);

      expect(worker.name, 'Amina Noor');
      expect(worker.role, 'Nanny');
      expect(worker.avatarUrl, isNull);
      expect(worker.phone, isNull);
      expect(worker.hourlyRate, 2500.0);
      expect(worker.city, 'Abbottabad');
      expect(worker.area, 'Mandian');
      expect(worker.profileVisibility, isTrue);
    });

    test('WR-T5-03: WorkerProfile.toMap produces matching Supabase schema dictionary with joined profiles structure', () {
      final worker = WorkerProfile(
        id: 'w_test_serialize',
        name: 'Muhammad Arshad',
        role: 'Electrician',
        rating: 4.8,
        reviewsCount: 30,
        rate: 'PKR 2,500 / hr',
        hourlyRate: 2500.0,
        experience: '5 years',
        experienceYears: 5,
        availability: 'Available today',
        availabilityStatus: 'Available today',
        location: 'Mandian',
        area: 'Mandian',
        description: 'Certified Electrician',
        highlight: 'Verified',
        bio: 'Residential and commercial electrician',
        verificationStatus: 'Verified',
        latitude: mandian['lat']!,
        longitude: mandian['lon']!,
        skillTags: ['Wiring', 'UPS Installation', 'Circuit Breakers'],
        phone: '+923225566778',
        avatarUrl: 'https://example.com/arshad.jpg',
      );

      final map = worker.toMap();

      expect(map['id'], 'w_test_serialize');
      expect(map['skills'], contains('Wiring'));
      expect(map['experience_years'], 5);
      expect(map['hourly_rate'], 2500.0);
      expect(map['locality'], 'Mandian');
      expect(map['verified'], isTrue);
      expect(map['latitude'], mandian['lat']!);
      expect(map['longitude'], mandian['lon']!);
      expect(map['profiles'], isA<Map<String, dynamic>>());
      expect(map['profiles']['full_name'], 'Muhammad Arshad');
      expect(map['profiles']['phone'], '+923225566778');
      expect(map['profiles']['role'], 'worker');
    });

    test('WR-T5-04: WorkerRepository singleton instance, client injection, and reset behavior', () {
      final repo1 = WorkerRepository();
      final repo2 = WorkerRepository();
      expect(identical(repo1, repo2), isTrue);

      // Verify reset does not crash
      repo1.reset();
      expect(repo1.client, isNull);
    });

    test('WR-T5-05: WorkerRepository.fetchWorkers filters candidates by category, locality, and query with graceful fallback', () async {
      final repo = WorkerRepository();

      // 1. Fetch all workers
      final allWorkers = await repo.fetchWorkers();
      expect(allWorkers, isNotEmpty);
      expect(allWorkers.length, greaterThanOrEqualTo(5));

      // 2. Fetch by category
      final cooks = await repo.fetchWorkers(category: 'Cook');
      expect(cooks, isNotEmpty);
      expect(cooks.every((w) => w.role == 'Cook' || w.skillTags.any((s) => s.toLowerCase().contains('cook'))), isTrue);

      // 3. Fetch by locality
      final mandianWorkers = await repo.fetchWorkers(locality: 'Mandian');
      expect(mandianWorkers, isNotEmpty);
      expect(mandianWorkers.every((w) => w.area == 'Mandian' || w.location.contains('Mandian')), isTrue);

      // 4. Fetch by search query
      final rabiaSearch = await repo.fetchWorkers(query: 'Rabia');
      expect(rabiaSearch, isNotEmpty);
      expect(rabiaSearch.first.name, contains('Rabia'));
    });

    test('WR-T5-06: WorkerRepository.getWorkerById retrieves targeted worker profile', () async {
      final repo = WorkerRepository();

      final rabia = await repo.getWorkerById('worker_1');
      expect(rabia, isNotNull);
      expect(rabia!.name, 'Rabia Bibi');
      expect(rabia.role, 'Cook');

      final nonExistent = await repo.getWorkerById('non_existent_worker_xyz');
      expect(nonExistent, isNull);
    });

    test('WR-T5-07: Dynamic worker profiles deserialized from PostgREST feed directly into AIRecommendationEngine for composite ranking and XAI badges', () async {
      // Simulate live PostgREST response records from PMA Kakul Road and Mandian
      final livePostgrestRecords = [
        {
          'id': 'w_pma_cook',
          'skills': ['Desi Cooking', 'Chapati & Naan', 'Cook'],
          'experience_years': 3,
          'hourly_rate': 2800.0,
          'locality': 'PMA Kakul Road',
          'bio': 'Passionate cook specializing in northern Pakistani cuisines.',
          'rating': 4.50,
          'reviews_count': 11,
          'verified': true,
          'latitude': pmaRoad['lat']!,
          'longitude': pmaRoad['lon']!,
          'profile_visibility': true,
          'profiles': {
            'id': 'w_pma_cook',
            'full_name': 'Nasreen Akhtar',
            'phone': '+923135566778',
            'role': 'worker',
          },
        },
        {
          'id': 'w_mandian_cook',
          'skills': ['Traditional Biryani', 'Family Meals', 'Cook'],
          'experience_years': 4,
          'hourly_rate': 3000.0,
          'locality': 'Mandian',
          'bio': 'Home cook expert for family events.',
          'rating': 4.80,
          'reviews_count': 24,
          'verified': true,
          'latitude': mandian['lat']!,
          'longitude': mandian['lon']!,
          'profile_visibility': true,
          'profiles': {
            'id': 'w_mandian_cook',
            'full_name': 'Rabia Bibi',
            'phone': '+923111234567',
            'role': 'worker',
          },
        },
      ];

      // Convert dynamically to WorkerProfile instances via fromMap
      final dynamicWorkers = livePostgrestRecords
          .map((m) => WorkerProfile.fromMap(m))
          .toList();

      // Feed into AIRecommendationEngine for a household in PMA Kakul Road
      final recommendations = AIRecommendationEngine.recommendWorkers(
        workers: dynamicWorkers,
        targetCategory: 'Cook',
        householdLat: pmaRoad['lat']!,
        householdLon: pmaRoad['lon']!,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.length, 2);

      // Candidate at PMA Kakul Road is ~0.0 km away -> has highest geographic proximity
      final topRec = recommendations.first;
      expect(topRec.worker.name, 'Nasreen Akhtar');
      expect(topRec.distanceKm, closeTo(0.0, 0.05));
      expect(topRec.compositeScore, greaterThan(0.70));
      expect(topRec.matchPercentage, greaterThanOrEqualTo(70));
      expect(topRec.xaiBadge, contains('% AI Match'));
      expect(topRec.xaiBadge, contains('km'));
      expect(topRec.matchReasons, isNotEmpty);
    });
  });
}

