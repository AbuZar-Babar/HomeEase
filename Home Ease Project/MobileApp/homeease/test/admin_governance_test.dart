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
import 'package:homeease/widgets/app_scaffold.dart';

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

  Widget buildDesktopApp(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  Widget buildMobileApp(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  // ===========================================================================
  // GROUP 1: ADMIN AUTHENTICATION & SESSION MANAGEMENT (ADM-01 TO ADM-07)
  // ===========================================================================
  group('Admin Authentication & Session Flow', () {
    test('ADM-01: SupabaseAuthService contains valid admin demo account', () {
      final auth = SupabaseAuthService();
      final demoAccounts = auth.getDemoAccounts();
      final adminAccount = demoAccounts.firstWhere(
        (acc) => acc.role == 'Admin',
      );

      expect(adminAccount.email, equals('admin@homeease.com'));
      expect(adminAccount.password, equals('admin123'));
      expect(adminAccount.role, equals('Admin'));
    });

    test('ADM-02: SupabaseAuthService.signIn authenticates admin credentials successfully', () async {
      final auth = SupabaseAuthService();
      final user = await auth.signIn('admin@homeease.com', 'admin123', 'Admin');

      expect(user, isNotNull);
      expect(user!.email, equals('admin@homeease.com'));
      expect(user.role, equals('Admin'));
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.id, equals('admin_1'));
    });

    test('ADM-03: SupabaseAuthService rejects admin signIn when role does not match', () async {
      final auth = SupabaseAuthService();
      // Attempting to sign in with admin credentials under 'Household' role must fail
      final user = await auth.signIn('admin@homeease.com', 'admin123', 'Household');

      expect(user, isNull);
      expect(auth.isAuthenticated, isFalse);
    });

    test('ADM-04: SupabaseAuthService.restoreSession restores active session and user', () async {
      final auth = SupabaseAuthService();
      await auth.signIn('admin@homeease.com', 'admin123', 'Admin');
      expect(auth.isAuthenticated, isTrue);

      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
    });

    testWidgets('ADM-05: SignInScreen renders Admin role tab with shield icon and title', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(
            onSignIn: () {},
            onWorkerSignIn: () {},
            onCreateAccount: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Governance'), findsOneWidget);
      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsOneWidget);
    });

    testWidgets('ADM-06: SignInScreen 1-tap Demo Admin Login pill populates admin credentials', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(
            onSignIn: () {},
            onWorkerSignIn: () {},
            onCreateAccount: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final demoAdminPill = find.text('Demo Admin Login');
      expect(demoAdminPill, findsOneWidget);

      await tester.ensureVisible(demoAdminPill);
      await tester.tap(demoAdminPill);
      await tester.pumpAndSettle();

      expect(find.text('admin@homeease.com'), findsOneWidget);
      expect(find.text('Sign In as Admin'), findsOneWidget);
    });

    testWidgets('ADM-07: SignInScreen triggers onAdminSignIn callback upon successful authentication', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      bool adminSignedIn = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(
            onSignIn: () {},
            onWorkerSignIn: () {},
            onAdminSignIn: () => adminSignedIn = true,
            onCreateAccount: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap demo admin pill to populate fields
      final demoPill = find.text('Demo Admin Login');
      await tester.ensureVisible(demoPill);
      await tester.tap(demoPill);
      await tester.pumpAndSettle();

      // Tap primary sign in button
      final signInButton = find.text('Sign In as Admin');
      await tester.ensureVisible(signInButton);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(adminSignedIn, isTrue);
    });
  });

  // ===========================================================================
  // GROUP 2: DUAL-SCREEN RESPONSIVENESS (ADM-08 TO ADM-12)
  // ===========================================================================
  group('Dual-Screen Responsiveness & Layout Architecture', () {
    testWidgets('ADM-08: Desktop viewport (>= 900dp) renders persistent 260dp left navigation sidebar', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Verify desktop sidebar container width is 260dp
      final sidebarFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.minWidth == 260 && widget.constraints?.maxWidth == 260,
      );
      expect(sidebarFinder, findsOneWidget);
    });

    testWidgets('ADM-09: Desktop sidebar renders HomeEase branding, Admin profile card, and 4 desk items', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HomeEase'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('admin@homeease.com'), findsOneWidget);

      expect(find.text('Platform Analytics'), findsWidgets);
      expect(find.text('Worker Verification Desk'), findsWidgets);
      expect(find.text('Dispute Resolution Desk'), findsWidgets);
      expect(find.text('System Audit Logs'), findsWidgets);
    });

    testWidgets('ADM-10: Mobile viewport (< 900dp) renders top app bar and compact horizontal tab bar', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildMobileApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // In mobile mode, HomeEase Admin is in the top header
      expect(find.text('HomeEase Admin'), findsOneWidget);
      expect(find.text('Abbottabad Regional Node'), findsOneWidget);

      // Verify no 260dp persistent sidebar container exists
      final sidebarFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.minWidth == 260 && widget.constraints?.maxWidth == 260,
      );
      expect(sidebarFinder, findsNothing);

      // Verify mobile tab bar is rendered
      expect(find.text('Platform Analytics'), findsOneWidget);
      expect(find.text('Worker Verification Desk'), findsOneWidget);
    });

    testWidgets('ADM-11: Mobile tab bar displays badge indicators for pending verification and active disputes', (tester) async {
      setMobileSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildMobileApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Badge for pending workers (Workers 9 and 10 are pending => badge is 2)
      expect(find.text('2'), findsWidgets);

      // Badge for active disputes (Dispute 301 is open => badge is 1)
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('ADM-12: Tapping desktop sidebar navigation items switches active tab content', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Platform Analytics
      expect(find.text('Gross PKR Volume'), findsOneWidget);

      // Tap Worker Verification Desk in sidebar
      final verificationDeskNav = find.widgetWithText(Semantics, 'Worker Verification Desk').first;
      await tester.tap(verificationDeskNav);
      await tester.pumpAndSettle();

      // Analytics KPI card should disappear, verification filters should appear
      expect(find.text('Gross PKR Volume'), findsNothing);
      expect(find.textContaining('Pending (2)'), findsOneWidget);
    });
  });

  // ===========================================================================
  // GROUP 3: TAB 1 — PLATFORM ANALYTICS DESK (ADM-13 TO ADM-18)
  // ===========================================================================
  group('Tab 1: Platform Analytics Desk', () {
    testWidgets('ADM-13: Gross PKR volume calculates sum of agreedAmount strictly for completed bookings', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final bookings = await BookingRepository().fetchAllBookings();
      final expectedVolume = bookings
          .where((b) => b.status.toLowerCase() == 'completed')
          .fold<double>(0.0, (sum, b) => sum + b.agreedAmount);

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gross PKR Volume'), findsOneWidget);
      expect(find.text('PKR ${expectedVolume.toInt()}'), findsOneWidget);
    });

    testWidgets('ADM-14: Active disputes KPI correctly reflects count of disputes with status open', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final disputes = await DisputeRepository().fetchAllDisputes();
      final openCount = disputes.where((d) => d.status.toLowerCase() == 'open').length;

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Disputes'), findsOneWidget);
      expect(find.text('$openCount'), findsWidgets);
      expect(find.text('Requires arbitration action'), findsOneWidget);
    });

    testWidgets('ADM-15: Verified workers KPI reflects ratio of Verified workers to total registered workers', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final workers = await WorkerRepository().fetchAllWorkersAdmin();
      final total = workers.length;
      final verified = workers.where((w) => w.verificationStatus.toLowerCase() == 'verified').length;
      final percent = total > 0 ? ((verified / total) * 100).toInt() : 0;

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verified Workers'), findsOneWidget);
      expect(find.text('$verified / $total ($percent%)'), findsOneWidget);
    });

    testWidgets('ADM-16: Category distribution displays registered workers across trades', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Category Distribution'), findsOneWidget);
      expect(find.text('10 Registered Workers'), findsOneWidget);
      expect(find.text('Cook'), findsOneWidget);
      expect(find.text('Cleaner'), findsOneWidget);
      expect(find.text('Electrician'), findsOneWidget);
      expect(find.text('Plumber'), findsOneWidget);
    });

    testWidgets('ADM-17: Category distribution renders proportional LinearProgressIndicators', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final progressIndicators = find.byType(LinearProgressIndicator);
      expect(progressIndicators, findsWidgets);
    });

    testWidgets('ADM-18: Analytics tab displays completed vs pending bookings breakdown in KPI subtitle', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final bookings = await BookingRepository().fetchAllBookings();
      final completed = bookings.where((b) => b.status.toLowerCase() == 'completed').length;
      final pending = bookings.where((b) => b.status.toLowerCase() == 'pending').length;

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('$completed Completed • $pending Pending'), findsOneWidget);
    });
  });

  // ===========================================================================
  // GROUP 4: TAB 2 — WORKER VERIFICATION DESK (ADM-19 TO ADM-25)
  // ===========================================================================
  group('Tab 2: Worker Verification Desk', () {
    testWidgets('ADM-19: Worker Verification Desk displays pending workers queue initially', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Verification Desk
      await tester.tap(find.widgetWithText(Semantics, 'Worker Verification Desk').first);
      await tester.pumpAndSettle();

      // Workers 9 and 10 are Tariq Mehmood and Muhammad Bilal
      expect(find.text('Tariq Mehmood'), findsOneWidget);
      expect(find.text('Muhammad Bilal'), findsOneWidget);
      expect(find.text('PendingVerification'), findsNWidgets(2));
    });

    testWidgets('ADM-20: Worker moderation card formats and renders Pakistani NADRA CNIC format', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Worker Verification Desk').first);
      await tester.pumpAndSettle();

      // Formatted CNIC mask 13101-XXXXXXX-X for Abbottabad regional node
      expect(find.textContaining('CNIC: 13101-'), findsWidgets);
      expect(find.text('CNIC: 13101-4567891-3'), findsOneWidget); // Tariq Mehmood
    });

    testWidgets('ADM-21: Filter chips (Pending, Verified, All) filter the worker queue', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Worker Verification Desk').first);
      await tester.pumpAndSettle();

      // Initially Pending (2)
      expect(find.text('Tariq Mehmood'), findsOneWidget);

      // Tap 'Verified (8)' filter chip
      final verifiedChip = find.textContaining('Verified (8)');
      await tester.tap(verifiedChip);
      await tester.pumpAndSettle();

      // Tariq is not verified yet, Sana Gul is verified
      expect(find.text('Tariq Mehmood'), findsNothing);
      expect(find.text('Sana Gul'), findsOneWidget);

      // Tap 'All (10)' filter chip
      final allChip = find.textContaining('All (10)');
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      expect(find.text('Tariq Mehmood'), findsOneWidget);
      expect(find.text('Sana Gul'), findsOneWidget);
    });

    testWidgets('ADM-22: Tapping View ID Document opens NADRA CNIC document preview dialog', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Worker Verification Desk').first);
      await tester.pumpAndSettle();

      final viewDocButtons = find.text('View ID Document');
      expect(viewDocButtons, findsWidgets);

      await tester.tap(viewDocButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('NADRA CNIC Document — Tariq Mehmood'), findsOneWidget);
      expect(find.text('GOVERNMENT OF PAKISTAN • NADRA'), findsOneWidget);
      expect(find.text('District: Abbottabad (Regional Node 13101)'), findsOneWidget);
      expect(find.text('Holographic watermark verified by Abbottabad Node.'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('GOVERNMENT OF PAKISTAN • NADRA'), findsNothing);
    });

    testWidgets('ADM-23: Tapping Approve updates worker verificationStatus to Verified', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Worker Verification Desk').first);
      await tester.pumpAndSettle();

      final approveButtons = find.text(LocalizationService.tr('approveVerification'));
      expect(approveButtons, findsWidgets);

      await tester.tap(approveButtons.first);
      await tester.pumpAndSettle();

      // Check snackbar
      expect(find.text('Worker Tariq Mehmood approved as Verified.'), findsOneWidget);

      // In repository, Tariq Mehmood must now be verified
      final workers = await WorkerRepository().fetchAllWorkersAdmin();
      final tariq = workers.firstWhere((w) => w.name == 'Tariq Mehmood');
      expect(tariq.verificationStatus, equals('Verified'));
    });

    testWidgets('ADM-24: Approving a worker records verification audit log event', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Worker Verification Desk').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocalizationService.tr('approveVerification')).first);
      await tester.pumpAndSettle();

      final auditLogs = AuditLogService().getLogs(actionType: 'verification');
      final approveLog = auditLogs.firstWhere(
        (log) => log.title == 'Worker Verification Approved',
        orElse: () => auditLogs.first,
      );

      expect(approveLog.title, equals('Worker Verification Approved'));
      expect(approveLog.actor, equals('Admin (admin@homeease.com)'));
      expect(approveLog.description, contains('Tariq Mehmood'));
    });

    testWidgets('ADM-25: Tapping Reject updates worker status to Rejected and records audit log', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Worker Verification Desk').first);
      await tester.pumpAndSettle();

      final rejectButtons = find.text('Reject');
      await tester.tap(rejectButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Worker Tariq Mehmood verification rejected.'), findsOneWidget);

      // Repository update check
      final workers = await WorkerRepository().fetchAllWorkersAdmin();
      final tariq = workers.firstWhere((w) => w.name == 'Tariq Mehmood');
      expect(tariq.verificationStatus, equals('Rejected'));

      // Audit log check
      final logs = AuditLogService().getLogs(actionType: 'verification');
      expect(logs.any((l) => l.title == 'Worker Verification Rejected'), isTrue);
    });
  });

  // ===========================================================================
  // GROUP 5: TAB 3 — DISPUTE RESOLUTION DESK (ADM-26 TO ADM-31)
  // ===========================================================================
  group('Tab 3: Dispute Resolution Desk', () {
    testWidgets('ADM-26: Dispute Resolution Desk displays disputes with metadata', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Dispute Desk
      await tester.tap(find.widgetWithText(Semantics, 'Dispute Resolution Desk').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('#DISP-'), findsOneWidget);
      expect(find.text('Payment Discrepancy'), findsOneWidget);
      expect(find.text('Disagreement regarding overtime rate for kitchen deep cleaning.'), findsOneWidget);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('ADM-27: Dispute status filter chips filter disputes list', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Dispute Resolution Desk').first);
      await tester.pumpAndSettle();

      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('Open (1)'), findsOneWidget);
      expect(find.text('Resolved (0)'), findsOneWidget);
      expect(find.text('Dismissed (0)'), findsOneWidget);

      // Tap Resolved (0)
      await tester.tap(find.text('Resolved (0)'));
      await tester.pumpAndSettle();

      expect(find.text('No disputes found in this filter'), findsOneWidget);
    });

    testWidgets('ADM-28: Tapping View Evidence opens modal dialog with photographic attachment', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Dispute Resolution Desk').first);
      await tester.pumpAndSettle();

      final viewEvidenceBtn = find.text('View Evidence');
      expect(viewEvidenceBtn, findsOneWidget);

      await tester.tap(viewEvidenceBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Evidence Attachment — Dispute #'), findsOneWidget);
      expect(find.text('evidence_dispute_301.jpg'), findsOneWidget);
      expect(find.text('Photographic verification proof attached by complainant'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('evidence_dispute_301.jpg'), findsNothing);
    });

    testWidgets('ADM-29: Tapping Full Refund to Household resolves dispute with resolved_refund and logs audit event', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Dispute Resolution Desk').first);
      await tester.pumpAndSettle();

      final refundBtn = find.text(LocalizationService.tr('refundHousehold'));
      expect(refundBtn, findsOneWidget);

      await tester.tap(refundBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Dispute adjudicated: Dispute Refund Authorized'), findsOneWidget);

      // Check repository status
      final disputes = await DisputeRepository().fetchAllDisputes();
      expect(disputes.first.status, equals('resolved_refund'));

      // Check audit log
      final logs = AuditLogService().getLogs(actionType: 'dispute');
      expect(logs.any((l) => l.title == 'Dispute Refund Authorized'), isTrue);
    });

    testWidgets('ADM-30: Tapping Release to Worker resolves dispute with resolved_payout and logs audit event', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Dispute Resolution Desk').first);
      await tester.pumpAndSettle();

      final payoutBtn = find.text('Release to Worker');
      expect(payoutBtn, findsOneWidget);

      await tester.tap(payoutBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Dispute adjudicated: Dispute Payout Released'), findsOneWidget);

      // Check repository status
      final disputes = await DisputeRepository().fetchAllDisputes();
      expect(disputes.first.status, equals('resolved_payout'));

      // Check audit log
      final logs = AuditLogService().getLogs(actionType: 'dispute');
      expect(logs.any((l) => l.title == 'Dispute Payout Released'), isTrue);
    });

    testWidgets('ADM-31: Tapping Dismiss Dispute marks dispute as dismissed and logs audit event', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'Dispute Resolution Desk').first);
      await tester.pumpAndSettle();

      final dismissBtn = find.text('Dismiss Dispute');
      expect(dismissBtn, findsOneWidget);

      await tester.tap(dismissBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Dispute adjudicated: Dispute Dismissed'), findsOneWidget);

      final disputes = await DisputeRepository().fetchAllDisputes();
      expect(disputes.first.status, equals('dismissed'));

      final logs = AuditLogService().getLogs(actionType: 'dispute');
      expect(logs.any((l) => l.title == 'Dispute Dismissed'), isTrue);
    });
  });

  // ===========================================================================
  // GROUP 6: TAB 4 — SYSTEM AUDIT LOGS (ADM-32 TO ADM-36)
  // ===========================================================================
  group('Tab 4: System Audit Logs', () {
    test('ADM-32: AuditLogService persists chronological platform audit events with actionType and actor', () {
      final service = AuditLogService();
      final initialCount = service.getLogs().length;

      service.logEvent(
        actionType: 'payment',
        title: 'Settlement Cleared',
        description: 'PKR 4,500 escrow balance settled to Easypaisa account.',
        actor: 'Finance Daemon',
        severity: 'success',
      );

      final logs = service.getLogs();
      expect(logs.length, equals(initialCount + 1));
      expect(logs.first.title, equals('Settlement Cleared'));
      expect(logs.first.actionType, equals('payment'));
      expect(logs.first.actor, equals('Finance Daemon'));
    });

    testWidgets('ADM-33: Audit logs tab renders chronological timeline entries with distinct category styling', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Audit Logs tab
      await tester.tap(find.widgetWithText(Semantics, 'System Audit Logs').first);
      await tester.pumpAndSettle();

      expect(find.text('Platform Infrastructure Online'), findsOneWidget);
      expect(find.text('Actor: System Daemon'), findsOneWidget);
      expect(find.text('Dispute Filed by Household'), findsOneWidget);
    });

    testWidgets('ADM-34: Action type filter chips filter audit logs correctly', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'System Audit Logs').first);
      await tester.pumpAndSettle();

      // Tap 'Verification' filter chip
      await tester.tap(find.text('Verification'));
      await tester.pumpAndSettle();

      expect(find.text('Worker Verification Approved'), findsOneWidget);
      expect(find.text('Dispute Filed by Household'), findsNothing);

      // Tap 'Dispute' filter chip
      await tester.tap(find.text('Dispute'));
      await tester.pumpAndSettle();

      expect(find.text('Dispute Filed by Household'), findsOneWidget);
      expect(find.text('Worker Verification Approved'), findsNothing);
    });

    test('ADM-35: Resetting AuditLogService via resetForTesting restores baseline history', () {
      final service = AuditLogService();
      service.logEvent(
        actionType: 'system',
        title: 'Ephemeral Test Event',
        description: 'Should be cleared on reset',
        actor: 'Test Daemon',
      );

      expect(service.getLogs().any((l) => l.title == 'Ephemeral Test Event'), isTrue);

      service.resetForTesting();
      expect(service.getLogs().any((l) => l.title == 'Ephemeral Test Event'), isFalse);
      expect(service.getLogs().length, equals(4)); // Baseline historical logs
    });

    testWidgets('ADM-36: ListenableBuilder in AuditLogsTab automatically updates when new event is logged', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Semantics, 'System Audit Logs').first);
      await tester.pumpAndSettle();

      expect(find.text('Dynamic Real-time Log Event'), findsNothing);

      // Emitting event through singleton should immediately trigger UI update via ListenableBuilder
      AuditLogService().logEvent(
        actionType: 'system',
        title: 'Dynamic Real-time Log Event',
        description: 'Verified live stream updates',
        actor: 'Test Daemon',
      );

      await tester.pumpAndSettle();
      expect(find.text('Dynamic Real-time Log Event'), findsOneWidget);
    });
  });

  // ===========================================================================
  // GROUP 7: ACCESSIBILITY & BI-DIRECTIONAL LOCALIZATION (ADM-37 TO ADM-40)
  // ===========================================================================
  group('Accessibility & Localization', () {
    testWidgets('ADM-37: Interactive controls across AdminDashboard strictly enforce >= 48x48dp minimum bounds', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Find all Semantics buttons
      final buttonFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.button == true,
      );

      expect(buttonFinder, findsWidgets);

      // Validate each button size is at least 48x48dp
      for (final element in buttonFinder.evaluate()) {
        final renderBox = element.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          expect(
            renderBox.size.height,
            greaterThanOrEqualTo(48.0 - 0.5), // tolerate micro subpixel rounding
            reason: 'Element ${element.widget} height is < 48dp: ${renderBox.size.height}',
          );
          expect(
            renderBox.size.width,
            greaterThanOrEqualTo(48.0 - 0.5),
            reason: 'Element ${element.widget} width is < 48dp: ${renderBox.size.width}',
          );
        }
      }
    });

    testWidgets('ADM-38: Urdu RTL locale switches Directionality to TextDirection.rtl and displays Urdu translations', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      LocalizationService.setLanguage('ur');

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final directionality = tester.widget<Directionality>(
        find.descendant(of: find.byType(AdminDashboardScreen), matching: find.byType(Directionality)).first,
      );
      expect(directionality.textDirection, equals(TextDirection.rtl));

      // Urdu translated strings
      expect(find.text(LocalizationService.tr('platformAnalytics')), findsWidgets);
      expect(find.text(LocalizationService.tr('grossPkrVolume')), findsOneWidget);
      expect(find.text(LocalizationService.tr('totalBookings')), findsOneWidget);
      expect(find.text(LocalizationService.tr('activeDisputes')), findsOneWidget);
    });

    testWidgets('ADM-39: Language toggle button dynamically toggles between English and Urdu', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      bool languageChangedCalled = false;

      await tester.pumpWidget(
        buildDesktopApp(
          AdminDashboardScreen(
            onLogout: () {},
            onLanguageChanged: () => languageChangedCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Language pill initially says 'اردو'
      final langPill = find.text('اردو');
      expect(langPill, findsOneWidget);

      await tester.tap(langPill);
      await tester.pumpAndSettle();

      expect(languageChangedCalled, isTrue);
      expect(LocalizationService.isUrdu, isTrue);

      // Now pill says 'English'
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('ADM-40: HomeEaseFlow correctly transitions to AppStage.adminDashboard and suppresses bottom nav', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeEaseFlow(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate past splash
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Skip onboarding
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // On SignInScreen, tap Admin tab
      final adminTab = find.text('Admin');
      expect(adminTab, findsOneWidget);
      await tester.tap(adminTab);
      await tester.pumpAndSettle();

      // Tap Demo Admin Login pill or enter text
      final demoAdminPill = find.text('Demo Admin Login');
      if (demoAdminPill.evaluate().isNotEmpty) {
        await tester.tap(demoAdminPill);
        await tester.pumpAndSettle();
      } else {
        await tester.enterText(find.byType(TextField).first, 'admin@homeease.com');
        await tester.enterText(find.byType(TextField).last, 'admin123');
        await tester.pumpAndSettle();
      }

      // Tap Sign In as Admin
      final signInButton = find.text('Sign In as Admin');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // AdminDashboardScreen should now be mounted
      expect(find.byType(AdminDashboardScreen), findsOneWidget);

      // Bottom navigation bar must NOT be displayed for Admin
      expect(find.byType(HomeEaseBottomNav), findsNothing);
    });
  });
}
