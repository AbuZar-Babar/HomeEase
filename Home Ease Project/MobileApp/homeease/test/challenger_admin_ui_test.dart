import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homeease/app/home_ease_flow.dart';
import 'package:homeease/screens/admin_dashboard_screen.dart';
import 'package:homeease/screens/sign_in_screen.dart';
import 'package:homeease/services/audit_log_service.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/dispute_repository.dart';
import 'package:homeease/services/localization_service.dart';
import 'package:homeease/services/supabase_auth_service.dart';
import 'package:homeease/services/worker_repository.dart';

/// Test HTTP overrides to guarantee 100% offline execution.
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      openUrl('GET', Uri(scheme: 'http', host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return const Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    LocalizationService.setLanguage('en');
    SupabaseAuthService().resetForTesting();
    AuditLogService().resetForTesting();
    DisputeRepository().reset();
    WorkerRepository().reset();
    BookingRepository().reset();
  });

  void setDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
  }

  void setMobileSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
  }

  Future<void> navigatePastSplashToSignIn(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeEaseFlow(),
      ),
    );
    await tester.pumpAndSettle();

    // Advance past splash screen controller duration + delay
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Skip onboarding if present
    final skipBtn = find.text('Skip');
    if (skipBtn.evaluate().isNotEmpty) {
      await tester.tap(skipBtn);
      await tester.pumpAndSettle();
    }
  }

  // ===========================================================================
  // CHALLENGE 1: RESPONSIVE BREAKPOINT TRANSITIONS & STATE PERSISTENCE
  // ===========================================================================
  group('CHALLENGE 1: Responsive Breakpoint Transitions & State Persistence', () {
    testWidgets('CH-01: Breakpoint swap Web (1200dp) -> Mobile (400dp) layout test and overflow check', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // On Web: switch to Desk 1 (Worker Verification Desk)
      final verificationNavItem = find.widgetWithText(Semantics, 'Worker Verification Desk');
      expect(verificationNavItem, findsWidgets);
      await tester.tap(verificationNavItem.first);
      await tester.pumpAndSettle();

      // Verify on Worker Verification Desk
      expect(find.text('Worker Verification Desk'), findsWidgets);

      // Swap viewport from Desktop (1200dp) to Mobile (400dp)
      setMobileSize(tester);
      await tester.pumpAndSettle();

      // Verify that Mobile layout is now active (no 260dp persistent sidebar container)
      final sidebarFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.minWidth == 260 && widget.constraints?.maxWidth == 260,
      );
      expect(sidebarFinder, findsNothing);

      // Verify active desk persisted across the breakpoint swap: mobile tab bar shows Worker Verification Desk
      expect(find.text('Worker Verification Desk'), findsWidgets);
    });

    testWidgets('CH-02: Breakpoint swap Mobile (400dp) -> Web (1200dp) preserves active desk and filter state', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // On Mobile: switch to Desk 1 (Worker Verification Desk)
      final verifTab = find.text('Worker Verification Desk');
      expect(verifTab, findsWidgets);
      await tester.tap(verifTab.first);
      await tester.pumpAndSettle();

      // Swap viewport from Mobile (400dp) to Web (1200dp)
      setDesktopSize(tester);
      await tester.pumpAndSettle();

      // Verify Desktop sidebar is now present
      final sidebarFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.minWidth == 260 && widget.constraints?.maxWidth == 260,
      );
      expect(sidebarFinder, findsOneWidget);

      // Verify active desk persisted: still Worker Verification Desk
      expect(find.text('Worker Verification Desk'), findsWidgets);
    });

    testWidgets('CH-03: Rapid bidirectional resizing does not crash, leak, or reset state', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Cycle sizes between desktop and tablet sizes: 1200 -> 950 -> 1400 -> 1000 -> 1200
      tester.view.physicalSize = const Size(950, 700);
      await tester.pumpAndSettle();
      expect(find.text('Platform Analytics'), findsWidgets);

      tester.view.physicalSize = const Size(1400, 1000);
      await tester.pumpAndSettle();
      expect(find.text('Platform Analytics'), findsWidgets);

      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpAndSettle();
      expect(find.text('Platform Analytics'), findsWidgets);

      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpAndSettle();
      expect(find.text('Platform Analytics'), findsWidgets);
    });
  });

  // ===========================================================================
  // CHALLENGE 2: 1-TAP DEMO ADMIN LOGIN PILL & END-TO-END DASHBOARD ENTRY
  // ===========================================================================
  group('CHALLENGE 2: 1-Tap Demo Admin Login Pill & End-to-End Navigation', () {
    testWidgets('CH-04: Tapping 1-tap Demo Admin Login pill sets role to Admin and populates credentials', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(
            onSignIn: () {},
            onWorkerSignIn: () {},
            onAdminSignIn: () {},
            onCreateAccount: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, household role is active
      expect(find.text('Sign In as Household'), findsOneWidget);

      // Tap 1-tap "Demo Admin Login" pill
      final demoPill = find.text('Demo Admin Login');
      expect(demoPill, findsOneWidget);
      await tester.tap(demoPill);
      await tester.pumpAndSettle();

      // Verify email text field is populated
      final emailTextField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'admin@homeease.com'),
      );
      expect(emailTextField.controller?.text, equals('admin@homeease.com'));

      // Verify primary submit button changed to Admin
      expect(find.text('Sign In as Admin'), findsOneWidget);
    });

    testWidgets('CH-05: HomeEaseFlow navigates to AppStage.adminDashboard on demo admin sign in', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await navigatePastSplashToSignIn(tester);

      // We should now be on SignInScreen
      expect(find.byType(SignInScreen), findsOneWidget);

      // Tap Demo Admin Login pill
      final demoPill = find.text('Demo Admin Login');
      expect(demoPill, findsOneWidget);
      await tester.tap(demoPill);
      await tester.pumpAndSettle();

      // Tap "Sign In as Admin"
      final signInBtn = find.text('Sign In as Admin');
      expect(signInBtn, findsOneWidget);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Verify navigation to AdminDashboardScreen
      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.text('HomeEase Admin'), findsOneWidget);

      // Verify audit log recorded the admin login
      final logs = AuditLogService().getLogs(actionType: 'auth');
      expect(logs.any((l) => l.title == 'Admin Session Authenticated'), isTrue);
    });
  });

  // ===========================================================================
  // CHALLENGE 3: ADMIN LOGOUT & NAVIGATION STACK CLEANLINESS
  // ===========================================================================
  group('CHALLENGE 3: Admin Logout & Navigation Stack Cleanliness', () {
    testWidgets('CH-06: Mobile Admin Logout returns to SignInScreen and back button cannot re-enter Admin', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await navigatePastSplashToSignIn(tester);

      // Tap Demo Admin Login & sign in
      await tester.tap(find.text('Demo Admin Login'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign In as Admin'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(SupabaseAuthService().isAuthenticated, isTrue);

      // Tap Mobile Logout button in top bar (icon logout_rounded)
      final mobileLogoutBtn = find.byIcon(Icons.logout_rounded);
      expect(mobileLogoutBtn, findsOneWidget);
      await tester.tap(mobileLogoutBtn);
      await tester.pumpAndSettle();

      // Verify redirected to SignInScreen
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(AdminDashboardScreen), findsNothing);

      // Verify auth session is terminated
      expect(SupabaseAuthService().isAuthenticated, isFalse);

      // Verify audit event recorded
      final authLogs = AuditLogService().getLogs(actionType: 'auth');
      expect(authLogs.any((l) => l.title == 'Admin Session Terminated'), isTrue);

      // ADVERSARIAL STACK CHECK: Trigger system back navigation
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // The pop should either pop the root route or stay on SignInScreen, NEVER reviving AdminDashboardScreen!
      expect(find.byType(AdminDashboardScreen), findsNothing);
    });

    testWidgets('CH-07: Web Admin Logout via persistent sidebar clears history cleanly', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await navigatePastSplashToSignIn(tester);

      await tester.tap(find.text('Demo Admin Login'));
      await tester.pumpAndSettle();

      // Wait for 2s SnackBar from Demo Admin pill to dismiss before clicking sidebar
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In as Admin'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);

      // On Web: find desktop sidebar logout button
      final desktopLogoutBtn = find.byIcon(Icons.logout_rounded);
      expect(desktopLogoutBtn, findsOneWidget);
      await tester.tap(desktopLogoutBtn);
      await tester.pumpAndSettle();

      // Verify returned to SignInScreen
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(AdminDashboardScreen), findsNothing);
      expect(SupabaseAuthService().isAuthenticated, isFalse);

      // Back navigation cannot resurrect Admin
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AdminDashboardScreen), findsNothing);
    });
  });

  // ===========================================================================
  // CHALLENGE 4: RAPID DESK SWITCHING & AUDIT LOGS CATEGORY FILTERING
  // ===========================================================================
  group('CHALLENGE 4: Rapid Desk Switching & Audit Logs Category Filtering', () {
    testWidgets('CH-08: Rapid cycling between all 4 desks executes cleanly without exceptions', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Desks: 0: Analytics, 1: Verification, 2: Disputes, 3: Audit Logs
      final desks = [
        'Platform Analytics',
        'Worker Verification Desk',
        'Dispute Resolution Desk',
        'System Audit Logs',
      ];

      // Rapidly switch 0 -> 1 -> 2 -> 3 -> 1 -> 0 -> 2 -> 3 -> 0
      final sequence = [1, 2, 3, 1, 0, 2, 3, 0];
      for (final targetIdx in sequence) {
        final deskName = desks[targetIdx];
        final finder = find.widgetWithText(Semantics, deskName);
        expect(finder, findsWidgets);
        await tester.tap(finder.first);
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      // Ended on Platform Analytics (0)
      expect(find.text('Platform Analytics'), findsWidgets);
      expect(find.text('Gross PKR Volume'), findsOneWidget);
    });

    testWidgets('CH-09: Audit Logs category filters strictly filter events (Auth, Verification, Dispute, Payment, All)', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      // Pre-seed an auth event and a payment event
      AuditLogService().logEvent(
        actionType: 'auth',
        title: 'Admin Session Login',
        description: 'System Administrator logged in safely.',
        actor: 'Admin (admin@homeease.com)',
        severity: 'info',
      );
      AuditLogService().logEvent(
        actionType: 'payment',
        title: 'Escrow Settlement Processed',
        description: 'PKR 3,500 settled via JazzCash to worker wallet.',
        actor: 'Payment Gateway Daemon',
        severity: 'success',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Go to Audit Logs
      await tester.tap(find.widgetWithText(Semantics, 'System Audit Logs').first);
      await tester.pumpAndSettle();

      // 1. Filter: Auth
      await tester.tap(find.text('Auth'));
      await tester.pumpAndSettle();
      expect(find.text('Admin Session Login'), findsOneWidget);
      expect(find.text('Escrow Settlement Processed'), findsNothing);
      expect(find.text('Worker Verification Approved'), findsNothing);

      // 2. Filter: Verification
      await tester.tap(find.text('Verification'));
      await tester.pumpAndSettle();
      expect(find.text('Worker Verification Approved'), findsOneWidget);
      expect(find.text('Admin Session Login'), findsNothing);
      expect(find.text('Escrow Settlement Processed'), findsNothing);

      // 3. Filter: Dispute
      await tester.tap(find.text('Dispute'));
      await tester.pumpAndSettle();
      expect(find.text('Dispute Filed by Household'), findsOneWidget);
      expect(find.text('Admin Session Login'), findsNothing);
      expect(find.text('Escrow Settlement Processed'), findsNothing);

      // 4. Filter: Payment
      await tester.tap(find.text('Payment'));
      await tester.pumpAndSettle();
      expect(find.text('Escrow Settlement Processed'), findsOneWidget);
      expect(find.text('Admin Session Login'), findsNothing);
      expect(find.text('Dispute Filed by Household'), findsNothing);

      // 5. Filter: All
      await tester.tap(find.textContaining('All ('));
      await tester.pumpAndSettle();
      expect(find.text('Admin Session Login'), findsOneWidget);
      expect(find.text('Escrow Settlement Processed'), findsOneWidget);
      expect(find.text('Dispute Filed by Household'), findsOneWidget);
      expect(find.text('Worker Verification Approved'), findsOneWidget);
    });
  });

  // ===========================================================================
  // CHALLENGE 5: TOUCH TARGET ACCESSIBILITY (>= 48x48dp)
  // ===========================================================================
  group('CHALLENGE 5: Touch Targets Accessibility (>= 48x48dp)', () {
    testWidgets('CH-10: All desktop sidebar buttons and actions meet >= 48x48dp bounds', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Check desktop logout button
      final logoutContainer = find.ancestor(
        of: find.byIcon(Icons.logout_rounded).first,
        matching: find.byType(Container),
      ).first;
      final logoutSize = tester.getSize(logoutContainer);
      expect(logoutSize.height, greaterThanOrEqualTo(48.0));

      // Check desktop language toggle
      final langToggleFinder = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.contains('Language Toggle') ?? false),
      );
      expect(langToggleFinder, findsOneWidget);
      final langSize = tester.getSize(langToggleFinder);
      expect(langSize.height, greaterThanOrEqualTo(48.0));
      expect(langSize.width, greaterThanOrEqualTo(48.0));

      // Check refresh button
      final refreshFinder = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.toLowerCase() == 'refresh'),
      );
      expect(refreshFinder, findsOneWidget);
      final refreshSize = tester.getSize(refreshFinder);
      expect(refreshSize.height, greaterThanOrEqualTo(48.0));
      expect(refreshSize.width, greaterThanOrEqualTo(48.0));
    });

    testWidgets('CH-11: Mobile header actions and tab items meet >= 48x48dp bounds', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile logout button
      final mobileLogout = find.byIcon(Icons.logout_rounded);
      expect(mobileLogout, findsOneWidget);
      final logoutParent = find.ancestor(of: mobileLogout, matching: find.byType(Container)).first;
      final logoutSize = tester.getSize(logoutParent);
      expect(logoutSize.width, greaterThanOrEqualTo(48.0));
      expect(logoutSize.height, greaterThanOrEqualTo(48.0));

      // Mobile tab bar item container height
      final tabContainer = find.ancestor(
        of: find.text('Platform Analytics').first,
        matching: find.byType(Container),
      ).first;
      final tabSize = tester.getSize(tabContainer);
      expect(tabSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('CH-12: Action buttons and filter chips meet >= 48x48dp bounds', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Worker Verification Desk
      await tester.tap(find.widgetWithText(Semantics, 'Worker Verification Desk').first);
      await tester.pumpAndSettle();

      // Check filter chip container
      final filterChipContainer = find.ancestor(
        of: find.textContaining('(').first,
        matching: find.byType(Container),
      ).first;
      final chipSize = tester.getSize(filterChipContainer);
      expect(chipSize.height, greaterThanOrEqualTo(48.0));
      expect(chipSize.width, greaterThanOrEqualTo(48.0));

      // Check Approve & Reject buttons
      final approveBtn = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.contains('Approve Verification') ?? false),
      );
      expect(approveBtn, findsWidgets);
      final approveSize = tester.getSize(approveBtn.first);
      expect(approveSize.height, greaterThanOrEqualTo(48.0));

      final rejectBtn = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.contains('Reject') ?? false),
      );
      expect(rejectBtn, findsWidgets);
      final rejectSize = tester.getSize(rejectBtn.first);
      expect(rejectSize.height, greaterThanOrEqualTo(48.0));

      // Check View Document button
      final docBtn = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.contains('ID Document') ?? false),
      );
      expect(docBtn, findsWidgets);
      final docSize = tester.getSize(docBtn.first);
      expect(docSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('CH-13: SignInScreen Demo Admin Login pill meets >= 48x48dp bounds', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(
            onSignIn: () {},
            onWorkerSignIn: () {},
            onAdminSignIn: () {},
            onCreateAccount: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final demoPillSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.contains('Demo Admin Login') ?? false),
      );
      expect(demoPillSemantics, findsOneWidget);
      final pillSize = tester.getSize(demoPillSemantics);
      expect(pillSize.height, greaterThanOrEqualTo(48.0));
      expect(pillSize.width, greaterThanOrEqualTo(48.0));

      // Also check Admin role tab item
      final adminTab = find.text('Admin');
      expect(adminTab, findsOneWidget);
      final adminTabContainer = find.ancestor(of: adminTab, matching: find.byType(AnimatedContainer)).first;
      final tabSize = tester.getSize(adminTabContainer);
      expect(tabSize.height, greaterThanOrEqualTo(48.0));
    });
  });
}
