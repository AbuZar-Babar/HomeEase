import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class ServiceAgreementScreen extends StatefulWidget {
  const ServiceAgreementScreen({
    super.key,
    required this.booking,
    required this.worker,
    required this.isWorker,
    required this.onBack,
    required this.onSubmitReceipt,
    required this.onConfirmPayment,
    required this.onRejectPayment,
    required this.onRaiseDispute,
  });

  final Booking booking;
  final WorkerProfile worker;
  final bool isWorker;
  final VoidCallback onBack;
  final Function(String txId, String receiptPath) onSubmitReceipt;
  final VoidCallback onConfirmPayment;
  final VoidCallback onRejectPayment;
  final VoidCallback onRaiseDispute;

  @override
  State<ServiceAgreementScreen> createState() => _ServiceAgreementScreenState();
}

class _ServiceAgreementScreenState extends State<ServiceAgreementScreen> {
  final TextEditingController _txController = TextEditingController();
  String? _receiptAttachmentPath;

  @override
  void dispose() {
    _txController.dispose();
    super.dispose();
  }

  void _attachReceiptPhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _receiptAttachmentPath = 'receipt_${widget.booking.id.hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt screenshot attached successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final worker = widget.worker;
    final isWorker = widget.isWorker;

    return AppScaffold(
      title: 'Service Agreement',
      subtitle: 'Agreement ID: AG-${booking.id.hashCode.abs().toString().take(6)}',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeEaseCard(
            color: HomeEaseTheme.cardDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agreement Terms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HomeEaseTheme.brand,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This binding agreement covers the domestic service request for the category "${worker.role}" to be performed on ${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year} between ${booking.startTime.format(context)} and ${booking.endTime.format(context)} at ${booking.address}.\n\n'
                  'Agreed rate: ${worker.rate}.\n'
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
            // Household View
            if (booking.status == 'Accepted') ...[
              HomeEaseCard(
                color: HomeEaseTheme.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Submit Payment Receipt'),
                    const SizedBox(height: 8),
                    Text(
                      'Please transfer PKR ${booking.agreedAmount.toStringAsFixed(0)} manually to the worker via EasyPaisa or JazzCash:\n\n'
                      '• Account Title: ${worker.name}\n'
                      '• Mobile Number: 0312-3456789\n\n'
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
                    GestureDetector(
                      onTap: _attachReceiptPhoto,
                      child: Container(
                        height: 96,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _receiptAttachmentPath != null
                              ? HomeEaseTheme.accentLight.withValues(alpha: 0.3)
                              : HomeEaseTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _receiptAttachmentPath != null
                                ? HomeEaseTheme.brand
                                : HomeEaseTheme.outline,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: _receiptAttachmentPath != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: HomeEaseTheme.statusVerified),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Receipt: $_receiptAttachmentPath',
                                      style: const TextStyle(
                                        color: HomeEaseTheme.brand,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: HomeEaseTheme.muted),
                                    onPressed: () {
                                      setState(() {
                                        _receiptAttachmentPath = null;
                                      });
                                    },
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, color: HomeEaseTheme.brand, size: 30),
                                  SizedBox(height: 6),
                                  Text('Tap to attach receipt screenshot', style: TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    HomeEaseButton(
                      label: 'Submit Payment Receipt',
                      onPressed: () {
                        if (_txController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a Transaction Reference ID.')),
                          );
                          return;
                        }
                        if (_receiptAttachmentPath == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please attach the receipt screenshot.')),
                          );
                          return;
                        }
                        Future.delayed(const Duration(milliseconds: 300), () {
                          widget.onSubmitReceipt(_txController.text, _receiptAttachmentPath!);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else if (booking.status == 'Completed') ...[
              HomeEaseCard(
                color: Colors.green.shade50,
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Confirmed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This service is completed. Thank you for using HomeEase!',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (booking.status == 'Disputed') ...[
              HomeEaseCard(
                color: Colors.red.shade50,
                child: const Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: Colors.red, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Under Dispute',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'A dispute has been opened for this booking. Admin is currently reviewing payment evidence.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
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
                            'Booking Status: ${booking.status}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'If the worker accepted the job, you will be prompted to submit payment details here.',
                      style: TextStyle(fontSize: 12, color: HomeEaseTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Worker View
            if (booking.status == 'Accepted') ...[
              HomeEaseCard(
                color: HomeEaseTheme.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Review Payment Receipt'),
                    const SizedBox(height: 10),
                    Text(
                      'The household needs to transfer payment via EasyPaisa/JazzCash and submit receipt details here. If they have done so, check the submission below:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
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
                          Text('• Reference: TXN-${booking.id.hashCode.abs().toString().take(8)}'),
                          Text('• Agreed Amount: PKR ${booking.agreedAmount.toStringAsFixed(0)}'),
                          Text('• Payment Channel: EasyPaisa / JazzCash'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.image_search_rounded, color: HomeEaseTheme.brand, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'receipt_${booking.id.hashCode.abs()}.jpg (Attached)',
                                style: const TextStyle(
                                  color: HomeEaseTheme.brand,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onConfirmPayment();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Confirm Payment'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onRejectPayment();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Decline Receipt'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onRaiseDispute();
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Center(child: Text('Raise Payment Dispute')),
                    ),
                  ],
                ),
              ),
            ] else ...[
              HomeEaseCard(
                color: HomeEaseTheme.white,
                child: Text(
                  'Booking Status for Worker: ${booking.status}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
