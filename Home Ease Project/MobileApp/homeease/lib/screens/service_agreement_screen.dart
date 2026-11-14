import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/worker_profile.dart';
import '../services/booking_repository.dart';
import '../services/dispute_repository.dart';
import '../services/hardware_interoperability.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/digital_receipt_dialog.dart';
import '../widgets/home_ease_widgets.dart';
import '../widgets/p2p_payment_sheet.dart';
import '../widgets/payment_gateway_sheet.dart';

class ServiceAgreementScreen extends StatefulWidget {
  const ServiceAgreementScreen({
    super.key,
    required this.booking,
    required this.worker,
    required this.isWorker,
    required this.onBack,
    required this.onSubmitReceipt,
    required this.onConfirmPayment,
    required this.onRaiseDispute,
    this.onVerifyArrival,
    this.onPaymentCompleted,
    this.simulationDuration = const Duration(seconds: 2),
  });

  final Booking booking;
  final WorkerProfile worker;
  final bool isWorker;
  final VoidCallback onBack;
  final Function(String txId, String receiptPath) onSubmitReceipt;
  final VoidCallback onConfirmPayment;
  final VoidCallback onRaiseDispute;
  final VoidCallback? onVerifyArrival;
  final void Function(PaymentResult result)? onPaymentCompleted;
  final Duration simulationDuration;

  @override
  State<ServiceAgreementScreen> createState() => _ServiceAgreementScreenState();
}

