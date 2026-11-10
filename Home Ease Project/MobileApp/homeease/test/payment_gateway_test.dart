import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/service_agreement_screen.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/localization_service.dart';
import 'package:homeease/widgets/digital_receipt_dialog.dart';
import 'package:homeease/widgets/payment_gateway_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testBooking = Booking(
    id: 'bkg_test_gateway_01',
    householdId: '00000000-0000-0000-0000-000000000001',
    workerId: '00000000-0000-0000-0000-000000000010',
    serviceCategoryId: 'Cooking',
    bookingDate: DateTime(2026, 10, 20),
    startTime: const TimeOfDay(hour: 9, minute: 0),
    endTime: const TimeOfDay(hour: 12, minute: 0),
    address: 'Mandian, Abbottabad',
    notes: 'Family dinner prep',
    agreedAmount: 2500.0,
    status: 'Accepted',
    paymentMethod: 'cash',
    paymentStatus: 'unpaid',
    createdAt: DateTime(2026, 10, 18),
  );

  final testWorker = WorkerProfile(
    id: '00000000-0000-0000-0000-000000000010',
    name: 'Saima Bibi',
    role: 'Traditional Cook',
    rating: 4.8,
    rate: 'PKR 800/hr',
    experience: '5 years',
    availability: 'Available',
    location: 'Mandian, Abbottabad',
    description: 'Specializes in Pakistani cuisine',
    highlight: 'Verified',
    bio: 'Specializes in Pakistani cuisine',
    experienceYears: 5,
    city: 'Abbottabad',
    area: 'Mandian',
    availabilityStatus: 'Available',
    verificationStatus: 'Verified',
    averageRating: 4.8,
  );

  Widget buildTestHost(Widget child, {bool isUrdu = false, Size size = const Size(800, 1600)}) {
    LocalizationService.setLanguage(isUrdu ? LocalizationService.langUrdu : LocalizationService.langEnglish);
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

  group('Group 1: Unit Tests - Validations & Format Helpers', () {
    test('PG-UNIT-01: Validates Pakistani mobile numbers (03XXXXXXXXX)', () {
      expect(PaymentGatewaySheet.isValidPakistaniMobile('03001234567'), isTrue);
      expect(PaymentGatewaySheet.isValidPakistaniMobile('0312-3456789'), isTrue);
      expect(PaymentGatewaySheet.isValidPakistaniMobile('0345 9876543'), isTrue);
      expect(PaymentGatewaySheet.isValidPakistaniMobile('03990000000'), isTrue);

      // Rejections
      expect(PaymentGatewaySheet.isValidPakistaniMobile('04001234567'), isFalse); // Not starting with 03
      expect(PaymentGatewaySheet.isValidPakistaniMobile('0300123456'), isFalse); // 10 digits
      expect(PaymentGatewaySheet.isValidPakistaniMobile('030012345678'), isFalse); // 12 digits
      expect(PaymentGatewaySheet.isValidPakistaniMobile('0300123456A'), isFalse); // Letters
      expect(PaymentGatewaySheet.isValidPakistaniMobile(''), isFalse);
    });

    test('PG-UNIT-02: Validates Easypaisa 5-digit PIN', () {
      expect(PaymentGatewaySheet.isValidEasypaisaPin('12345'), isTrue);
      expect(PaymentGatewaySheet.isValidEasypaisaPin('00000'), isTrue);
      expect(PaymentGatewaySheet.isValidEasypaisaPin('98765'), isTrue);

      // Rejections
      expect(PaymentGatewaySheet.isValidEasypaisaPin('1234'), isFalse); // 4 digits
      expect(PaymentGatewaySheet.isValidEasypaisaPin('123456'), isFalse); // 6 digits
      expect(PaymentGatewaySheet.isValidEasypaisaPin('1234a'), isFalse); // Alpha
      expect(PaymentGatewaySheet.isValidEasypaisaPin(''), isFalse);
    });

    test('PG-UNIT-03: Validates JazzCash 4-digit MPIN', () {
      expect(PaymentGatewaySheet.isValidJazzCashMpin('1234'), isTrue);
      expect(PaymentGatewaySheet.isValidJazzCashMpin('0000'), isTrue);
      expect(PaymentGatewaySheet.isValidJazzCashMpin('9876'), isTrue);

      // Rejections
      expect(PaymentGatewaySheet.isValidJazzCashMpin('123'), isFalse); // 3 digits
      expect(PaymentGatewaySheet.isValidJazzCashMpin('12345'), isFalse); // 5 digits
      expect(PaymentGatewaySheet.isValidJazzCashMpin('123a'), isFalse);
      expect(PaymentGatewaySheet.isValidJazzCashMpin(''), isFalse);
    });

    test('PG-UNIT-04: Validates Luhn Checksum algorithm for 16-digit cards', () {
      // Standard Visa test card: 4242 4242 4242 4242
      expect(PaymentGatewaySheet.isValidLuhn('4242424242424242'), isTrue);
      expect(PaymentGatewaySheet.isValidLuhn('4242 4242 4242 4242'), isTrue);

      // Standard Mastercard test card: 5555 5555 5555 4444
      expect(PaymentGatewaySheet.isValidLuhn('5555555555554444'), isTrue);

      // Corrupted checksum digits
      expect(PaymentGatewaySheet.isValidLuhn('4242424242424243'), isFalse);
      expect(PaymentGatewaySheet.isValidLuhn('5555555555554445'), isFalse);
      expect(PaymentGatewaySheet.isValidLuhn('1234567812345678'), isFalse);

      // Invalid lengths
      expect(PaymentGatewaySheet.isValidLuhn('424242424242424'), isFalse); // 15 digits
      expect(PaymentGatewaySheet.isValidLuhn('42424242424242421'), isFalse); // 17 digits
    });

    test('PG-UNIT-05: Detects card brand dynamically from card number prefix', () {
      expect(PaymentGatewaySheet.detectCardBrand('4242424242424242'), equals('Visa'));
      expect(PaymentGatewaySheet.detectCardBrand('4000123456789010'), equals('Visa'));
      expect(PaymentGatewaySheet.detectCardBrand('5100123456789010'), equals('Mastercard'));
      expect(PaymentGatewaySheet.detectCardBrand('5500123456789010'), equals('Mastercard'));
      expect(PaymentGatewaySheet.detectCardBrand('2221123456789010'), equals('Mastercard'));
      expect(PaymentGatewaySheet.detectCardBrand('2720123456789010'), equals('Mastercard'));
      expect(PaymentGatewaySheet.detectCardBrand('3700123456789010'), equals('Generic'));
      expect(PaymentGatewaySheet.detectCardBrand('6011123456789010'), equals('Generic'));
    });

    test('PG-UNIT-06: Validates card expiry MM/YY format and future year >= 26', () {
      expect(PaymentGatewaySheet.isValidExpiry('12/26'), isTrue);
      expect(PaymentGatewaySheet.isValidExpiry('05/28'), isTrue);
      expect(PaymentGatewaySheet.isValidExpiry('01/30'), isTrue);

      // Rejections
      expect(PaymentGatewaySheet.isValidExpiry('13/27'), isFalse); // Month 13
      expect(PaymentGatewaySheet.isValidExpiry('00/27'), isFalse); // Month 00
      expect(PaymentGatewaySheet.isValidExpiry('08/24'), isFalse); // Past year 24
      expect(PaymentGatewaySheet.isValidExpiry('08/25'), isFalse); // Past year 25
      expect(PaymentGatewaySheet.isValidExpiry('5/27'), isFalse); // Missing leading zero
    });

    test('PG-UNIT-07: Validates CVC (3 or 4 digits)', () {
      expect(PaymentGatewaySheet.isValidCvc('123'), isTrue);
      expect(PaymentGatewaySheet.isValidCvc('4567'), isTrue);
      expect(PaymentGatewaySheet.isValidCvc('000'), isTrue);

      // Rejections
      expect(PaymentGatewaySheet.isValidCvc('12'), isFalse);
      expect(PaymentGatewaySheet.isValidCvc('12345'), isFalse);
      expect(PaymentGatewaySheet.isValidCvc('12a'), isFalse);
    });

    test('PG-UNIT-08: Verifies authentic TxID generation formats for all 4 modes', () {
      final epTx = PaymentGatewaySheet.generateTxId(PaymentMode.easypaisa);
      expect(epTx.startsWith('EP-'), isTrue);
      expect(epTx.length, equals(11));

      final jcTx = PaymentGatewaySheet.generateTxId(PaymentMode.jazzcash);
      expect(jcTx.startsWith('JC-'), isTrue);
      expect(jcTx.length, equals(11));

      final stripeTx = PaymentGatewaySheet.generateTxId(PaymentMode.stripe);
      expect(stripeTx.startsWith('ch_3M'), isTrue);
      expect(stripeTx.length, equals(26));

      final codTx = PaymentGatewaySheet.generateTxId(PaymentMode.cod);
      expect(codTx.startsWith('COD-'), isTrue);
      expect(codTx.length, equals(12));
    });

    test('PG-UNIT-09: BookingRepository.completeBookingPayment updates status and cache', () async {
      final repo = BookingRepository();
      const testBkgId = 'test_unit_complete_01';

      final updated = await repo.completeBookingPayment(
        bookingId: testBkgId,
        paymentMethod: 'easypaisa',
        txId: 'EP-98765432',
        paymentStatus: 'confirmed',
      );

      expect(updated.status, equals('Completed'));
      expect(updated.paymentStatus, equals('confirmed'));
      expect(updated.paymentMethod, equals('easypaisa'));
    });
  });

  group('Group 2: Widget Tests - PaymentGatewaySheet Modes & Simulations', () {
    testWidgets('PG-WGT-01: Renders all 4 payment mode selector tabs', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      expect(find.text('Easypaisa'), findsOneWidget);
      expect(find.text('JazzCash'), findsOneWidget);
      expect(find.text('Card (Stripe)'), findsOneWidget);
      expect(find.text('Cash (COD)'), findsOneWidget);
    });

    testWidgets('PG-WGT-02: Mode switching activates corresponding form fields', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      // Default Easypaisa mode has 5-digit PIN field
      expect(find.byKey(const Key('easypaisa_pin_field')), findsOneWidget);

      // Tap JazzCash
      await tester.tap(find.text('JazzCash'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('jazzcash_pin_field')), findsOneWidget);

      // Tap Card (Stripe)
      await tester.tap(find.text('Card (Stripe)'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stripe_card_field')), findsOneWidget);

      // Tap Cash (COD)
      await tester.tap(find.text('Cash (COD)'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cod_checkbox_tile')), findsOneWidget);
    });

    testWidgets('PG-WGT-03: Easypaisa tab rejects invalid phone and PIN with error text', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      // Tap Pay with empty inputs
      await tester.tap(find.byKey(const Key('easypaisa_pay_button')));
      await tester.pumpAndSettle();

      expect(find.text('Enter valid 11-digit mobile (03XXXXXXXXX)'), findsOneWidget);
      expect(find.text('Enter 5-digit Easypaisa PIN'), findsOneWidget);
    });

    testWidgets('PG-WGT-04: Easypaisa tab shows USSD push modal on valid submission and returns EP- TxID', (tester) async {
      PaymentResult? capturedResult;

      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            simulationDuration: const Duration(milliseconds: 50),
            onPaymentSuccess: (res) {
              capturedResult = res;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('easypaisa_phone_field')), '03123456789');
      await tester.enterText(find.byKey(const Key('easypaisa_pin_field')), '12345');
      await tester.tap(find.byKey(const Key('easypaisa_pay_button')));
      await tester.pump(); // Show dialog

      expect(find.text('Easypaisa USSD Push Authorization'), findsOneWidget);
      expect(find.text('Authorize USSD Push'), findsOneWidget);

      // Tap manual button to complete
      await tester.tap(find.text('Authorize USSD Push'));
      await tester.pumpAndSettle();

      expect(capturedResult, isNotNull);
      expect(capturedResult!.success, isTrue);
      expect(capturedResult!.mode, equals(PaymentMode.easypaisa));
      expect(capturedResult!.txId.startsWith('EP-'), isTrue);
    });

    testWidgets('PG-WGT-05: JazzCash tab rejects invalid phone and MPIN', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.jazzcash,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('jazzcash_phone_field')), '04123456789'); // invalid prefix
      await tester.enterText(find.byKey(const Key('jazzcash_pin_field')), '12'); // only 2 digits
      await tester.tap(find.byKey(const Key('jazzcash_pay_button')));
      await tester.pumpAndSettle();

      expect(find.text('Enter valid 11-digit mobile (03XXXXXXXXX)'), findsOneWidget);
      expect(find.text('Enter 4-digit JazzCash MPIN'), findsOneWidget);
    });

    testWidgets('PG-WGT-06: JazzCash tab displays processing spinner dialog and returns JC- TxID', (tester) async {
      PaymentResult? capturedResult;

      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.jazzcash,
            simulationDuration: const Duration(milliseconds: 50),
            onPaymentSuccess: (res) {
              capturedResult = res;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('jazzcash_phone_field')), '03001234567');
      await tester.enterText(find.byKey(const Key('jazzcash_pin_field')), '4321');
      await tester.tap(find.byKey(const Key('jazzcash_pay_button')));
      await tester.pump();

      expect(find.text('Connecting to JazzCash Gateway & Verifying MPIN...'), findsOneWidget);
      expect(find.text('Complete Verification'), findsOneWidget);

      await tester.tap(find.text('Complete Verification'));
      await tester.pumpAndSettle();

      expect(capturedResult, isNotNull);
      expect(capturedResult!.success, isTrue);
      expect(capturedResult!.mode, equals(PaymentMode.jazzcash));
      expect(capturedResult!.txId.startsWith('JC-'), isTrue);
    });

    testWidgets('PG-WGT-07: Stripe Card tab displays dynamic Visa badge for 4... and Mastercard for 55...', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.stripe,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      // Type 4...
      await tester.enterText(find.byKey(const Key('stripe_card_field')), '4242');
      await tester.pump();
      expect(find.text('VISA'), findsOneWidget);

      // Type 55...
      await tester.enterText(find.byKey(const Key('stripe_card_field')), '5555');
      await tester.pump();
      expect(find.text('MC'), findsOneWidget);
    });

    testWidgets('PG-WGT-08: Stripe Card tab rejects card failing Luhn algorithm', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.stripe,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('stripe_card_field')), '4242424242424243'); // Invalid Luhn
      await tester.enterText(find.byKey(const Key('stripe_expiry_field')), '12/28');
      await tester.enterText(find.byKey(const Key('stripe_cvc_field')), '123');
      await tester.tap(find.byKey(const Key('stripe_pay_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid 16-digit card number (Luhn Checksum failed)'), findsOneWidget);
    });

    testWidgets('PG-WGT-09: Stripe Card tab shows 3D Secure modal dialog on valid entry and returns ch_3M TxID', (tester) async {
      PaymentResult? capturedResult;

      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.stripe,
            simulationDuration: const Duration(milliseconds: 50),
            onPaymentSuccess: (res) {
              capturedResult = res;
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('stripe_card_field')), '4242424242424242'); // Valid Luhn Visa
      await tester.enterText(find.byKey(const Key('stripe_expiry_field')), '12/28');
      await tester.enterText(find.byKey(const Key('stripe_cvc_field')), '456');
      await tester.tap(find.byKey(const Key('stripe_pay_button')));
      await tester.pump();

      expect(find.text('3D Secure 2.0 Verification'), findsOneWidget);
      expect(find.text('Authorize OTP'), findsOneWidget);

      await tester.tap(find.text('Authorize OTP'));
      await tester.pumpAndSettle();

      expect(capturedResult, isNotNull);
      expect(capturedResult!.success, isTrue);
      expect(capturedResult!.mode, equals(PaymentMode.stripe));
      expect(capturedResult!.txId.startsWith('ch_3M'), isTrue);
    });

    testWidgets('PG-WGT-10: COD tab requires acknowledgment checkbox before Pay button is enabled', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.cod,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      // Button is disabled initially
      final payBtnFinder = find.byKey(const Key('cod_pay_button'));
      final ElevatedButton btn = tester.widget(payBtnFinder);
      expect(btn.onPressed, isNull);

      // Tap acknowledgment checkbox
      await tester.tap(find.byKey(const Key('cod_checkbox_tile')));
      await tester.pumpAndSettle();

      // Button is now enabled
      final ElevatedButton btnEnabled = tester.widget(payBtnFinder);
      expect(btnEnabled.onPressed, isNotNull);
    });

    testWidgets('PG-WGT-11: COD tab returns COD- TxID upon confirmation', (tester) async {
      PaymentResult? capturedResult;

      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.cod,
            onPaymentSuccess: (res) {
              capturedResult = res;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('cod_checkbox_tile')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cod_pay_button')));
      await tester.pumpAndSettle();

      expect(capturedResult, isNotNull);
      expect(capturedResult!.success, isTrue);
      expect(capturedResult!.mode, equals(PaymentMode.cod));
      expect(capturedResult!.txId.startsWith('COD-'), isTrue);
    });

    testWidgets('PG-WGT-12: Interactive chips and buttons adhere to >= 48x48dp touch targets', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            initialMode: PaymentMode.easypaisa,
            onPaymentSuccess: (_) {},
          ),
        ),
      );

      final payBtnSize = tester.getSize(find.byKey(const Key('easypaisa_pay_button')));
      expect(payBtnSize.height, greaterThanOrEqualTo(48.0));
      expect(payBtnSize.width, greaterThanOrEqualTo(48.0));

      final chipFinder = find.ancestor(of: find.text('Easypaisa'), matching: find.byType(InkWell));
      final chipSize = tester.getSize(chipFinder);
      expect(chipSize.height, greaterThanOrEqualTo(48.0));
      expect(chipSize.width, greaterThanOrEqualTo(48.0));
    });

    testWidgets('PG-WGT-13: PaymentGatewaySheet renders in Urdu RTL directionality', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          PaymentGatewaySheet(
            booking: testBooking,
            worker: testWorker,
            onPaymentSuccess: (_) {},
          ),
          isUrdu: true,
        ),
      );

      expect(find.text(LocalizationService.tr('paymentGatewayTitle')), findsOneWidget);
      expect(LocalizationService.isUrdu, isTrue);
    });
  });

  group('Group 3: Widget Tests - DigitalReceiptDialog', () {
    final testResult = PaymentResult(
      success: true,
      txId: 'EP-92817264',
      mode: PaymentMode.easypaisa,
      amount: 2500.0,
      timestamp: DateTime(2026, 10, 18, 9, 30),
      payerIdentifier: '03123456789',
      brand: 'Easypaisa',
    );

    testWidgets('PG-WGT-14: DigitalReceiptDialog renders Serene Hearth watermark and verified icon', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          DigitalReceiptDialog(
            paymentResult: testResult,
            booking: testBooking,
            worker: testWorker,
          ),
        ),
      );

      expect(find.text('PAID • VERIFIED ESCROW'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text('HomeEase Digital Receipt'), findsOneWidget);
    });

    testWidgets('PG-WGT-15: DigitalReceiptDialog TxID badge features 1-tap Copy to Clipboard', (tester) async {
      String? copiedData;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedData = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        buildTestHost(
          DigitalReceiptDialog(
            paymentResult: testResult,
            booking: testBooking,
            worker: testWorker,
          ),
        ),
      );

      expect(find.text('EP-92817264'), findsOneWidget);
      final copyBtn = find.byKey(const Key('copy_txid_button'));
      expect(copyBtn, findsOneWidget);

      await tester.tap(copyBtn);
      await tester.pump();

      expect(find.text('Transaction ID copied to clipboard!'), findsOneWidget);
      expect(copiedData, equals('EP-92817264'));
    });

    testWidgets('PG-WGT-16: DigitalReceiptDialog renders correct amount breakdown and worker summary', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          DigitalReceiptDialog(
            paymentResult: testResult,
            booking: testBooking,
            worker: testWorker,
          ),
        ),
      );

      expect(find.text('PKR 2500'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Saima Bibi (Traditional Cook)'), findsOneWidget);
      expect(find.text('Mandian, Abbottabad'), findsAtLeastNWidgets(1));
    });

    testWidgets('PG-WGT-17: DigitalReceiptDialog renders in Urdu RTL directionality', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          DigitalReceiptDialog(
            paymentResult: testResult,
            booking: testBooking,
            worker: testWorker,
          ),
          isUrdu: true,
        ),
      );

      expect(find.text('ہوم ایز ڈیجیٹل رسید'), findsOneWidget);
      expect(find.text('ادا شدہ • تصدیق شدہ ایسکرو'), findsOneWidget);
      expect(find.text('تصدیق شدہ'), findsOneWidget);
    });

    testWidgets('PG-WGT-18: Done button dismisses the dialog cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool dismissed = false;

      await tester.pumpWidget(
        buildTestHost(
          DigitalReceiptDialog(
            paymentResult: testResult,
            booking: testBooking,
            worker: testWorker,
            onDismiss: () {
              dismissed = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('receipt_done_button')));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });
  });

  group('Group 4: Integration Tests - ServiceAgreementScreen Payment Integration', () {
    testWidgets('PG-INT-01: ServiceAgreementScreen renders Instant Payment Gateway card for household view', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestHost(
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
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Instant Payment Gateway (Recommended)'), findsOneWidget);
      expect(find.text('Pay via Payment Gateway'), findsOneWidget);
    });

    testWidgets('PG-INT-02: Tapping Pay via Payment Gateway opens PaymentGatewaySheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestHost(
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
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pay via Payment Gateway'));
      await tester.pumpAndSettle();

      expect(find.text('HomeEase Secure Payment Gateway'), findsOneWidget);
      expect(find.text('Easypaisa'), findsOneWidget);
      expect(find.text('JazzCash'), findsOneWidget);

      // Close bottom sheet cleanly
      Navigator.of(tester.element(find.text('Easypaisa'))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('PG-INT-03: Completing payment transitions status to Completed and shows digital receipt', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      PaymentResult? completedResult;

      await tester.pumpWidget(
        buildTestHost(
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
              completedResult = res;
            },
          ),
          size: const Size(1000, 1600),
        ),
      );
      await tester.pumpAndSettle();

      // Open gateway
      await tester.tap(find.text('Pay via Payment Gateway'));
      await tester.pumpAndSettle();

      // Switch to COD for instant confirmation
      await tester.ensureVisible(find.text('Cash (COD)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash (COD)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cod_checkbox_tile')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cod_pay_button')));
      await tester.pumpAndSettle();

      // Digital receipt dialog is now shown
      expect(find.text('HomeEase Digital Receipt'), findsOneWidget);
      expect(completedResult, isNotNull);
      expect(completedResult!.mode, equals(PaymentMode.cod));

      // Dismiss receipt
      await tester.tap(find.byKey(const Key('receipt_done_button')));
      await tester.pumpAndSettle();

      // Service agreement screen is now Completed
      expect(find.text('Payment Confirmed'), findsOneWidget);
      expect(find.text('View Digital Receipt'), findsOneWidget);
    });

    testWidgets('PG-INT-04: Completed status renders View Digital Receipt button allowing inspection', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completedBooking = testBooking.copyWith(
        status: 'Completed',
        paymentStatus: 'confirmed',
        paymentMethod: 'easypaisa',
      );

      await tester.pumpWidget(
        buildTestHost(
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

      expect(find.text('Payment Confirmed'), findsOneWidget);
      final viewBtn = find.text('View Digital Receipt');
      expect(viewBtn, findsOneWidget);

      await tester.tap(viewBtn);
      await tester.pumpAndSettle();

      expect(find.text('HomeEase Digital Receipt'), findsOneWidget);
      expect(find.text('PAID • VERIFIED ESCROW'), findsOneWidget);

      // Dismiss receipt
      await tester.tap(find.byKey(const Key('receipt_done_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('PG-INT-05: Existing manual receipt flow and Submit Payment Receipt button remain preserved', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestHost(
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

      // Verify backwards-compatibility elements required by existing tests
      expect(find.text('Submit Payment Receipt'), findsNWidgets(2)); // Card title + button
      expect(find.text('Arrival Verification OTP'), findsOneWidget);
      expect(find.text('Tap to attach receipt screenshot'), findsOneWidget);
    });
  });
}
