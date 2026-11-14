import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/booking_repository.dart';
import '../services/hardware_interoperability.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';

/// Available P2P payment channels.
enum P2PPaymentMethod {
  easypaisa,
  jazzcash,
  bankTransfer;

  String get displayName {
    switch (this) {
      case P2PPaymentMethod.easypaisa:
        return 'Easypaisa';
      case P2PPaymentMethod.jazzcash:
        return 'JazzCash';
      case P2PPaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String get dbValue {
    switch (this) {
      case P2PPaymentMethod.easypaisa:
        return 'easypaisa';
      case P2PPaymentMethod.jazzcash:
        return 'jazzcash';
      case P2PPaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }
}

/// Binance P2P-style manual payment and escrow sheet for HomeEase.
///
/// Features:
/// 1. Direct P2P payment channels (Easypaisa, JazzCash, Bank Transfer).
/// 2. Displays recipient worker title and phone/IBAN with 1-tap copy actions.
/// 3. Mandatory receipt screenshot attachment via [HardwareInteroperabilityService.pickImageFromGallery] / [Camera].
/// 4. Optional TRX ID reference field.
/// 5. Updates Booking in [BookingRepository] with paymentStatus='payment_sent' (escrow hold).
class P2PPaymentSheet extends StatefulWidget {
  const P2PPaymentSheet({
    super.key,
    required this.booking,
    required this.worker,
    this.onPaymentSent,
  });

  final Booking booking;
  final WorkerProfile worker;
  final ValueChanged<Booking>? onPaymentSent;

  /// Helper to display the modal bottom sheet.
  static Future<Booking?> show({
    required BuildContext context,
    required Booking booking,
    required WorkerProfile worker,
    ValueChanged<Booking>? onPaymentSent,
  }) {
    return showModalBottomSheet<Booking>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => P2PPaymentSheet(
        booking: booking,
        worker: worker,
        onPaymentSent: onPaymentSent,
      ),
    );
  }

  @override
  State<P2PPaymentSheet> createState() => _P2PPaymentSheetState();
}

class _P2PPaymentSheetState extends State<P2PPaymentSheet> {
  P2PPaymentMethod _selectedMethod = P2PPaymentMethod.easypaisa;
  final TextEditingController _trxController = TextEditingController();
  String? _receiptAttachmentPath;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _trxController.dispose();
    super.dispose();
  }

  // Account details based on selected payment channel
  String get _recipientTitle => widget.worker.name.isNotEmpty ? widget.worker.name : 'Authorized Worker';

  String get _recipientPhone {
    if (widget.worker.phone != null && widget.worker.phone!.isNotEmpty) {
      return widget.worker.phone!;
    }
    return _selectedMethod == P2PPaymentMethod.easypaisa ? '0312-9845120' : '0300-8765432';
  }

  String get _recipientBankName => 'Meezan Bank Limited';
  String get _recipientBranch => 'Abbottabad Main Branch (Code 0102)';

  String get _recipientIban {
    final seed = widget.worker.id.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = (seed.isNotEmpty ? seed : '100123456701').padRight(12, '0').substring(0, 12);
    return 'PK36MEZN00$suffix';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickReceipt(bool fromCamera) async {
    HapticFeedback.selectionClick();
    final path = fromCamera
        ? await HardwareInteroperabilityService.pickImageFromCamera()
        : await HardwareInteroperabilityService.pickImageFromGallery();

    if (path != null && mounted) {
      setState(() {
        _receiptAttachmentPath = path;
        _errorMessage = null;
      });

      // Background upload to Supabase Storage receipts bucket
      HardwareInteroperability.uploadPhotoToStorage(
        filePath: path,
        bucket: 'receipts',
      ).then((uploaded) {
        if (mounted && _receiptAttachmentPath == path) {
          setState(() {
            _receiptAttachmentPath = uploaded;
          });
        }
      });
    }
  }

  void _showImageSourceDialog() {
    final isUrdu = LocalizationService.isUrdu;
    showModalBottomSheet(
      context: context,
      backgroundColor: HomeEaseTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUrdu ? 'رسید کی تصویر منسلک کریں' : 'Attach Receipt Screenshot',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: HomeEaseTheme.brand,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUrdu
                    ? 'تصدیق کے لیے تصویر لینا یا گیلری سے اپ لوڈ کرنا لازمی ہے۔'
                    : 'A clear screenshot of the transfer confirmation is required.',
                style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: HomeEaseTheme.brand),
                ),
                title: Text(isUrdu ? 'کیمرے سے تصویر لیں' : 'Take Photo (Camera)'),
                subtitle: Text(isUrdu ? 'کیمرہ استعمال کریں' : 'Capture using device camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickReceipt(true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.mintSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: HomeEaseTheme.brand),
                ),
                title: Text(isUrdu ? 'گیلری سے منتخب کریں' : 'Choose from Gallery'),
                subtitle: Text(isUrdu ? 'تصویر منتخب کریں' : 'Pick from device gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickReceipt(false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePaymentSent() async {
    // 1. Mandatory Receipt Validation
    if (_receiptAttachmentPath == null || _receiptAttachmentPath!.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = LocalizationService.isUrdu
            ? 'براہ کرم ادائیگی کی رسید کا اسکرین شاٹ منسلک کریں۔'
            : 'Payment receipt screenshot is required before marking Payment Sent.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: HomeEaseTheme.statusConflict,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final updatedBooking = await BookingRepository().markPaymentSent(
        bookingId: widget.booking.id,
        paymentMethod: _selectedMethod.dbValue,
        receiptPath: _receiptAttachmentPath,
        transactionId: _trxController.text.trim().isNotEmpty ? _trxController.text.trim() : null,
      );

      if (!mounted) return;

      widget.onPaymentSent?.call(updatedBooking);
      Navigator.of(context).pop(updatedBooking);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.isUrdu
                ? 'ادائیگی بھیج دی گئی! ایسکرو ہولڈ فعال ہو گیا۔ ورکر کی تصدیق کا انتظار ہے۔'
                : 'Payment marked as sent! Escrow hold activated. Awaiting worker confirmation.',
          ),
          backgroundColor: HomeEaseTheme.brand,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error saving payment status: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  Widget _buildThumbnailPreview(String path) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: HomeEaseTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeEaseTheme.brand, width: 1.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 52,
              child: _buildImage(path),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: HomeEaseTheme.statusVerified, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Receipt Attached',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
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
            icon: const Icon(Icons.close_rounded, color: HomeEaseTheme.statusConflict, size: 20),
            onPressed: () => setState(() => _receiptAttachmentPath = null),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImageThumb(),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImageThumb(),
      );
    }
    return _fallbackImageThumb();
  }

  Widget _fallbackImageThumb() {
    return Container(
      color: HomeEaseTheme.mintSoft,
      alignment: Alignment.center,
      child: const Icon(Icons.receipt_rounded, color: HomeEaseTheme.brand, size: 28),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: HomeEaseTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: HomeEaseTheme.textPrimary,
              ),
            ),
          ),
          if (copyable)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _copyToClipboard(value, label),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.copy_rounded, size: 16, color: HomeEaseTheme.brand),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(P2PPaymentMethod method, String label, IconData icon, Color color) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : HomeEaseTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : HomeEaseTheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : HomeEaseTheme.muted, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : HomeEaseTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final amount = widget.booking.agreedAmount;

    return Directionality(
      textDirection: LocalizationService.direction,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 16,
        ),
        decoration: const BoxDecoration(
          color: HomeEaseTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Binance P2P Header & Escrow Shield
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0B90B).withValues(alpha: 0.15), // Binance Yellow tone
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.currency_exchange_rounded, color: Color(0xFFB48500), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isUrdu ? 'بینانس طرز پی ٹو پی ادائیگی' : 'P2P Escrow Payment',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: HomeEaseTheme.brand,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: HomeEaseTheme.statusVerified.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ESCROW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: HomeEaseTheme.statusVerified,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUrdu
                              ? 'براہ راست ورکر کو ادائیگی • رقم ایسکرو پروٹیکشن میں محفوظ'
                              : 'Pay worker directly • Funds held in escrow hold',
                          style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: HomeEaseTheme.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Amount Card with 1-tap copy
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: HomeEaseTheme.mintSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HomeEaseTheme.brand.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'کل قابل ادا رقم' : 'Amount to Transfer',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: HomeEaseTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PKR ${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: HomeEaseTheme.brand,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(amount.toStringAsFixed(0), 'Amount'),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HomeEaseTheme.brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 36),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Method Selector Tabs (Easypaisa, JazzCash, Bank Transfer)
              Row(
                children: [
                  _buildMethodChip(
                    P2PPaymentMethod.easypaisa,
                    'Easypaisa',
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF00A859),
                  ),
                  const SizedBox(width: 8),
                  _buildMethodChip(
                    P2PPaymentMethod.jazzcash,
                    'JazzCash',
                    Icons.phone_android_rounded,
                    const Color(0xFFFF6600),
                  ),
                  const SizedBox(width: 8),
                  _buildMethodChip(
                    P2PPaymentMethod.bankTransfer,
                    'Bank Transfer',
                    Icons.account_balance_rounded,
                    const Color(0xFF1E3A8A),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recipient Details Card
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
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: HomeEaseTheme.brand, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isUrdu ? 'وصول کنندہ ورکر کی تفصیلات' : 'Recipient Worker Account Details',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: HomeEaseTheme.brand,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildDetailRow('Account Title', _recipientTitle),
                    if (_selectedMethod == P2PPaymentMethod.easypaisa || _selectedMethod == P2PPaymentMethod.jazzcash) ...[
                      _buildDetailRow(
                        _selectedMethod == P2PPaymentMethod.easypaisa ? 'Easypaisa No.' : 'JazzCash No.',
                        _recipientPhone,
                      ),
                    ] else ...[
                      _buildDetailRow('Bank Name', _recipientBankName),
                      _buildDetailRow('Branch', _recipientBranch, copyable: false),
                      _buildDetailRow('IBAN / Acc', _recipientIban),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mandatory Receipt Screenshot Section
              Row(
                children: [
                  const Icon(Icons.attach_file_rounded, size: 18, color: HomeEaseTheme.brand),
                  const SizedBox(width: 6),
                  Text(
                    isUrdu ? 'ادائیگی کا ثبوت (رسید لازمی ہے) *' : 'Payment Proof (Screenshot Mandatory) *',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: HomeEaseTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_receiptAttachmentPath != null)
                _buildThumbnailPreview(_receiptAttachmentPath!)
              else
                InkWell(
                  onTap: _showImageSourceDialog,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 84,
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _errorMessage != null ? HomeEaseTheme.statusConflict : HomeEaseTheme.outline,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_rounded, color: HomeEaseTheme.brand, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            isUrdu
                                ? 'رسید کی تصویر منسلک کریں (کیمرہ یا گیلری)'
                                : 'Tap to attach receipt screenshot (Camera / Gallery)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HomeEaseTheme.brand),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),

              // Optional TRX ID Field
              TextField(
                controller: _trxController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'ٹرانزیکشن ریفرنس / ٹی آر ایکس آئی ڈی (اختیاری)' : 'TRX ID / Reference No. (Optional)',
                  hintText: 'e.g. 98124018241',
                  prefixIcon: const Icon(Icons.tag_rounded, color: HomeEaseTheme.brand),
                ),
              ),
              const SizedBox(height: 16),

              // Escrow notice banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Amber 100
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isUrdu
                            ? 'ایسکرو نوٹس: "Payment Sent" ٹیپ کرنے کے بعد رقم ایسکرو ہولڈ میں رہے گی۔ ورکر اپنے اکاؤنٹ میں رقم کی تصدیق کر کے معاہدہ مکمل کرے گا۔'
                            : 'Escrow Notice: Funds remain in escrow hold upon tapping "Payment Sent". Worker will verify receipt before final release.',
                        style: const TextStyle(fontSize: 11, height: 1.35, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Submit Action Button: 'Payment Sent'
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  key: const Key('p2p_payment_sent_button'),
                  onPressed: _isSubmitting ? null : _handlePaymentSent,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: Text(
                    isUrdu ? 'ادائیگی بھیج دی گئی (ایسکرو ہولڈ)' : 'Payment Sent',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeEaseTheme.brand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
