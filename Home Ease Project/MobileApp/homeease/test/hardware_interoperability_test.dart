import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/dispute_report_screen.dart';
import 'package:homeease/screens/service_agreement_screen.dart';
import 'package:homeease/screens/worker_detail_screen.dart';
import 'package:homeease/services/hardware_interoperability.dart';
import 'package:homeease/services/localization_service.dart';
import 'package:homeease/widgets/in_app_chat_sheet.dart';

// ============================================================================
// Platform Mocks for Isolated, Deterministic Testing
// ============================================================================

class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? launchedUrl;
  LaunchOptions? launchedOptions;
  bool canLaunchResult = true;
  bool launchUrlResult = true;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrl = url;
    launchedOptions = options;
    return launchUrlResult;
  }
}

class MockImagePickerPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {
  XFile? pickedFile;
  ImageSource? lastSource;
  ImagePickerOptions? lastOptions;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions? options,
  }) async {
    lastSource = source;
    lastOptions = options;
    return pickedFile;
  }
}

// ============================================================================
// Test Suite
// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUrlLauncherPlatform mockUrlLauncher;
  late MockImagePickerPlatform mockImagePicker;

  final sampleWorker = WorkerProfile(
    id: 'worker-test-01',
    name: 'Bashir Ahmed',
    role: 'Electrician',
    rating: 4.8,
    reviewsCount: 24,
    experience: '6 Years',
    rate: 'PKR 650/hr',
    location: 'Mandian, Abbottabad',
    highlight: 'Top Rated in Abbottabad',
    phone: '+923129845120',
    description: 'Expert residential electrician in Abbottabad.',
    skillTags: ['Wiring', 'UPS Repair', 'Breaker Fixing'],
    availability: 'Available Today',
  );

  final sampleBooking = Booking(
    id: 'booking-test-101',
    workerId: 'worker-test-01',
    householdId: 'employer-user-01',
    serviceCategoryId: 'electrician',
    bookingDate: DateTime(2026, 10, 20),
    startTime: const TimeOfDay(hour: 10, minute: 0),
    endTime: const TimeOfDay(hour: 12, minute: 0),
    agreedAmount: 1300.0,
    address: 'House 14, Supply Road, Abbottabad',
    notes: 'Fix main distribution board in basement',
    status: 'In Progress',
    createdAt: DateTime(2026, 10, 15),
  );

  setUp(() {
    mockUrlLauncher = MockUrlLauncherPlatform();
    mockImagePicker = MockImagePickerPlatform();
    UrlLauncherPlatform.instance = mockUrlLauncher;
    ImagePickerPlatform.instance = mockImagePicker;
    LocalizationService.setLanguage('en');
  });

  tearDown(() {
    LocalizationService.setLanguage('en');
  });

  group('HardwareInteroperability Helper Unit Tests', () {
    test('cleanPhoneNumber formats Pakistani and international phone numbers accurately', () {
      expect(HardwareInteroperability.cleanPhoneNumber('+92 312 9845120'), '+923129845120');
      expect(HardwareInteroperability.cleanPhoneNumber('0992-111-4663'), '09921114663');
      expect(HardwareInteroperability.cleanPhoneNumber('(0300) 123-4567'), '03001234567');
      expect(HardwareInteroperability.cleanPhoneNumber('  +92-300-5551234  '), '+923005551234');
      expect(HardwareInteroperability.cleanPhoneNumber(''), '');
      expect(HardwareInteroperability.cleanPhoneNumber('   '), '');
    });

    test('dialPhone launches tel: URI via UrlLauncherPlatform', () async {
      final result = await HardwareInteroperability.dialPhone('+92 312 9845120');
      expect(result, isTrue);
      expect(mockUrlLauncher.launchedUrl, 'tel:+923129845120');
    });

    test('dialPhone supports custom launcher dependency injection', () async {
      Uri? capturedUri;
      final result = await HardwareInteroperability.dialPhone(
        '0992-111-4663',
        customLauncher: (uri) async {
          capturedUri = uri;
          return true;
        },
      );
      expect(result, isTrue);
      expect(capturedUri, Uri.parse('tel:09921114663'));
    });

    test('dialPhone returns false when rawPhone is empty', () async {
      final result = await HardwareInteroperability.dialPhone('');
      expect(result, isFalse);
      expect(mockUrlLauncher.launchedUrl, isNull);
    });

    test('pickImage invokes camera and gallery via ImagePickerPlatform', () async {
      mockImagePicker.pickedFile = XFile('/tmp/test_camera.jpg');
      final cameraPath = await HardwareInteroperability.pickImage(source: ImageSource.camera);
      expect(cameraPath, '/tmp/test_camera.jpg');
      expect(mockImagePicker.lastSource, ImageSource.camera);

      mockImagePicker.pickedFile = XFile('/tmp/test_gallery.png');
      final galleryPath = await HardwareInteroperability.pickImage(source: ImageSource.gallery);
      expect(galleryPath, '/tmp/test_gallery.png');
      expect(mockImagePicker.lastSource, ImageSource.gallery);
    });

    test('pickImage returns null when user cancels selection', () async {
      mockImagePicker.pickedFile = null;
      final path = await HardwareInteroperability.pickImage(source: ImageSource.camera);
      expect(path, isNull);
    });

    test('uploadPhotoToStorage falls back gracefully to local path when offline or file missing', () async {
      final path = await HardwareInteroperability.uploadPhotoToStorage(
        filePath: 'non_existent_file.jpg',
        bucket: 'receipts',
      );
      expect(path, 'non_existent_file.jpg');
    });
  });

  group('Native Phone Dialer Integration Tests', () {
    testWidgets('WorkerDetailScreen launches dialer when Direct Phone Call is tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: WorkerDetailScreen(
            worker: sampleWorker,
            onBack: () {},
            onBookNow: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Direct Contact bottom modal
      final contactButton = find.text('Contact');
      expect(contactButton, findsOneWidget);
      await tester.tap(contactButton);
      await tester.pumpAndSettle();

      // Tap Direct Phone Call list tile
      final directPhoneTile = find.text('Direct Phone Call');
      expect(directPhoneTile, findsOneWidget);
      await tester.tap(directPhoneTile);
      await tester.pumpAndSettle();

      // Verify that the dialer was launched with the worker phone number
      expect(mockUrlLauncher.launchedUrl, 'tel:+923129845120');
    });

    testWidgets('InAppChatSheet phone button invokes onCallPressed callback', (tester) async {
      bool onCallCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppChatSheet(
              recipientId: sampleWorker.id,
              recipientName: sampleWorker.name,
              recipientRole: sampleWorker.role,
              onCallPressed: () {
                onCallCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final phoneButton = find.widgetWithIcon(IconButton, Icons.phone_rounded);
      expect(phoneButton, findsOneWidget);

      // Verify touch target >= 48x48 dp
      final size = tester.getSize(phoneButton);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(phoneButton);
      await tester.pumpAndSettle();
      expect(onCallCalled, isTrue);
    });

    testWidgets('InAppChatSheet phone button falls back to dialPhone if onCallPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppChatSheet(
              recipientId: sampleWorker.id,
              recipientName: sampleWorker.name,
              recipientRole: sampleWorker.role,
              onCallPressed: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final phoneButton = find.widgetWithIcon(IconButton, Icons.phone_rounded);
      expect(phoneButton, findsOneWidget);
      await tester.tap(phoneButton);
      await tester.pumpAndSettle();

      expect(mockUrlLauncher.launchedUrl, 'tel:+923129845120');
    });
  });

  group('ServiceAgreementScreen Hybrid Photo Attachment Tests', () {
    testWidgets('Household view renders tap-to-attach container and opens photo source bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockImagePicker.pickedFile = XFile('/tmp/receipt_snap_101.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: ServiceAgreementScreen(
            booking: sampleBooking,
            worker: sampleWorker,
            isWorker: false,
            onBack: () {},
            onSubmitReceipt: (txId, receiptPath) {},
            onConfirmPayment: () {},
            onRaiseDispute: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to attach receipt
      final attachBox = find.text('Tap to attach receipt screenshot');
      expect(attachBox, findsOneWidget);
      await tester.tap(attachBox);
      await tester.pumpAndSettle();

      // Bottom sheet presents "Take Photo (Camera)" and "Choose from Gallery"
      final cameraOption = find.text('Take Photo (Camera)');
      final galleryOption = find.text('Choose from Gallery');
      expect(cameraOption, findsOneWidget);
      expect(galleryOption, findsOneWidget);

      // Tap Take Photo option
      await tester.tap(cameraOption);
      await tester.pumpAndSettle();

      // Verify that ImagePickerPlatform received ImageSource.camera
      expect(mockImagePicker.lastSource, ImageSource.camera);

      // Verify thumbnail preview card rendered
      expect(find.text('Receipt Attached'), findsOneWidget);
      expect(find.text('receipt_snap_101.jpg'), findsOneWidget);

      // Verify Remove button exists with >= 48dp touch target
      final removeButton = find.byTooltip('Remove receipt');
      expect(removeButton, findsOneWidget);
      final removeSize = tester.getSize(removeButton);
      expect(removeSize.width, greaterThanOrEqualTo(48.0));
      expect(removeSize.height, greaterThanOrEqualTo(48.0));

      // Tap remove button and verify that preview resets
      await tester.tap(removeButton);
      await tester.pumpAndSettle();
      expect(find.text('Receipt Attached'), findsNothing);
      expect(find.text('Tap to attach receipt screenshot'), findsOneWidget);
    });

    testWidgets('Gallery option in ServiceAgreementScreen selects from photo library', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockImagePicker.pickedFile = XFile('/tmp/gallery_proof.png');

      await tester.pumpWidget(
        MaterialApp(
          home: ServiceAgreementScreen(
            booking: sampleBooking,
            worker: sampleWorker,
            isWorker: false,
            onBack: () {},
            onSubmitReceipt: (txId, receiptPath) {},
            onConfirmPayment: () {},
            onRaiseDispute: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap to attach receipt screenshot'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();

      expect(mockImagePicker.lastSource, ImageSource.gallery);
      expect(find.text('Receipt Attached'), findsOneWidget);
      expect(find.text('gallery_proof.png'), findsOneWidget);
    });
  });

  group('DisputeReportScreen Emergency Dialer & Photo Attachment Tests', () {
    testWidgets('Urgent helpline modal dials Abbottabad safety control center', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: DisputeReportScreen(
            booking: sampleBooking,
            onBack: () {},
            onSubmit: (cat, desc, proof) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap urgent helpline icon button in app bar
      final helplineBtn = find.byTooltip('Urgent Helpline');
      expect(helplineBtn, findsOneWidget);
      await tester.tap(helplineBtn);
      await tester.pumpAndSettle();

      // Tap Direct Safety Emergency Line
      final emergencyTile = find.text('Direct Safety Emergency Line');
      expect(emergencyTile, findsOneWidget);
      await tester.tap(emergencyTile);
      await tester.pumpAndSettle();

      // Verify that dialer was launched with 09921114663
      expect(mockUrlLauncher.launchedUrl, 'tel:09921114663');
    });

    testWidgets('DisputeReportScreen attaches photo evidence and displays thumbnail preview with remove button', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockImagePicker.pickedFile = XFile('/tmp/damage_evidence.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: DisputeReportScreen(
            booking: sampleBooking,
            onBack: () {},
            onSubmit: (cat, desc, proof) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final attachContainer = find.text('Tap to take photo or attach from gallery');
      expect(attachContainer, findsOneWidget);
      await tester.tap(attachContainer);
      await tester.pumpAndSettle();

      final cameraOption = find.text('Take Photo (Camera)');
      expect(cameraOption, findsOneWidget);
      await tester.tap(cameraOption);
      await tester.pumpAndSettle();

      expect(mockImagePicker.lastSource, ImageSource.camera);
      expect(find.text('Evidence Attached'), findsOneWidget);
      expect(find.text('damage_evidence.jpg'), findsOneWidget);

      final removeBtn = find.byTooltip('Remove photo');
      expect(removeBtn, findsOneWidget);
      final size = tester.getSize(removeBtn);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(removeBtn);
      await tester.pumpAndSettle();
      expect(find.text('Evidence Attached'), findsNothing);
      expect(find.text('Tap to take photo or attach from gallery'), findsOneWidget);
    });
  });

  group('Bilingual UI & RTL Touch Target Invariants', () {
    testWidgets('ServiceAgreementScreen supports Urdu RTL with localized labels', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      LocalizationService.setLanguage('ur');

      await tester.pumpWidget(
        MaterialApp(
          home: ServiceAgreementScreen(
            booking: sampleBooking,
            worker: sampleWorker,
            isWorker: false,
            onBack: () {},
            onSubmitReceipt: (txId, receiptPath) {},
            onConfirmPayment: () {},
            onRaiseDispute: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('معاہدے کی شرائط'), findsOneWidget);
      expect(find.text('رسید کی تصویر منسلک کرنے کے لیے ٹیپ کریں'), findsOneWidget);
    });

    testWidgets('DisputeReportScreen supports Urdu RTL with localized title', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      LocalizationService.setLanguage('ur');

      await tester.pumpWidget(
        MaterialApp(
          home: DisputeReportScreen(
            booking: sampleBooking,
            onBack: () {},
            onSubmit: (cat, desc, proof) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تنازعہ درج کریں'), findsOneWidget);
      expect(find.text('تصویر لینے یا گیلری سے منتخب کرنے کے لیے ٹیپ کریں'), findsOneWidget);
    });
  });
}
