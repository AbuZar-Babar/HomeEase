import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import 'payment_gateway_sheet.dart';

/// Serene Hearth Branded Digital Payment Receipt Dialog with watermark and verified escrow proof.
class DigitalReceiptDialog extends StatelessWidget {
  const DigitalReceiptDialog({
    super.key,
    required this.paymentResult,
    required this.booking,
    required this.worker,
    this.onDismiss,
  });

  final PaymentResult paymentResult;
  final Booking booking;
  final WorkerProfile worker;
  final VoidCallback? onDismiss;

  /// Helper to display the Serene Hearth digital receipt modal dialog.
  static Future<void> show(
    BuildContext context, {
    required PaymentResult paymentResult,
    required Booking booking,
    required WorkerProfile worker,
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DigitalReceiptDialog(
        paymentResult: paymentResult,
        booking: booking,
        worker: worker,
        onDismiss: () {
          Navigator.of(ctx).pop();
          onDismiss?.call();
        },
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute PKT';
  }

  Widget _buildModeBadge() {
    Color bg;
    Color fg;
    IconData icon;
    String label = paymentResult.mode.displayName;

    switch (paymentResult.mode) {
      case PaymentMode.easypaisa:
        bg = const Color(0xFF00A859).withValues(alpha: 0.12);
        fg = const Color(0xFF00A859);
        icon = Icons.account_balance_wallet_rounded;
        break;
      case PaymentMode.jazzcash:
        bg = const Color(0xFFFF6600).withValues(alpha: 0.12);
        fg = const Color(0xFFFF6600);
        icon = Icons.phone_android_rounded;
        break;
      case PaymentMode.stripe:
        bg = const Color(0xFF635BFF).withValues(alpha: 0.12);
        fg = const Color(0xFF635BFF);
        icon = Icons.credit_card_rounded;
        if (paymentResult.brand != null && paymentResult.brand!.isNotEmpty) {
          label = '${paymentResult.brand} Card';
        }
        break;
      case PaymentMode.cod:
        bg = HomeEaseTheme.brand.withValues(alpha: 0.12);
        fg = HomeEaseTheme.brand;
        icon = Icons.handshake_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: HomeEaseTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HomeEaseTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final formattedTime = _formatTimestamp(paymentResult.timestamp);
    final serviceDateStr =
        '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}';
    final durationHours = booking.durationHours > 0 ? booking.durationHours : 2;

    return Directionality(
      textDirection: LocalizationService.direction,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: HomeEaseTheme.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Stack(
            children: [
              // Subtle Serene Hearth Watermark
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: 0.06,
                      child: Transform.rotate(
                        angle: -0.26,
                        child: Text(
                          LocalizationService.tr('receiptWatermark'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: HomeEaseTheme.brand,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Foreground Content
              Padding(
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Verified Shield
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.statusVerified.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: HomeEaseTheme.statusVerified,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          LocalizationService.tr('digitalReceiptTitle'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: HomeEaseTheme.brand,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Center(
                        child: Text(
                          LocalizationService.tr('digitalReceiptSubtitle'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: HomeEaseTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // TxID Badge with 1-tap Copy Action
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: HomeEaseTheme.outline),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TRANSACTION ID',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                      color: HomeEaseTheme.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(
                                    paymentResult.txId,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: HomeEaseTheme.brand,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              key: const Key('copy_txid_button'),
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: paymentResult.txId));
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(LocalizationService.tr('txIdCopied')),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.copy_rounded, size: 18, color: HomeEaseTheme.brand),
                                    const SizedBox(width: 4),
                                    Text(
                                      LocalizationService.tr('copyTxId'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: HomeEaseTheme.brand,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Mode Badge & Timestamp
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildModeBadge(),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 11,
                              color: HomeEaseTheme.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amount Highlight Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.mintSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: HomeEaseTheme.brandSoft.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUrdu ? 'ادا شدہ رقم' : 'Amount Settled',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: HomeEaseTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'PKR ${paymentResult.amount.toStringAsFixed(0)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: HomeEaseTheme.brand,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: HomeEaseTheme.statusVerified,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    isUrdu ? 'تصدیق شدہ' : 'Confirmed',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Booking & Worker Summary
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        isUrdu ? 'ورکر کا نام' : 'Worker',
                        '${worker.name} (${worker.role})',
                      ),
                      _buildSummaryRow(
                        isUrdu ? 'علاقہ' : 'Locality',
                        worker.area.isNotEmpty ? '${worker.area}, Abbottabad' : (worker.location.isNotEmpty ? worker.location : 'Abbottabad'),
                      ),
                      _buildSummaryRow(
                        isUrdu ? 'سروس تاریخ' : 'Service Date',
                        '$serviceDateStr • $durationHours hrs',
                      ),
                      _buildSummaryRow(
                        isUrdu ? 'پتہ' : 'Address',
                        booking.address.isNotEmpty ? booking.address : 'Abbottabad Residence',
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      // Action Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          key: const Key('receipt_done_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HomeEaseTheme.brand,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                          child: Text(
                            LocalizationService.tr('done'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