class _ServiceAgreementScreenState extends State<ServiceAgreementScreen> {
  final TextEditingController _txController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? _receiptAttachmentPath;
  late String _currentStatus;
  late String _currentPaymentStatus;
  Booking? _updatedBooking;
  PaymentResult? _lastPaymentResult;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking.status;
    _currentPaymentStatus = widget.booking.paymentStatus;
    _receiptAttachmentPath = widget.booking.receiptUrl;
    if (widget.booking.transactionId != null && widget.booking.transactionId!.isNotEmpty) {
      _txController.text = widget.booking.transactionId!;
    }
  }

  @override
  void didUpdateWidget(ServiceAgreementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.booking.status != oldWidget.booking.status) {
      _currentStatus = widget.booking.status;
    }
    if (widget.booking.paymentStatus != oldWidget.booking.paymentStatus) {
      _currentPaymentStatus = widget.booking.paymentStatus;
    }
    if (widget.booking.receiptUrl != oldWidget.booking.receiptUrl && widget.booking.receiptUrl != null) {
      _receiptAttachmentPath = widget.booking.receiptUrl;
    }
  }

  @override
  void dispose() {
    _txController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _attachReceiptPhoto() {
    _showPhotoSourceDialog();
  }

  void _showPhotoSourceDialog() {
    HapticFeedback.lightImpact();
    final isUrdu = LocalizationService.isUrdu;
    showModalBottomSheet(
      context: context,
      backgroundColor: HomeEaseTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUrdu ? 'رسید کی تصویر منسلک کریں' : 'Attach Receipt Photo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HomeEaseTheme.brand,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUrdu
                    ? 'براہ کرم رسید کی واضح تصویر لیں یا گیلری سے منتخب کریں'
                    : 'Take a clear photo of the payment screenshot or choose from gallery',
                style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: HomeEaseTheme.brand),
                ),
                title: Text(
                  isUrdu ? 'کیمرے سے تصویر لیں' : 'Take Photo (Camera)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  isUrdu ? 'کیمرہ استعمال کریں' : 'Use device camera to snap receipt',
                  style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadReceipt(ImageSource.camera);
                },
              ),
              const Divider(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.mintSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: HomeEaseTheme.brand),
                ),
                title: Text(
                  isUrdu ? 'گیلری سے منتخب کریں' : 'Choose from Gallery',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  isUrdu ? 'موبائل گیلری سے اپ لوڈ کریں' : 'Select from photo library',
                  style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadReceipt(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadReceipt(ImageSource source) async {
    final localPath = await HardwareInteroperability.pickImage(source: source);
    if (localPath == null) return;

    if (!mounted) return;
    setState(() {
      _receiptAttachmentPath = localPath;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.isUrdu
            ? 'رسید کی تصویر منسلک ہو گئی۔'
            : 'Receipt screenshot attached successfully.'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Asynchronously attempt upload to Supabase Storage bucket 'receipts'
    final uploadedPath = await HardwareInteroperability.uploadPhotoToStorage(
      filePath: localPath,
      bucket: 'receipts',
    );
    if (mounted && _receiptAttachmentPath == localPath) {
      setState(() {
        _receiptAttachmentPath = uploadedPath;
      });
    }
  }

  Widget _buildThumbnailPreview(String path, VoidCallback onRemove, {required bool isUrdu}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HomeEaseTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeEaseTheme.brand, width: 1.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _buildImageWidget(path),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: HomeEaseTheme.statusVerified, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      isUrdu ? 'رسید منسلک ہو گئی' : 'Receipt Attached',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: HomeEaseTheme.brand,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  path.split(RegExp(r'[/\\]')).last,
                  style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.delete_outline_rounded, color: HomeEaseTheme.statusConflict, size: 22),
            tooltip: isUrdu ? 'رسید ہٹائیں' : 'Remove receipt',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackThumb(),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackThumb(),
      );
    }
    return _fallbackThumb();
  }

  Widget _fallbackThumb() {
    return Container(
      color: HomeEaseTheme.mintSoft,
      alignment: Alignment.center,
      child: const Icon(Icons.receipt_long_rounded, color: HomeEaseTheme.brand, size: 28),
    );
  }

  void _verifyArrivalOtp() {
    final entered = _otpController.text.trim();
    if (entered == widget.booking.arrivalOtp) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStatus = 'In Progress';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.tr('otpVerified'))),
      );
      widget.onVerifyArrival?.call();
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.tr('otpMismatch'))),
      );
    }
  }

  Future<void> _openPaymentGateway() async {
    final result = await PaymentGatewaySheet.show(
      context: context,
      booking: widget.booking,
      worker: widget.worker,
      simulationDuration: widget.simulationDuration,
    );

    if (result != null && result.success && mounted) {
      _lastPaymentResult = result;
      try {
        await BookingRepository().completeBookingPayment(
          bookingId: widget.booking.id,
          paymentMethod: result.mode.dbValue,
          txId: result.txId,
        );
      } catch (e) {
        debugPrint('BookingRepository.completeBookingPayment error: $e');
      }

      if (mounted) {
        setState(() {
          _currentStatus = 'Completed';
        });

        widget.onPaymentCompleted?.call(result);

        await DigitalReceiptDialog.show(
          context,
          paymentResult: result,
          booking: widget.booking,
          worker: widget.worker,
        );
      }
    }
  }

  void _viewDigitalReceipt() {
    final result = _lastPaymentResult ??
        PaymentResult(
          success: true,
          txId: 'EP-${widget.booking.id.hashCode.abs().toString().padLeft(8, '0').substring(0, 8)}',
          mode: widget.booking.paymentMethod.toLowerCase() == 'jazzcash'
              ? PaymentMode.jazzcash
              : widget.booking.paymentMethod.toLowerCase() == 'stripe'
                  ? PaymentMode.stripe
                  : widget.booking.paymentMethod.toLowerCase() == 'cash'
                      ? PaymentMode.cod
                      : PaymentMode.easypaisa,
          amount: widget.booking.agreedAmount,
          timestamp: DateTime.now(),
          payerIdentifier: 'HomeEase Escrow',
          brand: 'Verified Escrow',
        );

    DigitalReceiptDialog.show(
      context,
      paymentResult: result,
      booking: widget.booking,
      worker: widget.worker,
    );
  }

  void _showReceiptDialog(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Receipt Proof',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: HomeEaseTheme.brand),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380, maxWidth: double.infinity),
                  child: _buildImageWidget(path),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openP2PPayment() async {
    final activeBooking = _updatedBooking ?? widget.booking;
    final updated = await P2PPaymentSheet.show(
      context: context,
      booking: activeBooking,
      worker: widget.worker,
      onPaymentSent: (b) {
        setState(() {
          _updatedBooking = b;
          _currentPaymentStatus = 'payment_sent';
          _receiptAttachmentPath = b.receiptUrl;
          if (b.transactionId != null && b.transactionId!.isNotEmpty) {
            _txController.text = b.transactionId!;
          }
        });
        widget.onSubmitReceipt(b.transactionId ?? 'TRX-P2P', b.receiptUrl ?? '');
      },
    );

    if (updated != null && mounted) {
      setState(() {
        _updatedBooking = updated;
        _currentPaymentStatus = 'payment_sent';
        _receiptAttachmentPath = updated.receiptUrl;
      });
    }
  }

  Future<void> _workerConfirmPayment() async {
    final activeBooking = _updatedBooking ?? widget.booking;
    try {
      final updated = await BookingRepository().confirmPaymentReceived(
        bookingId: activeBooking.id,
        txId: activeBooking.transactionId ?? _txController.text.trim(),
        paymentMethod: activeBooking.paymentMethod,
      );
      if (!mounted) return;
      setState(() {
        _updatedBooking = updated;
        _currentStatus = 'Completed';
        _currentPaymentStatus = 'confirmed';
      });

      final result = PaymentResult(
        success: true,
        txId: updated.transactionId ??
            (activeBooking.transactionId?.isNotEmpty == true
                ? activeBooking.transactionId!
                : 'P2P-${activeBooking.id.hashCode.abs().toString().padLeft(8, '0').substring(0, 8)}'),
        mode: activeBooking.paymentMethod.toLowerCase() == 'jazzcash'
            ? PaymentMode.jazzcash
            : activeBooking.paymentMethod.toLowerCase() == 'bank_transfer'
                ? PaymentMode.stripe
                : activeBooking.paymentMethod.toLowerCase() == 'cash'
                    ? PaymentMode.cod
                    : PaymentMode.easypaisa,
        amount: activeBooking.agreedAmount,
        timestamp: DateTime.now(),
        payerIdentifier: 'Household Transfer',
        brand: 'P2P Escrow Released',
      );

      _lastPaymentResult = result;

      widget.onConfirmPayment();

      await DigitalReceiptDialog.show(
        context,
        paymentResult: result,
        booking: updated,
        worker: widget.worker,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming payment: $e')),
      );
    }
  }

  Future<void> _workerPaymentNotReceived() async {
    final activeBooking = _updatedBooking ?? widget.booking;
    try {
      await DisputeRepository().createDispute(
        bookingId: activeBooking.id,
        complainantId: activeBooking.workerId,
        respondentId: activeBooking.householdId,
        category: 'Payment Not Received',
        description:
            'Worker reported payment of PKR ${activeBooking.agreedAmount.toStringAsFixed(0)} was not received in their account despite household marking payment_sent.',
        evidencePath: activeBooking.receiptUrl ?? _receiptAttachmentPath,
      );

      final updated = await BookingRepository().updateBookingStatus(activeBooking.id, 'Disputed');
      if (!mounted) return;
      setState(() {
        _updatedBooking = updated;
        _currentStatus = 'Disputed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.isUrdu
              ? 'تنازعہ ایڈمن کو ارسال کر دیا گیا۔'
              : 'Payment dispute filed for administrative arbitration.'),
          backgroundColor: HomeEaseTheme.statusConflict,
        ),
      );

      widget.onRaiseDispute();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting dispute: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final booking = widget.booking;
    final worker = widget.worker;
    final isWorker = widget.isWorker;
    final statusLower = _currentStatus.toLowerCase().replaceAll(' ', '_');
    final isAccepted = statusLower == 'accepted';
    final isInProgress = statusLower == 'in_progress';
    final isCompleted = statusLower == 'completed';
    final isDisputed = statusLower == 'disputed';

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AppScaffold(
        title: LocalizationService.tr('viewAgreement'),
        subtitle: 'Agreement ID: AG-${booking.id.hashCode.abs().toString().take(6)}',
        onBack: widget.onBack,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agreement Terms Card
            HomeEaseCard(
              color: HomeEaseTheme.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUrdu ? 'معاہدے کی شرائط' : 'Agreement Terms',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: HomeEaseTheme.brand,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This binding agreement covers the domestic service request for the category "${worker.role}" to be performed on ${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year} between ${booking.startTime.format(context)} and ${booking.endTime.format(context)} at ${booking.address}.\n\n'
                    'Agreed rate: PKR ${booking.agreedAmount.toStringAsFixed(0)}.\n'
                    'Service scope: General house tasks as requested in booking notes: "${booking.notes.isNotEmpty ? booking.notes : 'No extra notes provided.'}"\n\n'
                    'Cancellation: Allowed up to 2 hours before the service starts.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: HomeEaseTheme.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!isWorker) ...[
              // =================== Household View ===================
              if (isAccepted || isInProgress) ...[
                // Arrival OTP Card for Household
                HomeEaseCard(
                  color: HomeEaseTheme.brand.withValues(alpha: 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: HomeEaseTheme.brand,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.security_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationService.tr('arrivalOtpTitle'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: HomeEaseTheme.brand,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  LocalizationService.tr('shareOnArrival'),
                                  style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: HomeEaseTheme.brand, width: 1.5),
                            ),
                            child: Text(
                              booking.arrivalOtp,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: HomeEaseTheme.brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        LocalizationService.tr('arrivalInstructions'),
                        style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Escrow Hold Banner for Household (When payment has been marked sent)
                if (_currentPaymentStatus == 'payment_sent') ...[
                  HomeEaseCard(
                    color: const Color(0xFFFEF3C7), // Amber 100
                    child: Row(
                      children: [
                        const Icon(Icons.lock_clock_rounded, color: Color(0xFFB45309), size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUrdu ? 'ایسکرو ہولڈ فعال ہے (ادائیگی بھیج دی گئی)' : 'Escrow Hold Active (Payment Sent)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isUrdu
                                    ? 'آپ کی رسید جمع ہو چکی ہے۔ ورکر کے اپنے اکاؤنٹ میں رقم کی تصدیق کا انتظار ہے۔'
                                    : 'Payment receipt uploaded. Funds are held in escrow until worker confirms receipt.',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Primary: Instant Payment Gateway (Recommended)
                HomeEaseCard(
                  color: HomeEaseTheme.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: HomeEaseTheme.brand.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.flash_on_rounded, color: HomeEaseTheme.brand, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationService.tr('instantPaymentTitle'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: HomeEaseTheme.brand,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Easypaisa • JazzCash • Stripe Card • P2P Escrow',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: HomeEaseTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        LocalizationService.tr('instantPaymentSubtitle'),
                        style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      HomeEaseButton(
                        label: LocalizationService.tr('payViaGateway'),
                        onPressed: _openPaymentGateway,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          key: const Key('open_p2p_payment_button'),
                          onPressed: _openP2PPayment,
                          icon: const Icon(Icons.currency_exchange_rounded, size: 18),
                          label: Text(
                            isUrdu ? 'پی ٹو پی ایسکرو ادائیگی' : 'Pay via P2P Escrow',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HomeEaseTheme.brand,
                            side: const BorderSide(color: HomeEaseTheme.brand, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Secondary / Manual: Submit Payment Receipt Card (Enabled for Accepted & In Progress)
                HomeEaseCard(
                  color: HomeEaseTheme.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(isUrdu ? 'ادائیگی کی رسید جمع کرائیں' : 'Submit Payment Receipt'),
                      const SizedBox(height: 8),
                      Text(
                        'Please transfer PKR ${booking.agreedAmount.toStringAsFixed(0)} manually to the worker via EasyPaisa or JazzCash:\n\n'
                        '• Account Title: ${worker.name}\n'
                        '• Mobile Number: ${worker.phone ?? '0312-3456789'}\n\n'
                        'Once done, enter the transaction ID/reference and select the receipt picture.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _txController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Transaction Reference ID (e.g. 918237198)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _receiptAttachmentPath != null
                          ? _buildThumbnailPreview(
                              _receiptAttachmentPath!,
                              () {
                                setState(() {
                                  _receiptAttachmentPath = null;
                                });
                              },
                              isUrdu: isUrdu,
                            )
                          : GestureDetector(
                              onTap: _attachReceiptPhoto,
                              child: Container(
                                height: 96,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: HomeEaseTheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: HomeEaseTheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_rounded, color: HomeEaseTheme.brand, size: 30),
                                    const SizedBox(height: 6),
                                    Text(
                                      isUrdu ? 'رسید کی تصویر منسلک کرنے کے لیے ٹیپ کریں' : 'Tap to attach receipt screenshot',
                                      style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),
                      HomeEaseButton(
                        label: isUrdu ? 'رسید جمع کرائیں' : 'Submit Payment Receipt',
                        onPressed: () async {
                          if (_receiptAttachmentPath == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please attach the receipt screenshot.')),
                            );
                            return;
                          }
                          final txId = _txController.text.trim().isNotEmpty
                              ? _txController.text.trim()
                              : 'TXN-${DateTime.now().millisecondsSinceEpoch}';

                          try {
                            final updated = await BookingRepository().markPaymentSent(
                              bookingId: widget.booking.id,
                              paymentMethod: 'easypaisa',
                              receiptPath: _receiptAttachmentPath,
                              transactionId: txId,
                            );
                            if (mounted) {
                              setState(() {
                                _updatedBooking = updated;
                                _currentPaymentStatus = 'payment_sent';
                              });
                            }
                          } catch (_) {}

                          widget.onSubmitReceipt(txId, _receiptAttachmentPath!);
                        },
                      ),
                    ],
                  ),
                ),
              ] else if (isCompleted) ...[
                HomeEaseCard(
                  color: HomeEaseTheme.statusVerified.withValues(alpha: 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: HomeEaseTheme.statusVerified, size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isUrdu ? 'ادائیگی مکمل ہو گئی' : 'Payment Confirmed',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: HomeEaseTheme.statusVerified,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isUrdu ? 'یہ سروس کامیابی سے مکمل ہو گئی ہے۔ ہوم ایز استعمال کرنے کا شکریہ!' : 'This service is completed. Thank you for using HomeEase!',
                                  style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      HomeEaseButton(
                        label: LocalizationService.tr('viewReceipt'),
                        icon: Icons.receipt_long_rounded,
                        onPressed: _viewDigitalReceipt,
                      ),
                    ],
                  ),
                ),
              ] else if (isDisputed) ...[
                HomeEaseCard(
                  color: HomeEaseTheme.statusConflict.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel_rounded, color: HomeEaseTheme.statusConflict, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUrdu ? 'معاملہ زیر تفتیش ہے' : 'Transaction Under Dispute',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: HomeEaseTheme.statusConflict,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isUrdu ? 'اس بکنگ کے خلاف تنازعہ درج کر دیا گیا ہے۔ ایڈمن ٹیم شواہد کا جائزہ لے رہی ہے۔' : 'A dispute has been opened for this booking. Admin is currently reviewing payment evidence.',
                              style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                HomeEaseCard(
                  color: HomeEaseTheme.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: HomeEaseTheme.brandSoft),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Booking Status: $_currentStatus',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isUrdu ? 'اگر ورکر نے کام قبول کر لیا ہے تو آپ یہاں ادائیگی جمع کرا سکتے ہیں۔' : 'If the worker accepted the job, you will be prompted to submit payment details here.',
                        style: const TextStyle(fontSize: 12, color: HomeEaseTheme.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // =================== Worker View ===================
              if (isAccepted) ...[
                // Arrival OTP Verification Card for Worker (When Accepted)
                HomeEaseCard(
                  color: HomeEaseTheme.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: HomeEaseTheme.brand.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.pin_rounded, color: HomeEaseTheme.brand, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationService.tr('verifyArrival'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: HomeEaseTheme.textPrimary),
                                ),
                                Text(
                                  isUrdu ? 'سروس شروع کرنے کے لیے گھریلو صارف سے کوڈ مانگیں' : 'Ask household employer for 4-digit OTP to start service',
                                  style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: InputDecoration(
                          counterText: '',
                          prefixIcon: const Icon(Icons.key_rounded, color: HomeEaseTheme.brand),
                          hintText: LocalizationService.tr('enterArrivalOtp'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _verifyArrivalOtp,
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text(
                            LocalizationService.tr('verifyArrival'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: HomeEaseTheme.brand,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (isAccepted || isInProgress) ...[
                // Payment Receipt Review & Confirmation Card (Binance P2P Escrow)
                HomeEaseCard(
                  color: HomeEaseTheme.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0B90B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: Color(0xFFB48500), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isUrdu ? 'ادائیگی کی رسید کا جائزہ' : 'Review Payment Receipt',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: HomeEaseTheme.brand,
                                  ),
                                ),
                                Text(
                                  isUrdu ? 'گھریلو صارف کی جانب سے بھیجی گئی رقم کی تصدیق کریں' : 'Verify incoming transfer from household',
                                  style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_currentPaymentStatus == 'payment_sent') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_rounded, color: Color(0xFFB45309), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUrdu ? 'ادائیگی بھیج دی گئی (ایسکرو ہولڈ)' : 'Payment Sent (Escrow Hold Active)',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isUrdu
                                          ? 'براہ کرم اپنے اکاؤنٹ میں رقم کی تصدیق کریں۔ تسلی ہونے پر "ادائیگی موصول ہو گئی" دبائیں۔'
                                          : 'Check your account before releasing escrow. If funds are not received, tap "Payment Not Received".',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: HomeEaseTheme.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.receipt_long_rounded, color: HomeEaseTheme.brand, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Payment Submission Details',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('• Reference / TRX ID: ${booking.transactionId ?? (_txController.text.isNotEmpty ? _txController.text : 'TXN-${booking.id.hashCode.abs().toString().take(8)}')}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('• Agreed Amount: PKR ${booking.agreedAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: HomeEaseTheme.brand)),
                            const SizedBox(height: 2),
                            Text('• Channel: ${booking.paymentMethod.toUpperCase()}',
                                style: const TextStyle(fontSize: 12.5)),
                            const SizedBox(height: 12),

                            // Receipt Thumbnail Preview with tap-to-expand
                            if (booking.receiptUrl != null || _receiptAttachmentPath != null) ...[
                              InkWell(
                                onTap: () => _showReceiptDialog(
                                  context,
                                  booking.receiptUrl ?? _receiptAttachmentPath!,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: HomeEaseTheme.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: HomeEaseTheme.brand.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 54,
                                          height: 54,
                                          child: _buildImageWidget(booking.receiptUrl ?? _receiptAttachmentPath!),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.zoom_in_rounded, size: 16, color: HomeEaseTheme.brand),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Receipt Screenshot Attached',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: HomeEaseTheme.brand),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isUrdu ? 'بڑی تصویر دیکھنے کے لیے ٹیپ کریں' : 'Tap to preview full screenshot',
                                              style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: HomeEaseTheme.muted),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 18, color: HomeEaseTheme.muted),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isUrdu
                                            ? 'گھریلو صارف کی جانب سے رسید کی تصویر کا انتظار ہے۔'
                                            : 'Awaiting receipt attachment from household employer.',
                                        style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Two P2P Action Buttons: 'Payment Not Received' & 'Confirm Payment Received'
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('worker_payment_not_received_button'),
                              icon: const Icon(Icons.report_problem_outlined, size: 18),
                              onPressed: _workerPaymentNotReceived,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: HomeEaseTheme.statusConflict,
                                side: const BorderSide(color: HomeEaseTheme.statusConflict, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              label: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUrdu ? 'رقم نہیں ملی' : 'Payment Not Received',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                  Text(
                                    isUrdu ? 'تنازعہ درج کریں' : 'Raise Dispute',
                                    style: const TextStyle(fontSize: 10, color: HomeEaseTheme.statusConflict),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              key: const Key('worker_confirm_payment_button'),
                              icon: const Icon(Icons.check_circle_rounded, size: 18),
                              onPressed: _workerConfirmPayment,
                              style: FilledButton.styleFrom(
                                backgroundColor: HomeEaseTheme.statusVerified,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              label: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUrdu ? 'ادائیگی موصول ہو گئی' : 'Confirm Payment Received',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                  Text(
                                    isUrdu ? 'ادائیگی کی تصدیق کریں' : 'Confirm Payment',
                                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (isCompleted) ...[
                HomeEaseCard(
                  color: HomeEaseTheme.statusVerified.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: HomeEaseTheme.statusVerified, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUrdu ? 'ادائیگی مکمل ہو گئی' : 'Payment Confirmed',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: HomeEaseTheme.statusVerified,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isUrdu ? 'یہ سروس مکمل ہو گئی ہے اور رقم کی تصدیق ہو چکی ہے۔' : 'This service is completed and payment has been confirmed.',
                              style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                HomeEaseCard(
                  color: HomeEaseTheme.white,
                  child: Text(
                    'Booking Status for Worker: $_currentStatus',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
