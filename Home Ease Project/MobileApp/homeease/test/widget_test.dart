// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:homeease/app/home_ease_app.dart';

void main() {
  testWidgets('shows HomeEase splash screen and transitions to login', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HomeEaseApp());

    // Verify that the splash screen shows logo / title / subtitle elements
    expect(find.text('H'), findsOneWidget);
    expect(find.text('HomeEase'), findsOneWidget);
    expect(
      find.text('Trusted home services, right around your area.'),
      findsOneWidget,
    );

    // Wait for the animation to complete, then for the hold delay to elapse
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Verify that we transitioned to the onboarding screen
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Hyper-Local Search'), findsOneWidget);

    // Tap Skip to navigate to Sign In
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify that we transitioned to the login screen
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue as'), findsOneWidget);
  });
}
