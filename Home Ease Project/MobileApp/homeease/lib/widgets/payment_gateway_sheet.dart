import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';

/// Available payment channels in HomeEase.
enum PaymentMode {
  easypaisa,
  jazzcash,
  stripe,
  cod;

  String get displayName {
    switch (this) {
      case PaymentMode.easypaisa:
        return 'Easypaisa';
      case PaymentMode.jazzcash:
        return 'JazzCash';
      case PaymentMode.stripe:
        return 'Credit / Debit Card';
      case PaymentMode.cod:
        return 'Cash on Delivery';
    }
  }

  String get dbValue {
    switch (this) {
      case PaymentMode.easypaisa:
        return 'easypaisa';
      case PaymentMode.jazzcash:
        return 'jazzcash';
      case PaymentMode.stripe:
        return 'stripe';
      case PaymentMode.cod:
        return 'cash';
    }
  }
}

/// Result returned upon completing a payment transaction.
class PaymentResult {
  final bool success;
  final String txId;
  final PaymentMode mode;
  final double amount;
  final DateTime timestamp;
  final String? payerIdentifier;
  final String? brand;

  const PaymentResult({
    required this.success,
    required this.txId,
    required this.mode,
    required this.amount,
    required this.timestamp,
    this.payerIdentifier,
    this.brand,
  });
}

/// Multi-mode realistic Pakistani and Global payment gateway bottom sheet.
class PaymentGatewaySheet extends StatefulWidget {
  const PaymentGatewaySheet({
    super.key,
    required this.booking,
    required this.worker,
    required this.onPaymentSuccess,
    this.initialMode = PaymentMode.easypaisa,
    this.simulationDuration = const Duration(seconds: 2),
  });

  final Booking booking;
  final WorkerProfile worker;
  final void Function(PaymentResult result) onPaymentSuccess;
  final PaymentMode initialMode;
  final Duration simulationDuration;

  /// Helper to display the payment gateway modal sheet.
  static Future<PaymentResult?> show({
    required BuildContext context,
    required Booking booking,
    required WorkerProfile worker,
    PaymentMode initialMode = PaymentMode.easypaisa,
    Duration simulationDuration = const Duration(seconds: 2),
  }) {
    return showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentGatewaySheet(
        booking: booking,
        worker: worker,
        initialMode: initialMode,
        simulationDuration: simulationDuration,
        onPaymentSuccess: (result) {
          Navigator.of(ctx).pop(result);
        },
      ),
    );
  }

  // ================= Static Validation & Helper Functions =================

  /// Validates Pakistani mobile numbers (exactly 11 digits starting with 03).
  static bool isValidPakistaniMobile(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^03[0-9]{9}$').hasMatch(clean);
  }

  /// Validates Easypaisa 5-digit PIN.
  static bool isValidEasypaisaPin(String pin) {
    return RegExp(r'^[0-9]{5}$').hasMatch(pin);
  }

  /// Validates JazzCash 4-digit MPIN.
  static bool isValidJazzCashMpin(String mpin) {
    return RegExp(r'^[0-9]{4}$').hasMatch(mpin);
  }

  /// Validates 16-digit card number using the Luhn checksum algorithm.
  static bool isValidLuhn(String number) {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 16) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = clean.length - 1; i >= 0; i--) {
      int n = int.parse(clean[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return (sum % 10 == 0);
  }

  /// Detects card brand (Visa, Mastercard, or Generic).
  static String detectCardBrand(String number) {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('4')) return 'Visa';
    if (clean.length >= 2) {
      final prefix2 = int.tryParse(clean.substring(0, 2)) ?? 0;
      if (prefix2 >= 51 && prefix2 <= 55) return 'Mastercard';
      if (prefix2 >= 22 && prefix2 <= 27) return 'Mastercard';
    }
    return 'Generic';
  }

  /// Validates MM/YY card expiry (month 01-12, year >= current 2-digit year).
  static bool isValidExpiry(String expiry) {
    final clean = expiry.replaceAll(RegExp(r'[\s/]'), '');
    if (clean.length != 4) return false;
    final month = int.tryParse(clean.substring(0, 2));
    final year = int.tryParse(clean.substring(2, 4));
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    // Current year baseline is 2026 -> 26
    if (year < 26) return false;
    return true;
  }

  /// Validates CVC (3 or 4 digits).
  static bool isValidCvc(String cvc) {
    return RegExp(r'^[0-9]{3,4}$').hasMatch(cvc);
  }

  /// Generates authentic transaction IDs according to platform standards.
  static String generateTxId(PaymentMode mode) {
    final random = Random();
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String randomChars(int length) {
      return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    }

    switch (mode) {
      case PaymentMode.easypaisa:
        return 'EP-${randomChars(8)}';
      case PaymentMode.jazzcash:
        return 'JC-${randomChars(8)}';
      case PaymentMode.stripe:
        return 'ch_3M${randomChars(21)}';
      case PaymentMode.cod:
        return 'COD-${randomChars(8)}';
    }
  }

  @override
  State<PaymentGatewaySheet> createState() => _PaymentGatewaySheetState();
}

