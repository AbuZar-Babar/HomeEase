import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/config/supabase_config.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/services/supabase_auth_service.dart';

void main() {
  late SupabaseAuthService authService;

  setUp(() {
    authService = SupabaseAuthService();
    authService.resetForTesting();
  });

  tearDown(() async {
    await authService.signOut();
  });

  // ===========================================================================
  // TIER 1: CORE FEATURE & UNIT COVERAGE (>=5 tests)
  // ===========================================================================
  group('Tier 1: Authentication & Role-Based Access - Feature Coverage', () {
    test('AUTH-T1-01: Household user registration creates active household user', () async {
      final AppUser user = await authService.signUp(
        name: 'Ahmed Tariq',
        email: 'ahmed.tariq@example.com',
        phone: '+923001122334',
        password: 'securePassword123',
        role: 'Household',
      );

      expect(user.id, isNotEmpty);
      expect(user.fullName, 'Ahmed Tariq');
      expect(user.email, 'ahmed.tariq@example.com');
      expect(user.phone, '+923001122334');
      expect(user.role, 'Household');
      expect(user.accountStatus, 'Active');
      expect(authService.currentUser?.id, user.id);
      expect(authService.isAuthenticated, isTrue);
    });

    test('AUTH-T1-02: Worker user registration creates active worker user with trade data', () async {
      final AppUser user = await authService.signUp(
        name: 'Rashid Minhas',
        email: 'rashid.minhas@example.com',
        phone: '+923018899001',
        password: 'workerPassword456',
        role: 'Worker',
        tradeData: {
          'category': 'Electrician',
          'experience': '5 years',
          'rate': 'PKR 1200 / visit',
          'bio': 'Certified electrician with 5 years experience',
          'locality': 'Mandian',
        },
      );

      expect(user.id, isNotEmpty);
      expect(user.fullName, 'Rashid Minhas');
      expect(user.role, 'Worker');
      expect(user.accountStatus, 'Active');
      expect(authService.currentUser?.role, 'Worker');
      expect(authService.isAuthenticated, isTrue);
    });

    test('AUTH-T1-03: Sign in with valid household credentials restores session', () async {
      final user = await authService.signIn(
        'household@homeease.com',
        'password123',
        'Household',
      );

      expect(user, isNotNull);
      expect(user?.fullName, 'Babar Khan');
      expect(user?.role, 'Household');
      expect(authService.currentUser?.id, user?.id);
      expect(authService.isAuthenticated, isTrue);
    });

    test('AUTH-T1-04: Sign in with valid worker credentials restores session', () async {
      final user = await authService.signIn(
        'worker@homeease.com',
        'password123',
        'Worker',
      );

      expect(user, isNotNull);
      expect(user?.fullName, 'Rabia Bibi');
      expect(user?.role, 'Worker');
      expect(authService.currentUser?.id, user?.id);
      expect(authService.isAuthenticated, isTrue);
    });

    test('AUTH-T1-05: Sign out successfully revokes active session', () async {
      // First sign in
      final user = await authService.signIn('household@homeease.com', 'password123', 'Household');
      expect(user, isNotNull);
      expect(authService.currentUser, isNotNull);
      expect(authService.isAuthenticated, isTrue);

      // Sign out
      await authService.signOut();
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);
    });
  });

  // ===========================================================================
  // TIER 2: BOUNDARY, CORNER & ADVERSARIAL CASES (>=5 tests)
  // ===========================================================================
  group('Tier 2: Authentication & RBAC - Boundary & Corner Cases', () {
    test('AUTH-T2-01: Case-insensitive email normalization on sign-in', () async {
      // Uppercase email variant
      final user = await authService.signIn(
        'HOUSEHOLD@HOMEEASE.COM',
        'password123',
        'Household',
      );

      expect(user, isNotNull);
      expect(user?.email, 'household@homeease.com');
    });

    test('AUTH-T2-02: Whitespace trimming on email input prevents login failure', () async {
      final user = await authService.signIn(
        '   worker@homeease.com   ',
        'password123',
        'Worker',
      );

      expect(user, isNotNull);
      expect(user?.fullName, 'Rabia Bibi');
    });

    test('AUTH-T2-03: Incorrect password returns null and does not mutate session', () async {
      final user = await authService.signIn(
        'household@homeease.com',
        'wrongPassword999',
        'Household',
      );

      expect(user, isNull);
      expect(authService.currentUser, isNull);
    });

    test('AUTH-T2-04: Role mismatch rejects sign-in even with valid email and password', () async {
      // Household credentials used with 'Worker' role
      final user = await authService.signIn(
        'household@homeease.com',
        'password123',
        'Worker',
      );

      expect(user, isNull);
      expect(authService.currentUser, isNull);
    });

    test('AUTH-T2-05: Non-existent email returns null cleanly without unhandled exception', () async {
      final user = await authService.signIn(
        'nonexistent.user.999@homeease.pk',
        'anyPassword123',
        'Household',
      );

      expect(user, isNull);
      expect(authService.currentUser, isNull);
    });

    test('AUTH-T2-06: Registration and authentication with complex passwords and symbols', () async {
      const complexPass = r'P@ssw0rd!#$%^&*()_+=~`{}[]:;<>,.?/|';
      final newUser = await authService.signUp(
        name: 'Special Char User',
        email: 'special.chars@homeease.com',
        phone: '+923331112233',
        password: complexPass,
        role: 'Household',
      );

      expect(newUser.password, complexPass);

      await authService.signOut();
      final loggedIn = await authService.signIn(
        'special.chars@homeease.com',
        complexPass,
        'Household',
      );

      expect(loggedIn, isNotNull);
      expect(loggedIn?.fullName, 'Special Char User');
    });
  });

  // ===========================================================================
  // TIER 3: PAIRWISE COMBINATORIAL TESTING
  // ===========================================================================
  group('Tier 3: Authentication - Pairwise Combinations (Roles x Domains x Phones)', () {
    final roles = ['Household', 'Worker'];
    final domainSuffixes = ['@homeease.com', '@ciit.net.pk', '@ayub.edu.pk'];
    final phonePrefixes = ['+92300', '+92311', '+92345'];

    for (final role in roles) {
      for (int i = 0; i < domainSuffixes.length; i++) {
        final domain = domainSuffixes[i];
        final phone = '${phonePrefixes[i]}998877';
        final testEmail = 'pairwise_${role.toLowerCase()}_$i$domain';

        test('AUTH-T3: Pairwise registration and auth for $role with domain $domain', () async {
          final registered = await authService.signUp(
            name: 'Pairwise User $role $i',
            email: testEmail,
            phone: phone,
            password: 'PairwisePass123!',
            role: role,
          );

          expect(registered.role, role);
          expect(registered.email, testEmail);

          await authService.signOut();
          final authenticated = await authService.signIn(
            testEmail,
            'PairwisePass123!',
            role,
          );

          expect(authenticated, isNotNull);
          expect(authenticated?.role, role);
        });
      }
    }
  });

  // ===========================================================================
  // TIER 4: REAL-WORLD SCENARIOS / E2E USER JOURNEYS
  // ===========================================================================
  group('Tier 4: Authentication - Real-World End-to-End User Journeys', () {
    test('AUTH-T4-01: Multi-role lifecycle: Household register -> Sign out -> Worker register -> Re-login', () async {
      // 1. Household user signs up
      final household = await authService.signUp(
        name: 'Fatima Zahra',
        email: 'fatima.zahra@mandian.pk',
        phone: '+923005544332',
        password: 'FatimaPassword2026',
        role: 'Household',
      );
      expect(authService.currentUser?.id, household.id);
      expect(authService.currentUser?.role, 'Household');

      // 2. Household signs out
      await authService.signOut();
      expect(authService.currentUser, isNull);

      // 3. Worker signs up on same device
      final worker = await authService.signUp(
        name: 'Gul Zaman Plumber',
        email: 'gul.zaman@abbottabad.pk',
        phone: '+923336677889',
        password: 'PlumberPassword2026',
        role: 'Worker',
        tradeData: {
          'category': 'Plumber',
          'experience': '8 years',
          'rate': 'PKR 1500 / visit',
          'bio': 'Expert plumber in Abbottabad',
        },
      );
      expect(authService.currentUser?.id, worker.id);
      expect(authService.currentUser?.role, 'Worker');

      // 4. Worker signs out
      await authService.signOut();
      expect(authService.currentUser, isNull);

      // 5. Original household re-authenticates and recovers session
      final restoredHousehold = await authService.signIn(
        'fatima.zahra@mandian.pk',
        'FatimaPassword2026',
        'Household',
      );
      expect(restoredHousehold, isNotNull);
      expect(restoredHousehold?.id, household.id);
      expect(restoredHousehold?.fullName, 'Fatima Zahra');
      expect(authService.currentUser?.id, household.id);
    });

    test('AUTH-T4-02: Demo accounts availability for rapid evaluation without manual signup', () async {
      final demoAccounts = authService.getDemoAccounts();

      expect(demoAccounts.length, greaterThanOrEqualTo(2));
      final householdDemo = demoAccounts.firstWhere((u) => u.role == 'Household');
      final workerDemo = demoAccounts.firstWhere((u) => u.role == 'Worker');

      expect(householdDemo.email, 'household@homeease.com');
      expect(workerDemo.email, 'worker@homeease.com');

      // Verify immediate login with demo accounts
      final loggedInDemo = await authService.signIn(
        householdDemo.email,
        householdDemo.password,
        householdDemo.role,
      );
      expect(loggedInDemo, isNotNull);
      expect(loggedInDemo?.fullName, 'Babar Khan');
    });
  });

  // ===========================================================================
  // TIER 5: SUPABASE CLIENT CONFIGURATION & CONTRACT VERIFICATION
  // ===========================================================================
  group('Tier 5: Supabase Configuration & Contract Verification', () {
    test('AUTH-T5-01: SupabaseConfig contains valid project URL and Anon JWT', () {
      expect(SupabaseConfig.url, startsWith('https://'));
      expect(SupabaseConfig.url, contains('supabase.co'));
      expect(SupabaseConfig.anonKey, isNotEmpty);
      expect(SupabaseConfig.anonKey.split('.').length, 3); // Valid JWT structure
    });

    test('AUTH-T5-02: SupabaseAuthService singleton preserves identity across callers', () {
      final instance1 = SupabaseAuthService();
      final instance2 = SupabaseAuthService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('AUTH-T5-03: Session restore returns null when no user session exists', () async {
      await authService.signOut();
      final restored = await authService.restoreSession();
      expect(restored, isNull);
    });
  });
}
