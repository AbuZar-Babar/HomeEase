import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/service_agreement_screen.dart';
import 'package:homeease/services/localization_service.dart';
import 'package:homeease/widgets/digital_receipt_dialog.dart';
import 'package:homeease/widgets/home_ease_widgets.dart';
import 'package:homeease/widgets/payment_gateway_sheet.dart';

// ============================================================================
// Platform Mocks for Isolated Challenge Testing
// ============================================================================

class ChallengerMockImagePicker extends Fake
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {
  XFile? nextImageToReturn;
  ImageSource? lastSourceRequested;
  int pickCallCount = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions? options,
  }) async {
    lastSourceRequested = source;
    pickCallCount++;
    return nextImageToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testBooking = Booking(
    id: 'bkg_challenger_001',
    householdId: '00000000-0000-0000-0000-000000000001',
    workerId: '00000000-0000-0000-0000-000000000010',
    serviceCategoryId: 'Cleaning',
    bookingDate: DateTime(2026, 10, 22),
    startTime: const TimeOfDay(hour: 10, minute: 0),
    endTime: const TimeOfDay(hour: 13, minute: 0),
    address: 'Supply Bazaar, Abbottabad',
    notes: 'Deep house cleaning',
    agreedAmount: 3200.0,
    status: 'Accepted',
    paymentMethod: 'easypaisa',
    paymentStatus: 'unpaid',
    createdAt: DateTime(2026, 10, 18),
  );

  final testWorker = WorkerProfile(
    id: '00000000-0000-0000-0000-000000000010',
    name: 'Rashid Khan',
    role: 'Domestic Cleaner',
    rating: 4.9,
    rate: 'PKR 900/hr',
    experience: '6 years',
    availability: 'Available',
    location: 'Supply Bazaar, Abbottabad',
    description: 'Expert residential and commercial cleaner',
    highlight: 'Verified',
    bio: 'Expert residential and commercial cleaner',
    experienceYears: 6,
    city: 'Abbottabad',
    area: 'Supply Bazaar',
    availabilityStatus: 'Available',
    verificationStatus: 'Verified',
    averageRating: 4.9,
  );

  Widget buildChallengerHost(
    Widget child, {
    bool isUrdu = false,
    Size size = const Size(800, 1600),
  }) {
    LocalizationService.setLanguage(
      isUrdu ? LocalizationService.langUrdu : LocalizationService.langEnglish,
    );
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  // ==========================================================================
  // Group 1: Rapid Double-Tapping & Idempotency Challenges
  // ==========================================================================
  group('Group 1: Rapid Double-Tapping & Idempotency Challenges', () {
    testWidgets('CH-PAY-01: Rapid double-tap on Easypaisa pay button triggers single dialog & callback', (tester) async {
      int successCallbackCount = 0;
      PaymentResult? lastResult;

      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            simulationDuration: const Duration(milliseconds: 100),
            onPaymentSuccess: (res) {
              successCallbackCount++;
              lastResult = res;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('easypaisa_phone_field')), '03001234567');
      await tester.enterText(find.byKey(const Key('easypaisa_pin_field')), '54321');

      // Dispatch rapid double tap without waiting for animation/dialog settle
      final payBtn = find.byKey(const Key('easypaisa_pay_button'));
      await tester.tap(payBtn);
      await tester.tap(payBtn);
      await tester.pump(); // Show dialog

      // Verify exactly one USSD modal dialog is mounted
      expect(find.text('Easypaisa USSD Push Authorization'), findsOneWidget);

      // Rapidly double tap the dialog authorization button
      final authBtn = find.text('Authorize USSD Push');
      expect(authBtn, findsOneWidget);
      await tester.tap(authBtn);
      await tester.tap(authBtn);
      await tester.pumpAndSettle();

      // Idempotency assertion: exactly 1 callback triggered
      expect(successCallbackCount, equals(1));
      expect(lastResult, isNotNull);
      expect(lastResult!.mode, equals(PaymentMode.easypaisa));
      expect(lastResult!.txId.startsWith('EP-'), isTrue);
    });

    testWidgets('CH-PAY-02: Rapid double-tap on JazzCash pay button triggers single dialog & callback', (tester) async {
      int successCallbackCount = 0;
      PaymentResult? lastResult;

      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.jazzcash,
            simulationDuration: const Duration(milliseconds: 100),
            onPaymentSuccess: (res) {
              successCallbackCount++;
              lastResult = res;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('jazzcash_phone_field')), '03129876543');
      await tester.enterText(find.byKey(const Key('jazzcash_pin_field')), '9876');

      final payBtn = find.byKey(const Key('jazzcash_pay_button'));
      await tester.tap(payBtn);
      await tester.tap(payBtn);
      await tester.pump();

      expect(find.text('Connecting to JazzCash Gateway & Verifying MPIN...'), findsOneWidget);

      final verifyBtn = find.text('Complete Verification');
      await tester.tap(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      expect(successCallbackCount, equals(1));
      expect(lastResult, isNotNull);
      expect(lastResult!.mode, equals(PaymentMode.jazzcash));
      expect(lastResult!.txId.startsWith('JC-'), isTrue);
    });

    testWidgets('CH-PAY-03: Rapid double-tap on Stripe Card pay button maintains single 3DS modal', (tester) async {
      int successCallbackCount = 0;
      PaymentResult? lastResult;

      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.stripe,
            simulationDuration: const Duration(milliseconds: 100),
            onPaymentSuccess: (res) {
              successCallbackCount++;
              lastResult = res;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('stripe_card_field')), '4242424242424242');
      await tester.enterText(find.byKey(const Key('stripe_expiry_field')), '11/29');
      await tester.enterText(find.byKey(const Key('stripe_cvc_field')), '789');

      final payBtn = find.byKey(const Key('stripe_pay_button'));
      await tester.tap(payBtn);
      await tester.tap(payBtn);
      await tester.pump();

      expect(find.text('3D Secure 2.0 Verification'), findsOneWidget);

      final otpBtn = find.text('Authorize OTP');
      await tester.tap(otpBtn);
      await tester.tap(otpBtn);
      await tester.pumpAndSettle();

      expect(successCallbackCount, equals(1));
      expect(lastResult, isNotNull);
      expect(lastResult!.mode, equals(PaymentMode.stripe));
      expect(lastResult!.txId.startsWith('ch_3M'), isTrue);
    });

    testWidgets('CH-PAY-04: Rapid double-tap on COD Pay button dispatches exactly once', (tester) async {
      int successCallbackCount = 0;
      PaymentResult? lastResult;

      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.cod,
            onPaymentSuccess: (res) {
              successCallbackCount++;
              lastResult = res;
            },
          ),
        ),
      );

      // Check acknowledgment
      await tester.tap(find.byKey(const Key('cod_checkbox_tile')));
      await tester.pumpAndSettle();

      // Double-tap pay button in immediate succession
      final payBtn = find.byKey(const Key('cod_pay_button'));
      await tester.tap(payBtn);
      await tester.tap(payBtn);
      await tester.pumpAndSettle();

      expect(successCallbackCount, equals(1));
      expect(lastResult, isNotNull);
      expect(lastResult!.mode, equals(PaymentMode.cod));
      expect(lastResult!.txId.startsWith('COD-'), isTrue);
    });

    testWidgets('CH-PAY-05: Double-tapping PaymentGatewaySheet.show does not crash or double-pop', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      PaymentResult? dialogResult;

      await tester.pumpWidget(
        buildChallengerHost(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                final res = await PaymentGatewaySheet.show(
                  context: ctx,
                  booking: testBooking,
                  worker: testWorker,
                  initialMode: PaymentMode.cod,
                );
                dialogResult = res;
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cod_checkbox_tile')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cod_checkbox_tile')));
      await tester.pumpAndSettle();

      // Rapidly tap COD pay button
      final codBtn = find.byKey(const Key('cod_pay_button'));
      await tester.tap(codBtn);
      await tester.tap(codBtn);
      await tester.pumpAndSettle();

      expect(dialogResult, isNotNull);
      expect(dialogResult!.mode, equals(PaymentMode.cod));
      // Root button is still present in parent route
      expect(find.text('Open Sheet'), findsOneWidget);
    });
  });

  // ==========================================================================
  // Group 2: Modal Lifecycle, Premature Dismissal & Timer Leak Challenges
  // ==========================================================================
  group('Group 2: Modal Lifecycle, Premature Dismissal & Timer Leak Challenges', () {
    testWidgets('CH-TIMER-01: Easypaisa USSD push modal premature dismissal cancels 2s timer without leaks', (tester) async {
      bool successCalled = false;

      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            simulationDuration: const Duration(seconds: 2), // Full 2s duration
            onPaymentSuccess: (_) {
              successCalled = true;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('easypaisa_phone_field')), '03001234567');
      await tester.enterText(find.byKey(const Key('easypaisa_pin_field')), '12345');
      await tester.tap(find.byKey(const Key('easypaisa_pay_button')));
      await tester.pump(); // Dialog opens

      expect(find.text('Easypaisa USSD Push Authorization'), findsOneWidget);

      // Advance time by only 300ms (far before the 2s timer completes)
      await tester.pump(const Duration(milliseconds: 300));

      // Prematurely dismiss the dialog via Navigator pop (simulating back button)
      final dialogElement = tester.element(find.text('Easypaisa USSD Push Authorization'));
      Navigator.of(dialogElement).pop(false);
      await tester.pumpAndSettle();

      // Dialog is gone
      expect(find.text('Easypaisa USSD Push Authorization'), findsNothing);

      // Advance time past the remaining 2s duration to prove the timer was properly cancelled
      await tester.pump(const Duration(seconds: 3));

      // Success callback must NOT have fired
      expect(successCalled, isFalse);

      // Sheet is still active and can be interacted with
      expect(find.byKey(const Key('easypaisa_pay_button')), findsOneWidget);
    });

    testWidgets('CH-TIMER-02: JazzCash processing modal premature dismissal cancels 2s timer cleanly', (tester) async {
      bool successCalled = false;

      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.jazzcash,
            simulationDuration: const Duration(seconds: 2),
            onPaymentSuccess: (_) {
              successCalled = true;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('jazzcash_phone_field')), '03129998877');
      await tester.enterText(find.byKey(const Key('jazzcash_pin_field')), '5555');
      await tester.tap(find.byKey(const Key('jazzcash_pay_button')));
      await tester.pump();

      expect(find.text('Connecting to JazzCash Gateway & Verifying MPIN...'), findsOneWidget);

      // Advance by 400ms then pop prematurely
      await tester.pump(const Duration(milliseconds: 400));
      final dialogElement = tester.element(find.text('Connecting to JazzCash Gateway & Verifying MPIN...'));
      Navigator.of(dialogElement).pop(null);
      await tester.pumpAndSettle();

      expect(find.text('Connecting to JazzCash Gateway & Verifying MPIN...'), findsNothing);

      // Advance past 2s
      await tester.pump(const Duration(seconds: 3));
      expect(successCalled, isFalse);
      expect(find.byKey(const Key('jazzcash_pay_button')), findsOneWidget);
    });

    testWidgets('CH-TIMER-03: Stripe 3DS modal premature dismissal cancels 2s timer without async errors', (tester) async {
      bool successCalled = false;

      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.stripe,
            simulationDuration: const Duration(seconds: 2),
            onPaymentSuccess: (_) {
              successCalled = true;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('stripe_card_field')), '4242424242424242');
      await tester.enterText(find.byKey(const Key('stripe_expiry_field')), '10/28');
      await tester.enterText(find.byKey(const Key('stripe_cvc_field')), '321');
      await tester.tap(find.byKey(const Key('stripe_pay_button')));
      await tester.pump();

      expect(find.text('3D Secure 2.0 Verification'), findsOneWidget);

      // Advance 250ms and dismiss
      await tester.pump(const Duration(milliseconds: 250));
      final dialogElement = tester.element(find.text('3D Secure 2.0 Verification'));
      Navigator.of(dialogElement).pop(false);
      await tester.pumpAndSettle();

      expect(find.text('3D Secure 2.0 Verification'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      expect(successCalled, isFalse);
      expect(find.byKey(const Key('stripe_pay_button')), findsOneWidget);
    });

    testWidgets('CH-TIMER-04: Full 2-second simulation timer auto-resolves successfully if not cancelled', (tester) async {
      PaymentResult? capturedResult;

      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            simulationDuration: const Duration(seconds: 2),
            onPaymentSuccess: (res) {
              capturedResult = res;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('easypaisa_phone_field')), '03001234567');
      await tester.enterText(find.byKey(const Key('easypaisa_pin_field')), '12345');
      await tester.tap(find.byKey(const Key('easypaisa_pay_button')));
      await tester.pump();

      expect(find.text('Easypaisa USSD Push Authorization'), findsOneWidget);

      // Wait out full 2s timer without tapping anything
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(capturedResult, isNotNull);
      expect(capturedResult!.success, isTrue);
      expect(capturedResult!.mode, equals(PaymentMode.easypaisa));
    });

    testWidgets('CH-TIMER-05: Closing sheet while USSD modal is active safely unwinds widget tree', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildChallengerHost(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                PaymentGatewaySheet.show(
                  context: ctx,
                  booking: testBooking,
                  worker: testWorker,
                  simulationDuration: const Duration(seconds: 2),
                );
              },
              child: const Text('Launch Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch Sheet'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('easypaisa_phone_field')), '03001234567');
      await tester.enterText(find.byKey(const Key('easypaisa_pin_field')), '12345');
      await tester.tap(find.byKey(const Key('easypaisa_pay_button')));
      await tester.pump();

      expect(find.text('Easypaisa USSD Push Authorization'), findsOneWidget);

      // Pop root navigator while dialog is active
      Navigator.of(tester.element(find.text('Easypaisa USSD Push Authorization'))).pop();
      await tester.pumpAndSettle();

      // Now close bottom sheet via close button
      if (find.byIcon(Icons.close_rounded).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
      }

      // Ensure no residual timers fire
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Launch Sheet'), findsOneWidget);
    });
  });

  // ==========================================================================
  // Group 3: COD Mutual Escrow State Machine & Spamming Challenges
  // ==========================================================================
  group('Group 3: COD Mutual Escrow State Machine & Spamming Challenges', () {
    testWidgets('CH-COD-01: Rapid 21x checkbox spamming leaves checkbox checked and button enabled', (tester) async {
      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.cod,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      final tile = find.byKey(const Key('cod_checkbox_tile'));
      final payBtnFinder = find.byKey(const Key('cod_pay_button'));

      // Initially disabled
      ElevatedButton payBtn = tester.widget(payBtnFinder);
      expect(payBtn.onPressed, isNull);

      // Spam 21 times (odd count)
      for (int i = 0; i < 21; i++) {
        await tester.tap(tile);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Checkbox should be checked
      final Checkbox cb = tester.widget(find.byType(Checkbox));
      expect(cb.value, isTrue);

      // Button should be enabled
      payBtn = tester.widget(payBtnFinder);
      expect(payBtn.onPressed, isNotNull);
    });

    testWidgets('CH-COD-02: Rapid 20x checkbox spamming leaves checkbox unchecked and button disabled', (tester) async {
      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.cod,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      final tile = find.byKey(const Key('cod_checkbox_tile'));
      final payBtnFinder = find.byKey(const Key('cod_pay_button'));

      // Spam 20 times (even count)
      for (int i = 0; i < 20; i++) {
        await tester.tap(tile);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final Checkbox cb = tester.widget(find.byType(Checkbox));
      expect(cb.value, isFalse);

      final ElevatedButton payBtn = tester.widget(payBtnFinder);
      expect(payBtn.onPressed, isNull);
    });

    testWidgets('CH-COD-03: Switching tabs while COD is checked preserves clean state transitions', (tester) async {
      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.cod,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      // Check COD
      await tester.tap(find.byKey(const Key('cod_checkbox_tile')));
      await tester.pumpAndSettle();

      // Switch to Easypaisa
      await tester.tap(find.text('Easypaisa'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('easypaisa_phone_field')), findsOneWidget);

      // Switch to Stripe
      await tester.tap(find.text('Card (Stripe)'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stripe_card_field')), findsOneWidget);

      // Switch back to COD
      await tester.tap(find.text('Cash (COD)'));
      await tester.pumpAndSettle();

      // COD pay button and state remain accessible
      expect(find.byKey(const Key('cod_pay_button')), findsOneWidget);
    });

    testWidgets('CH-COD-04: Alternating direct Checkbox tap and tile tap toggles reliably', (tester) async {
      await tester.pumpWidget(
        buildChallengerHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.cod,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      // Tap direct checkbox (1st toggle: true)
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect((tester.widget(find.byType(Checkbox)) as Checkbox).value, isTrue);

      // Tap outer tile (2nd toggle: false)
      await tester.tap(find.byKey(const Key('cod_checkbox_tile')));
      await tester.pumpAndSettle();
      expect((tester.widget(find.byType(Checkbox)) as Checkbox).value, isFalse);

      // Tap direct checkbox again (3rd toggle: true)
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect((tester.widget(find.byType(Checkbox)) as Checkbox).value, isTrue);
    });
  });

  // ==========================================================================
  // Group 4: ServiceAgreementScreen Dual Settlement Integration
  // ==========================================================================
  group('Group 4: ServiceAgreementScreen Dual Settlement Integration & Coexistence', () {
    testWidgets('CH-SETTLE-01: Dual settlement cards coexist cleanly in Accepted status', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildChallengerHost(
          ServiceAgreementScreen(
            booking: testBooking,
            worker: testWorker,
            isWorker: false,
            onBack: () {},
            onSubmitReceipt: (_, __) {},
            onConfirmPayment: () {},
            onRaiseDispute: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both cards are present simultaneously
      expect(find.text('Instant Payment Gateway (Recommended)'), findsOneWidget);
      expect(find.text('Submit Payment Receipt'), findsAtLeastNWidgets(1));
      expect(find.text('Pay via Payment Gateway'), findsOneWidget);
    });

    testWidgets('CH-SETTLE-02: Manual receipt submission operates without touching payment gateway', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? submittedTxId;
      String? submittedReceiptPath;

      // Mock image picker platform
      final mockPicker = ChallengerMockImagePicker();
      mockPicker.nextImageToReturn = XFile('C:/mock/receipt_screenshot.png');
      ImagePickerPlatform.instance = mockPicker;

      await tester.pumpWidget(
        buildChallengerHost(
          ServiceAgreementScreen(
            booking: testBooking,
            worker: testWorker,
            isWorker: false,
            onBack: () {},
            onSubmitReceipt: (tx, path) {
              submittedTxId = tx;
              submittedReceiptPath = path;
            },
            onConfirmPayment: () {},
            onRaiseDispute: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Enter manual transaction reference ID
      await tester.enterText(
        find.widgetWithText(TextField, ''),
        'TX-MANUAL-109283',
      );
      await tester.pumpAndSettle();

      // 2. Attach receipt photo via bottom sheet
      await tester.tap(find.text('Tap to attach receipt screenshot'));
      await tester.pumpAndSettle();

      // Choose gallery option
      expect(find.text('Choose from Gallery'), findsOneWidget);
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();

      // Verify attachment thumbnail rendered
      expect(find.text('Receipt Attached'), findsOneWidget);

      // 3. Submit manual receipt
      await tester.tap(find.widgetWithText(HomeEaseButton, 'Submit Payment Receipt'));
      // Wait for internal 300ms submission delay
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(submittedTxId, equals('TX-MANUAL-109283'));
      expect(submittedReceiptPath, isNotNull);
      expect(submittedReceiptPath!.contains('receipt_screenshot.png'), isTrue);
    });

    testWidgets('CH-SETTLE-03: Completing payment via Gateway updates status to Completed and replaces dual settlement cards', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      PaymentResult? completedPaymentResult;

      await tester.pumpWidget(
        buildChallengerHost(
          ServiceAgreementScreen(
            booking: testBooking,
            worker: testWorker,
            isWorker: false,
            simulationDuration: const Duration(milliseconds: 50),
            onBack: () {},
            onSubmitReceipt: (_, __) {},
            onConfirmPayment: () {},
            onRaiseDispute: () {},
            onPaymentCompleted: (res) {
              completedPaymentResult = res;
            },
          ),
          size: const Size(1000, 1600),
        ),
      );
      await tester.pumpAndSettle();

      // Open Gateway
      await tester.tap(find.text('Pay via Payment Gateway'));
      await tester.pumpAndSettle();

      // Pay with Easypaisa
      await tester.enterText(find.byKey(const Key('easypaisa_phone_field')), '03331234567');
      await tester.enterText(find.byKey(const Key('easypaisa_pin_field')), '11223');
      await tester.tap(find.byKey(const Key('easypaisa_pay_button')));
      await tester.pump();

      // Authorize
      await tester.tap(find.text('Authorize USSD Push'));
      await tester.pumpAndSettle();

      // Digital receipt modal appears
      expect(find.text('HomeEase Digital Receipt'), findsOneWidget);
      expect(completedPaymentResult, isNotNull);
      expect(completedPaymentResult!.mode, equals(PaymentMode.easypaisa));

      // Dismiss receipt
      await tester.tap(find.byKey(const Key('receipt_done_button')));
      await tester.pumpAndSettle();

      // ServiceAgreementScreen is now Completed
      expect(find.text('Payment Confirmed'), findsOneWidget);
      expect(find.text('View Digital Receipt'), findsOneWidget);

      // Dual settlement cards must no longer be visible
      expect(find.text('Instant Payment Gateway (Recommended)'), findsNothing);
      expect(find.text('Submit Payment Receipt'), findsNothing);
    });

    testWidgets('CH-SETTLE-04: Digital receipt re-inspection retains accurate TxID and details', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completedBooking = testBooking.copyWith(
        status: 'Completed',
        paymentStatus: 'confirmed',
        paymentMethod: 'jazzcash',
      );

      await tester.pumpWidget(
        buildChallengerHost(
          ServiceAgreementScreen(
            booking: completedBooking,
            worker: testWorker,
            isWorker: false,
            onBack: () {},
            onSubmitReceipt: (_, __) {},
            onConfirmPayment: () {},
            onRaiseDispute: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap View Digital Receipt
      await tester.tap(find.text('View Digital Receipt'));
      await tester.pumpAndSettle();

      expect(find.text('HomeEase Digital Receipt'), findsOneWidget);
      expect(find.text('PAID • VERIFIED ESCROW'), findsOneWidget);
      expect(find.text('PKR 3200'), findsOneWidget);
      expect(find.text('Rashid Khan (Domestic Cleaner)'), findsOneWidget);

      // Dismiss cleanly
      await tester.tap(find.byKey(const Key('receipt_done_button')));
      await tester.pumpAndSettle();

      expect(find.text('HomeEase Digital Receipt'), findsNothing);
      expect(find.text('Payment Confirmed'), findsOneWidget);
    });

    testWidgets('CH-SETTLE-05: Urdu RTL dual settlement flow executes with clean bidirectional typography', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildChallengerHost(
          ServiceAgreementScreen(
            booking: testBooking,
            worker: testWorker,
            isWorker: false,
            simulationDuration: const Duration(milliseconds: 50),
            onBack: () {},
            onSubmitReceipt: (_, __) {},
            onConfirmPayment: () {},
            onRaiseDispute: () {},
          ),
          isUrdu: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(LocalizationService.isUrdu, isTrue);
      // Gateway button has translated text
      expect(find.text('گیٹ وے سے ادائیگی کریں'), findsOneWidget);

      // Open sheet in Urdu
      await tester.tap(find.text('گیٹ وے سے ادائیگی کریں'));
      await tester.pumpAndSettle();

      final titleUrdu = LocalizationService.tr('paymentGatewayTitle');
      expect(find.text(titleUrdu), findsOneWidget);

      // Close modal
      Navigator.of(tester.element(find.text(titleUrdu))).pop();
      await tester.pumpAndSettle();
    });
  });

  // ==========================================================================
  // Group 5: DigitalReceiptDialog Clipboard Mocking & Multi-Mode Challenges
  // ==========================================================================
  group('Group 5: DigitalReceiptDialog Clipboard Mocking & Multi-Mode Challenges', () {
    testWidgets('CH-RCPT-01: Clipboard mock receives exact TxID across all 4 payment modes', (tester) async {
      String? clipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );

      final modes = [
        PaymentMode.easypaisa,
        PaymentMode.jazzcash,
        PaymentMode.stripe,
        PaymentMode.cod,
      ];

      for (final mode in modes) {
        final txId = PaymentGatewaySheet.generateTxId(mode);
        final result = PaymentResult(
          success: true,
          txId: txId,
          mode: mode,
          amount: 3200.0,
          timestamp: DateTime(2026, 10, 18, 12, 0),
          brand: mode == PaymentMode.stripe ? 'Visa' : null,
        );

        await tester.pumpWidget(
          buildChallengerHost(
            DigitalReceiptDialog(
              paymentResult: result,
              booking: testBooking,
              worker: testWorker,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final copyBtn = find.byKey(const Key('copy_txid_button'));
        expect(copyBtn, findsOneWidget);

        await tester.tap(copyBtn);
        await tester.pump();

        // Platform clipboard must contain exact txId
        expect(clipboardText, equals(txId));
      }
    });

    testWidgets('CH-RCPT-02: Rapid 10x copy button spamming succeeds without unhandled platform errors', (tester) async {
      int copyCallCount = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copyCallCount++;
          }
          return null;
        },
      );

      final result = PaymentResult(
        success: true,
        txId: 'EP-SPAMTEST1',
        mode: PaymentMode.easypaisa,
        amount: 3200.0,
        timestamp: DateTime(2026, 10, 18, 12, 0),
      );

      await tester.pumpWidget(
        buildChallengerHost(
          DigitalReceiptDialog(
            paymentResult: result,
            booking: testBooking,
            worker: testWorker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final copyBtn = find.byKey(const Key('copy_txid_button'));
      for (int i = 0; i < 10; i++) {
        await tester.tap(copyBtn);
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();

      expect(copyCallCount, equals(10));
    });

    testWidgets('CH-RCPT-03: Long TxID and worker details render without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640); // Compact mobile screen
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final longWorker = testWorker.copyWith(
        name: 'Muhammad Aurangzeb Khan Niazi',
        role: 'Master Domestic Operations Specialist & Executive Housekeeper',
        area: 'Jhangi Syedan Upper Heights Complex',
      );

      final result = PaymentResult(
        success: true,
        txId: 'ch_3M99999999999999999999999999_EXTRALONG_TXID',
        mode: PaymentMode.stripe,
        amount: 154500.0,
        timestamp: DateTime(2026, 10, 18, 23, 59),
        brand: 'Mastercard',
      );

      final prevHandler = FlutterError.onError;
      String? overflowMessage;
      FlutterError.onError = (details) {
        overflowMessage = details.toString();
        debugPrint('CHALLENGER_DEBUG_OVERFLOW:\n$overflowMessage');
        prevHandler?.call(details);
      };

      await tester.pumpWidget(
        buildChallengerHost(
          DigitalReceiptDialog(
            paymentResult: result,
            booking: testBooking.copyWith(
              address: 'House #492, Sector C-2, PMA Road, Abbottabad Cantonment',
            ),
            worker: longWorker,
          ),
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();
      FlutterError.onError = prevHandler;

      // Verify no overflow errors occurred
      final exception = tester.takeException();
      expect(exception, isNull);
      expect(find.text('PAID • VERIFIED ESCROW'), findsOneWidget);
      expect(find.text('PKR 154500'), findsOneWidget);
    });

    testWidgets('CH-RCPT-04: Urdu RTL DigitalReceiptDialog renders translated watermark and copy SnackBar', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async => null,
      );

      final result = PaymentResult(
        success: true,
        txId: 'JC-URDUTEST9',
        mode: PaymentMode.jazzcash,
        amount: 3200.0,
        timestamp: DateTime(2026, 10, 18, 12, 0),
      );

      await tester.pumpWidget(
        buildChallengerHost(
          DigitalReceiptDialog(
            paymentResult: result,
            booking: testBooking,
            worker: testWorker,
          ),
          isUrdu: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ادا شدہ • تصدیق شدہ ایسکرو'), findsOneWidget);
      expect(find.text('ہوم ایز ڈیجیٹل رسید'), findsOneWidget);
      expect(find.text(LocalizationService.tr('copyTxId')), findsOneWidget);

      await tester.tap(find.byKey(const Key('copy_txid_button')));
      await tester.pump();

      expect(find.text('ٹرانزیکشن آئی ڈی کاپی ہو گئی!'), findsOneWidget);
    });
  });
}