class _PaymentGatewaySheetState extends State<PaymentGatewaySheet> {
  late PaymentMode _selectedMode;

  // Controllers
  final TextEditingController _epPhoneController = TextEditingController();
  final TextEditingController _epPinController = TextEditingController();

  final TextEditingController _jcPhoneController = TextEditingController();
  final TextEditingController _jcPinController = TextEditingController();

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvcController = TextEditingController();

  bool _obscureEpPin = true;
  bool _obscureJcPin = true;
  bool _obscureCardCvc = true;
  bool _codAcknowledged = false;
  bool _isProcessing = false;

  String? _epPhoneError;
  String? _epPinError;
  String? _jcPhoneError;
  String? _jcPinError;
  String? _cardError;
  String? _expiryError;
  String? _cvcError;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _cardNumberController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _epPhoneController.dispose();
    _epPinController.dispose();
    _jcPhoneController.dispose();
    _jcPinController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    super.dispose();
  }

  // ================= Submit Handlers per Mode =================

  Future<void> _handleEasypaisaPay() async {
    final phone = _epPhoneController.text.trim();
    final pin = _epPinController.text.trim();

    setState(() {
      _epPhoneError = PaymentGatewaySheet.isValidPakistaniMobile(phone)
          ? null
          : 'Enter valid 11-digit mobile (03XXXXXXXXX)';
      _epPinError = PaymentGatewaySheet.isValidEasypaisaPin(pin)
          ? null
          : 'Enter 5-digit Easypaisa PIN';
    });

    if (_epPhoneError != null || _epPinError != null) return;

    final amount = widget.booking.agreedAmount;
    final isUrdu = LocalizationService.isUrdu;

    // Show simulated USSD Push modal dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        Timer? timer;
        timer = Timer(widget.simulationDuration, () {
          if (dialogCtx.mounted && Navigator.of(dialogCtx).canPop()) {
            Navigator.of(dialogCtx).pop(true);
          }
        });

        return PopScope(
          onPopInvokedWithResult: (_, __) => timer?.cancel(),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A859).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phonelink_ring_rounded, color: Color(0xFF00A859), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isUrdu ? 'ایزی پیسہ یو ایس ایس ڈی پش تصدیق' : 'Easypaisa USSD Push Authorization',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isUrdu
                      ? 'ہوم ایز ایسکرو کو روپے ${amount.toStringAsFixed(0)} ادا کرنے کے لیے اپنے موبائل پر پن درج کریں۔'
                      : 'Enter PIN on your mobile to authorize payment of PKR ${amount.toStringAsFixed(0)} to HomeEase Escrow',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A859)),
                ),
                const SizedBox(height: 12),
                Text(
                  isUrdu ? 'نیٹ ورک کا انتظار ہے...' : 'Awaiting USSD prompt approval on SIM...',
                  style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.of(dialogCtx).pop(true);
                },
                child: const Text('Authorize USSD Push', style: TextStyle(color: Color(0xFF00A859))),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      final txId = PaymentGatewaySheet.generateTxId(PaymentMode.easypaisa);
      final result = PaymentResult(
        success: true,
        txId: txId,
        mode: PaymentMode.easypaisa,
        amount: amount,
        timestamp: DateTime.now(),
        payerIdentifier: phone,
        brand: 'Easypaisa',
      );
      widget.onPaymentSuccess(result);
    }
  }

  Future<void> _handleJazzCashPay() async {
    final phone = _jcPhoneController.text.trim();
    final pin = _jcPinController.text.trim();

    setState(() {
      _jcPhoneError = PaymentGatewaySheet.isValidPakistaniMobile(phone)
          ? null
          : 'Enter valid 11-digit mobile (03XXXXXXXXX)';
      _jcPinError = PaymentGatewaySheet.isValidJazzCashMpin(pin)
          ? null
          : 'Enter 4-digit JazzCash MPIN';
    });

    if (_jcPhoneError != null || _jcPinError != null) return;

    final amount = widget.booking.agreedAmount;
    final isUrdu = LocalizationService.isUrdu;

    // Show simulated 2-second processing spinner dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        Timer? timer;
        timer = Timer(widget.simulationDuration, () {
          if (dialogCtx.mounted && Navigator.of(dialogCtx).canPop()) {
            Navigator.of(dialogCtx).pop(true);
          }
        });

        return PopScope(
          onPopInvokedWithResult: (_, __) => timer?.cancel(),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isUrdu ? 'جاز کیش ٹرانزیکشن پروسیس ہو رہی ہے...' : 'Connecting to JazzCash Gateway & Verifying MPIN...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PKR ${amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFF6600)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.of(dialogCtx).pop(true);
                },
                child: const Text('Complete Verification', style: TextStyle(color: Color(0xFFFF6600))),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      final txId = PaymentGatewaySheet.generateTxId(PaymentMode.jazzcash);
      final result = PaymentResult(
        success: true,
        txId: txId,
        mode: PaymentMode.jazzcash,
        amount: amount,
        timestamp: DateTime.now(),
        payerIdentifier: phone,
        brand: 'JazzCash',
      );
      widget.onPaymentSuccess(result);
    }
  }

  Future<void> _handleStripePay() async {
    final card = _cardNumberController.text.trim();
    final expiry = _cardExpiryController.text.trim();
    final cvc = _cardCvcController.text.trim();

    setState(() {
      _cardError = PaymentGatewaySheet.isValidLuhn(card)
          ? null
          : 'Invalid 16-digit card number (Luhn Checksum failed)';
      _expiryError = PaymentGatewaySheet.isValidExpiry(expiry)
          ? null
          : 'Invalid expiry (MM/YY, future year >= 26)';
      _cvcError = PaymentGatewaySheet.isValidCvc(cvc)
          ? null
          : 'Enter valid 3-4 digit CVC';
    });

    if (_cardError != null || _expiryError != null || _cvcError != null) return;

    final amount = widget.booking.agreedAmount;
    final brand = PaymentGatewaySheet.detectCardBrand(card);
    final cleanCard = card.replaceAll(RegExp(r'\D'), '');
    final last4 = cleanCard.length >= 4 ? cleanCard.substring(cleanCard.length - 4) : '0000';
    final isUrdu = LocalizationService.isUrdu;

    // Show 2-second 3D Secure modal OTP dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        Timer? timer;
        timer = Timer(widget.simulationDuration, () {
          if (dialogCtx.mounted && Navigator.of(dialogCtx).canPop()) {
            Navigator.of(dialogCtx).pop(true);
          }
        });

        return PopScope(
          onPopInvokedWithResult: (_, __) => timer?.cancel(),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF635BFF).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF635BFF), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrdu ? 'تھری ڈی سیکیور 2.0 تصدیق' : '3D Secure 2.0 Verification',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Simulated $brand Bank Authentication',
                        style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A one-time passcode has been sent to your registered phone to authorize PKR ${amount.toStringAsFixed(0)} on card •••• $last4.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                const LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF635BFF)),
                  backgroundColor: Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 10),
                Text(
                  isUrdu ? 'بینک کی توثیق جاری ہے...' : 'Authenticating with bank directory server...',
                  style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.of(dialogCtx).pop(true);
                },
                child: const Text('Authorize OTP', style: TextStyle(color: Color(0xFF635BFF))),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      final txId = PaymentGatewaySheet.generateTxId(PaymentMode.stripe);
      final result = PaymentResult(
        success: true,
        txId: txId,
        mode: PaymentMode.stripe,
        amount: amount,
        timestamp: DateTime.now(),
        payerIdentifier: '•••• $last4',
        brand: brand,
      );
      widget.onPaymentSuccess(result);
    }
  }

  void _handleCodPay() {
    if (_isProcessing || !_codAcknowledged) return;
    setState(() {
      _isProcessing = true;
    });

    final amount = widget.booking.agreedAmount;
    final txId = PaymentGatewaySheet.generateTxId(PaymentMode.cod);
    final result = PaymentResult(
      success: true,
      txId: txId,
      mode: PaymentMode.cod,
      amount: amount,
      timestamp: DateTime.now(),
      payerIdentifier: 'Cash',
      brand: 'HomeEase Escrow COD',
    );
    widget.onPaymentSuccess(result);
  }

  // ================= UI Builders =================

  Widget _buildBrandBadge() {
    final brand = PaymentGatewaySheet.detectCardBrand(_cardNumberController.text);
    if (brand == 'Visa') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F71),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      );
    } else if (brand == 'Mastercard') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEB001B),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'MC',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      );
    }
    return const Icon(Icons.credit_card_rounded, color: HomeEaseTheme.muted);
  }

  Widget _buildModePill(PaymentMode mode, String label, IconData icon, Color color) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : HomeEaseTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : HomeEaseTheme.outline,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : HomeEaseTheme.muted, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : HomeEaseTheme.text,
              ),
            ),
          ],
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
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // Sheet Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_outline_rounded, color: HomeEaseTheme.brand, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationService.tr('paymentGatewayTitle'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: HomeEaseTheme.brand,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUrdu
                              ? 'قابل ادا رقم: روپے ${amount.toStringAsFixed(0)}'
                              : 'Total Payable: PKR ${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: HomeEaseTheme.statusVerified,
                          ),
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
              const SizedBox(height: 18),

              // Mode Selector Tabs (Scrollable horizontal row)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildModePill(PaymentMode.easypaisa, 'Easypaisa', Icons.account_balance_wallet_rounded, const Color(0xFF00A859)),
                    const SizedBox(width: 10),
                    _buildModePill(PaymentMode.jazzcash, 'JazzCash', Icons.phone_android_rounded, const Color(0xFFFF6600)),
                    const SizedBox(width: 10),
                    _buildModePill(PaymentMode.stripe, 'Card (Stripe)', Icons.credit_card_rounded, const Color(0xFF635BFF)),
                    const SizedBox(width: 10),
                    _buildModePill(PaymentMode.cod, 'Cash (COD)', Icons.handshake_rounded, const Color(0xFF0F594E)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ================= Mode Form Content =================
              if (_selectedMode == PaymentMode.easypaisa) ...[
                // Easypaisa Form
                TextField(
                  key: const Key('easypaisa_phone_field'),
                  controller: _epPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                  decoration: InputDecoration(
                    labelText: LocalizationService.tr('mobileNumber'),
                    hintText: '03XXXXXXXXX',
                    prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF00A859)),
                    errorText: _epPhoneError,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('easypaisa_pin_field'),
                  controller: _epPinController,
                  obscureText: _obscureEpPin,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                  decoration: InputDecoration(
                    labelText: LocalizationService.tr('easypaisaPin'),
                    hintText: '•••••',
                    prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFF00A859)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureEpPin ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscureEpPin = !_obscureEpPin),
                    ),
                    errorText: _epPinError,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('easypaisa_pay_button'),
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    label: Text(
                      'Authorize PKR ${amount.toStringAsFixed(0)} (Easypaisa)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A859),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _handleEasypaisaPay,
                  ),
                ),
              ] else if (_selectedMode == PaymentMode.jazzcash) ...[
                // JazzCash Form
                TextField(
                  key: const Key('jazzcash_phone_field'),
                  controller: _jcPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                  decoration: InputDecoration(
                    labelText: LocalizationService.tr('mobileNumber'),
                    hintText: '03XXXXXXXXX',
                    prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFFFF6600)),
                    errorText: _jcPhoneError,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('jazzcash_pin_field'),
                  controller: _jcPinController,
                  obscureText: _obscureJcPin,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  decoration: InputDecoration(
                    labelText: LocalizationService.tr('jazzcashMpin'),
                    hintText: '••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFFF6600)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureJcPin ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscureJcPin = !_obscureJcPin),
                    ),
                    errorText: _jcPinError,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('jazzcash_pay_button'),
                    icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                    label: Text(
                      'Pay PKR ${amount.toStringAsFixed(0)} via JazzCash',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _handleJazzCashPay,
                  ),
                ),
              ] else if (_selectedMode == PaymentMode.stripe) ...[
                // Stripe Card Form
                TextField(
                  key: const Key('stripe_card_field'),
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                  decoration: InputDecoration(
                    labelText: LocalizationService.tr('cardNumber'),
                    hintText: '4242 4242 4242 4242',
                    prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFF635BFF)),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [_buildBrandBadge()],
                      ),
                    ),
                    errorText: _cardError,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('stripe_expiry_field'),
                        controller: _cardExpiryController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [LengthLimitingTextInputFormatter(5)],
                        decoration: InputDecoration(
                          labelText: LocalizationService.tr('expiryDate'),
                          hintText: 'MM/YY',
                          prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF635BFF), size: 18),
                          errorText: _expiryError,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        key: const Key('stripe_cvc_field'),
                        controller: _cardCvcController,
                        obscureText: _obscureCardCvc,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                        decoration: InputDecoration(
                          labelText: LocalizationService.tr('cvc'),
                          hintText: '123',
                          prefixIcon: const Icon(Icons.security_rounded, color: Color(0xFF635BFF), size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCardCvc ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                            onPressed: () => setState(() => _obscureCardCvc = !_obscureCardCvc),
                          ),
                          errorText: _cvcError,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('stripe_pay_button'),
                    icon: const Icon(Icons.lock_rounded, color: Colors.white),
                    label: Text(
                      'Pay PKR ${amount.toStringAsFixed(0)} via Stripe',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF635BFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _handleStripePay,
                  ),
                ),
              ] else if (_selectedMode == PaymentMode.cod) ...[
                // COD Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.mintSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HomeEaseTheme.brand.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: HomeEaseTheme.brand, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            LocalizationService.tr('codHeader'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: HomeEaseTheme.brand,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You agree to pay PKR ${amount.toStringAsFixed(0)} in cash directly to ${widget.worker.name} upon successful completion of the domestic service at your premises.',
                        style: const TextStyle(fontSize: 13, height: 1.4, color: HomeEaseTheme.text),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        LocalizationService.tr('codEscrowGuarantee'),
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: HomeEaseTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  key: const Key('cod_checkbox_tile'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _codAcknowledged = !_codAcknowledged;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Checkbox(
                            value: _codAcknowledged,
                            activeColor: HomeEaseTheme.brand,
                            onChanged: (val) {
                              setState(() {
                                _codAcknowledged = val ?? false;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: Text(
                            isUrdu
                                ? 'میں کام مکمل ہونے پر نقد رقم ادا کرنے کا اقرار کرتا ہوں۔'
                                : 'I acknowledge and agree to settle PKR ${amount.toStringAsFixed(0)} in cash upon completion.',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('cod_pay_button'),
                    icon: const Icon(Icons.handshake_rounded, color: Colors.white),
                    label: Text(
                      LocalizationService.tr('confirmCod'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_codAcknowledged && !_isProcessing) ? HomeEaseTheme.brand : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: (_codAcknowledged && !_isProcessing) ? _handleCodPay : null,
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
