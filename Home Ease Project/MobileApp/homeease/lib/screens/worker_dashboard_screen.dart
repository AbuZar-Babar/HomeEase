import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/booking_repository.dart';
import '../services/dispute_repository.dart';
import '../services/localization_service.dart';
import '../services/supabase_auth_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/digital_receipt_dialog.dart';
import '../widgets/home_ease_widgets.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/payment_gateway_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({
    super.key,
    required this.bookings,
    required this.verificationStatus,
    this.workerName,
    required this.onAcceptBooking,
    required this.onRejectBooking,
    this.onCompleteBooking,
    required this.onManageAvailability,
    required this.onOpenNotifications,
    required this.unreadNotificationsCount,
    required this.onSelectBooking,
    required this.onLogout,
    this.onBrowseAvailableJobs,
    this.onLanguageChanged,
    this.onRefresh,
    this.bottomNavigationBar,
  });

  final List<Booking> bookings;
  final String verificationStatus;
  final String? workerName;
  final ValueChanged<Booking> onAcceptBooking;
  final ValueChanged<Booking> onRejectBooking;
  final ValueChanged<Booking>? onCompleteBooking;
  final VoidCallback onManageAvailability;
  final VoidCallback onOpenNotifications;
  final int unreadNotificationsCount;
  final ValueChanged<Booking> onSelectBooking;
  final VoidCallback onLogout;
  final VoidCallback? onBrowseAvailableJobs;
  final VoidCallback? onLanguageChanged;
  final Future<void> Function()? onRefresh;
  final Widget? bottomNavigationBar;

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  late List<Booking> _liveBookings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _liveBookings = List.from(widget.bookings);
    _fetchLiveWorkerBookings();
  }

  @override
  void didUpdateWidget(WorkerDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookings != oldWidget.bookings) {
      _liveBookings = List.from(widget.bookings);
    }
  }

  Future<void> _fetchLiveWorkerBookings() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseAuthService().currentUser;
      final workerId = user?.id ?? '00000000-0000-0000-0000-000000000010';
      final fresh = await BookingRepository().fetchBookingsForWorker(workerId);
      if (mounted && (user != null || (fresh.isNotEmpty && widget.bookings.isEmpty))) {
        setState(() {
          _liveBookings = fresh;
        });
      }
    } catch (e) {
      debugPrint('Error fetching worker bookings in dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptBooking(Booking booking) async {
    try {
      final updated = await BookingRepository().updateBookingStatus(booking.id, 'Accepted');
      if (!mounted) return;
      setState(() {
        final idx = _liveBookings.indexWhere((b) => IdMapping.matchesBooking(b.id, booking.id));
        if (idx != -1) {
          _liveBookings[idx] = _liveBookings[idx].copyWith(status: 'Accepted');
        }
      });
      widget.onAcceptBooking(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.isUrdu
                ? 'کام قبول کر لیا گیا! سروس کا معاہدہ تیار ہے۔'
                : 'Job accepted! Service agreement generated.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting job: $e')),
      );
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    try {
      final updated = await BookingRepository().updateBookingStatus(booking.id, 'Rejected');
      if (!mounted) return;
      setState(() {
        final idx = _liveBookings.indexWhere((b) => IdMapping.matchesBooking(b.id, booking.id));
        if (idx != -1) {
          _liveBookings[idx] = _liveBookings[idx].copyWith(status: 'Rejected');
        }
      });
      widget.onRejectBooking(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.isUrdu
                ? 'درخواست مسترد کر دی گئی۔'
                : 'Job request declined.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining job: $e')),
      );
    }
  }

  Future<void> _completeBooking(Booking booking) async {
    try {
      final updated = await BookingRepository().updateBookingStatus(booking.id, 'Completed');
      if (!mounted) return;
      setState(() {
        final idx = _liveBookings.indexWhere((b) => IdMapping.matchesBooking(b.id, booking.id));
        if (idx != -1) {
          _liveBookings[idx] = _liveBookings[idx].copyWith(status: 'Completed');
        }
      });
      widget.onCompleteBooking?.call(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.isUrdu
                ? 'ملازمت کو مکمل قرار دے دیا گیا۔'
                : 'Job marked as Completed!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing job: $e')),
      );
    }
  }

  Future<void> _confirmPaymentReceived(Booking booking) async {
    try {
      final updated = await BookingRepository().confirmPaymentReceived(
        bookingId: booking.id,
        txId: booking.transactionId,
        paymentMethod: booking.paymentMethod,
      );

      if (!mounted) return;
      setState(() {
        final idx = _liveBookings.indexWhere((b) => IdMapping.matchesBooking(b.id, booking.id));
        if (idx != -1) {
          _liveBookings[idx] = updated;
        }
      });

      widget.onCompleteBooking?.call(updated);

      final workerProfile = WorkerProfile(
        id: booking.workerId,
        name: widget.workerName ?? 'HomeEase Worker',
        role: booking.serviceCategoryId,
        rating: 4.9,
        rate: 'PKR ${booking.agreedAmount.toStringAsFixed(0)}',
        experience: '3 years',
        availability: 'Available',
        location: booking.address,
        description: 'Verified HomeEase Service Professional',
        highlight: 'Verified',
      );

      final paymentResult = PaymentResult(
        success: true,
        txId: booking.transactionId ??
            'P2P-${booking.id.hashCode.abs().toString().padLeft(8, '0').substring(0, 8)}',
        mode: booking.paymentMethod.toLowerCase() == 'jazzcash'
            ? PaymentMode.jazzcash
            : booking.paymentMethod.toLowerCase() == 'bank_transfer'
                ? PaymentMode.stripe
                : booking.paymentMethod.toLowerCase() == 'cash'
                    ? PaymentMode.cod
                    : PaymentMode.easypaisa,
        amount: booking.agreedAmount,
        timestamp: DateTime.now(),
        payerIdentifier: 'Household P2P Transfer',
        brand: 'P2P Escrow Released',
      );

      await DigitalReceiptDialog.show(
        context,
        paymentResult: paymentResult,
        booking: updated,
        worker: workerProfile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.isUrdu
                  ? 'رقم کی تصدیق ہو گئی! ایسکرو جاری کر دیا گیا۔'
                  : 'Payment confirmed! Escrow released and job completed.',
            ),
            backgroundColor: HomeEaseTheme.statusVerified,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming payment: $e')),
      );
    }
  }

  Future<void> _paymentNotReceived(Booking booking) async {
    try {
      await DisputeRepository().createDispute(
        bookingId: booking.id,
        complainantId: booking.workerId,
        respondentId: booking.householdId,
        category: 'Payment Not Received',
        description:
            'Worker reported payment of PKR ${booking.agreedAmount.toStringAsFixed(0)} was not received in wallet/bank despite household marking payment_sent.',
        evidencePath: booking.receiptUrl,
      );

      final updated = await BookingRepository().updateBookingStatus(booking.id, 'Disputed');
      if (!mounted) return;

      setState(() {
        final idx = _liveBookings.indexWhere((b) => IdMapping.matchesBooking(b.id, booking.id));
        if (idx != -1) {
          _liveBookings[idx] = updated;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.isUrdu
                ? 'تنازعہ درج کر دیا گیا! ایڈمن ثالثی کا عمل شروع ہو چکا ہے۔'
                : 'Dispute filed! Domestic service dispute sent for admin arbitration.',
          ),
          backgroundColor: HomeEaseTheme.statusConflict,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error filing dispute: $e')),
      );
    }
  }

  Widget _buildReceiptThumbnail(String path) {
    Widget imageWidget;
    if (path.isEmpty) {
      imageWidget = _fallbackThumb();
    } else if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
      imageWidget = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackThumb(),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackThumb(),
        );
      } else {
        imageWidget = _fallbackThumb();
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: imageWidget,
      ),
    );
  }

  Widget _fallbackThumb() {
    return Container(
      color: HomeEaseTheme.mintSoft,
      alignment: Alignment.center,
      child: const Icon(Icons.receipt_long_rounded, color: HomeEaseTheme.brand, size: 24),
    );
  }

  void _showFullReceipt(String path) {
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
                  const Text('Payment Receipt Screenshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380, maxWidth: double.infinity),
                child: _buildReceiptThumbnail(path),
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
    final candidateBookings = _liveBookings;
    final pendingRequests = candidateBookings.where((b) {
      final s = b.status.toLowerCase().replaceAll(' ', '_');
      return s == 'pending';
    }).toList();
    final acceptedJobs = candidateBookings.where((b) {
      final s = b.status.toLowerCase().replaceAll(' ', '_');
      return s == 'accepted' || s == 'in_progress';
    }).toList();
    final completedBookings = candidateBookings.where((b) {
      final s = b.status.toLowerCase().replaceAll(' ', '_');
      return s == 'completed';
    }).toList();
    final grossEarnings = completedBookings.fold<double>(0.0, (sum, b) => sum + b.agreedAmount);
    final completedTasks = completedBookings.length;
    final averageYield = completedTasks > 0 ? (grossEarnings / completedTasks) : 0.0;

    final welcomeSubtitle = widget.workerName != null
        ? (isUrdu ? 'خوش آمدید، ${widget.workerName}' : 'Welcome back, ${widget.workerName}')
        : (isUrdu ? 'آج کے کام اور نئی درخواستیں' : "Today's schedule & incoming job requests");

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AppScaffold(
        title: LocalizationService.tr('workerDashboard'),
        subtitle: welcomeSubtitle,
        roleBadge: 'Worker',
        unreadNotificationsCount: widget.unreadNotificationsCount,
        onOpenNotifications: widget.onOpenNotifications,
        onToggleLanguage: () {
          LocalizationService.toggleLanguage();
          setState(() {});
          widget.onLanguageChanged?.call();
        },
        onLogout: widget.onLogout,
        bottomNavigationBar: widget.bottomNavigationBar,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: HomeEaseTheme.brand),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: HomeEaseTheme.brand, size: 20),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () async {
                await _fetchLiveWorkerBookings();
                if (widget.onRefresh != null) {
                  await widget.onRefresh!();
                }
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verification Status Banner
            if (widget.verificationStatus != 'Verified')
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: HomeEaseCard(
                  color: const Color(0xFFFFFBEB), // Amber 50
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: HomeEaseTheme.statusPending, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.verificationStatus == 'PendingVerification'
                                  ? (isUrdu ? 'تصدیق کا عمل جاری ہے' : 'Verification In-Review')
                                  : (isUrdu ? 'پروفائل غیر تصدیق شدہ' : 'Profile Unverified'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: HomeEaseTheme.statusPending, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.verificationStatus == 'PendingVerification'
                                  ? (isUrdu
                                      ? 'ایڈمن آپ کی تفصیلات کا جائزہ لے رہا ہے۔ تصدیق کے بعد آپ تلاش میں ظاہر ہوں گے۔'
                                      : 'Admin is reviewing your details. Once verified, you will appear in search results.')
                                  : (isUrdu
                                      ? 'براہ کرم تصدیق کے لیے اپنی پروفائل اور شناختی کارڈ کی کاپی جمع کرائیں۔'
                                      : 'Please submit your profile and CNIC copy for verification.'),
                              style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: HomeEaseCard(
                  color: const Color(0xFFECFDF5), // Emerald 50
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: HomeEaseTheme.statusVerified, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUrdu ? 'تصدیق شدہ ورکر بیج' : 'Verified Profile Badge',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: HomeEaseTheme.statusVerified, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isUrdu
                                  ? 'آپ کی پروفائل مکمل تصدیق شدہ ہے۔ آپ گھریلو تلاش کے نتائج میں نظر آ رہے ہیں۔'
                                  : 'Your profile is fully verified. You are visible in household search results.',
                              style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Milestone Performance Summary Card
            HomeEaseCard(
              color: HomeEaseTheme.white,
              padding: const EdgeInsets.all(16),
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
                        child: const Icon(Icons.insights_rounded, color: HomeEaseTheme.brand, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizationService.tr('performanceSummary'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: HomeEaseTheme.textPrimary,
                              ),
                            ),
                            Text(
                              isUrdu ? 'تکمیل شدہ ملازمتوں کی مالی کارکردگی' : 'Financial yield from completed gigs',
                              style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.mintSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Text(
                          'PKR ${grossEarnings.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: HomeEaseTheme.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: HomeEaseTheme.outline),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: LocalizationService.tr('grossEarnings'),
                          value: 'PKR ${grossEarnings.toStringAsFixed(0)}',
                          icon: Icons.payments_outlined,
                          color: HomeEaseTheme.brand,
                        ),
                      ),
                      Container(width: 1, height: 38, color: HomeEaseTheme.outline),
                      Expanded(
                        child: _MetricTile(
                          label: LocalizationService.tr('completedTasks'),
                          value: '$completedTasks',
                          icon: Icons.task_alt_rounded,
                          color: HomeEaseTheme.statusVerified,
                        ),
                      ),
                      Container(width: 1, height: 38, color: HomeEaseTheme.outline),
                      Expanded(
                        child: _MetricTile(
                          label: LocalizationService.tr('averageYield'),
                          value: 'PKR ${averageYield.toStringAsFixed(0)}',
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Stats Row
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: '${pendingRequests.length}',
                    subtitle: isUrdu ? 'نئی درخواستیں' : 'Pending Requests',
                    color: HomeEaseTheme.card,
                    icon: Icons.pending_actions_rounded,
                    iconColor: HomeEaseTheme.statusPending,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: '${acceptedJobs.length}',
                    subtitle: isUrdu ? 'فعال ملازمتیں' : 'Confirmed Tasks',
                    color: HomeEaseTheme.card,
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: HomeEaseTheme.statusVerified,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Incoming Requests Card (High Affordance, 48x48+ dp touch targets)
            HomeEaseCard(
              color: HomeEaseTheme.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(LocalizationService.tr('incomingRequests')),
                  const SizedBox(height: 12),
                  if (pendingRequests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          isUrdu ? 'اس وقت کوئی نئی بکنگ درخواست نہیں ہے۔' : 'No pending booking requests.',
                          style: const TextStyle(color: HomeEaseTheme.muted),
                        ),
                      ),
                    )
                  else
                    ...pendingRequests.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: HomeEaseTheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LocalizationService.getCategoryIcon(booking.serviceCategoryId),
                                    color: HomeEaseTheme.brand,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isUrdu ? LocalizationService.tr(booking.serviceCategoryId.toLowerCase()) : booking.serviceCategoryId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: HomeEaseTheme.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: HomeEaseTheme.textPrimary, fontSize: 12),
                                  ),
                                ],
                              ),
                               const SizedBox(height: 8),
                              Text(
                                isUrdu
                                    ? 'وقت: ${booking.startTime.format(context)} - ${booking.endTime.format(context)}'
                                    : 'Time: ${booking.startTime.format(context)} - ${booking.endTime.format(context)}',
                                style: const TextStyle(fontSize: 13, color: HomeEaseTheme.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isUrdu ? 'مقام: ${booking.address}' : 'Location: ${booking.address}',
                                style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isUrdu
                                    ? 'طے شدہ رقم: PKR ${booking.agreedAmount.toStringAsFixed(0)}'
                                    : 'Agreed Amount: PKR ${booking.agreedAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: HomeEaseTheme.brand, fontSize: 13),
                              ),
                              if (booking.notes.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  isUrdu ? 'ہدایات: "${booking.notes}"' : 'Notes: "${booking.notes}"',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: HomeEaseTheme.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 16),
                              // High Affordance Accept / Decline Buttons (48dp height minimum)
                              Row(
                                children: [
                                  Expanded(
                                    child: AnimatedScaleTap(
                                      onTap: () => _acceptBooking(booking),
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: HomeEaseTheme.statusVerified,
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: HomeEaseTheme.statusVerified.withValues(alpha: 0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              isUrdu ? 'قبول کریں' : 'Accept',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: AnimatedScaleTap(
                                      onTap: () => _rejectBooking(booking),
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: HomeEaseTheme.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: HomeEaseTheme.statusConflict, width: 1.5),
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.close_rounded, color: HomeEaseTheme.statusConflict, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              isUrdu ? 'مسترد کریں' : 'Decline',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: HomeEaseTheme.statusConflict),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Active Jobs & Agreements Card
            HomeEaseCard(
              color: HomeEaseTheme.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(isUrdu ? 'جاری کام اور معاہدے' : 'Active Jobs & Agreements'),
                  const SizedBox(height: 12),
                  if (acceptedJobs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          isUrdu ? 'اس وقت کوئی فعال کام نہیں ہے۔' : 'No active jobs at the moment.',
                          style: const TextStyle(color: HomeEaseTheme.muted),
                        ),
                      ),
                    )
                  else
                    ...acceptedJobs.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: HomeEaseTheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LocalizationService.getCategoryIcon(booking.serviceCategoryId),
                                    color: HomeEaseTheme.brand,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${isUrdu ? LocalizationService.tr(booking.serviceCategoryId.toLowerCase()) : booking.serviceCategoryId} - ${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          isUrdu
                                              ? 'وقت: ${booking.startTime.format(context)} - ${booking.endTime.format(context)}'
                                              : 'Time: ${booking.startTime.format(context)} - ${booking.endTime.format(context)}',
                                          style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                                        ),
                                        Text(
                                          booking.address,
                                          style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'PKR ${booking.agreedAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: HomeEaseTheme.brand,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              if (booking.paymentStatus.toLowerCase() == 'payment_sent') ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFF59E0B)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.lock_clock_rounded, color: Color(0xFFB45309), size: 18),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              isUrdu ? 'ایسکرو ہولڈ: گھریلو صارف نے رقم بھیج دی ہے' : 'Escrow Hold: Payment Sent by Household',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF92400E)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Receipt Thumbnail Preview
                                      InkWell(
                                        onTap: () {
                                          if (booking.receiptUrl != null && booking.receiptUrl!.isNotEmpty) {
                                            _showFullReceipt(booking.receiptUrl!);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.amber.shade300),
                                          ),
                                          child: Row(
                                            children: [
                                              _buildReceiptThumbnail(booking.receiptUrl ?? ''),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      booking.transactionId != null && booking.transactionId!.isNotEmpty
                                                          ? 'TRX ID: ${booking.transactionId}'
                                                          : 'Receipt Screenshot Attached',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: HomeEaseTheme.brand),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      isUrdu ? 'رسید دیکھنے کے لیے ٹیپ کریں' : 'Tap to inspect receipt proof',
                                                      style: const TextStyle(fontSize: 10.5, color: HomeEaseTheme.textSecondary),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.zoom_in_rounded, color: HomeEaseTheme.brand, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Two Buttons: 'Payment Not Received' & 'Confirm Payment Received'
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 46,
                                              child: OutlinedButton.icon(
                                                key: const Key('dashboard_payment_not_received_button'),
                                                onPressed: () {
                                                  HapticFeedback.lightImpact();
                                                  _paymentNotReceived(booking);
                                                },
                                                icon: const Icon(Icons.report_problem_outlined, size: 16),
                                                label: Text(
                                                  isUrdu ? 'رقم نہیں ملی' : 'Payment Not Received',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: HomeEaseTheme.statusConflict,
                                                  side: const BorderSide(color: HomeEaseTheme.statusConflict, width: 1.5),
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: SizedBox(
                                              height: 46,
                                              child: ElevatedButton.icon(
                                                key: const Key('dashboard_confirm_payment_received_button'),
                                                onPressed: () {
                                                  HapticFeedback.lightImpact();
                                                  _confirmPaymentReceived(booking);
                                                },
                                                icon: const Icon(Icons.check_circle_rounded, size: 16),
                                                label: Text(
                                                  isUrdu ? 'ادائیگی موصول ہو گئی' : 'Confirm Payment Received',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: HomeEaseTheme.statusVerified,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () => widget.onSelectBooking(booking),
                                    icon: const Icon(Icons.description_outlined, size: 16),
                                    label: Text(
                                      isUrdu ? 'معاہدہ دیکھیں' : 'View Agreement Details',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            _completeBooking(booking);
                                          },
                                          icon: const Icon(Icons.check_circle_rounded, size: 17),
                                          label: Text(
                                            isUrdu ? 'مکمل کریں' : 'Mark Completed',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: HomeEaseTheme.statusVerified,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: OutlinedButton(
                                          onPressed: () => widget.onSelectBooking(booking),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: HomeEaseTheme.brand,
                                            side: const BorderSide(color: HomeEaseTheme.brand),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Text(
                                            isUrdu ? 'معاہدہ دیکھیں' : 'View Agreement',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.8)),
        boxShadow: HomeEaseTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: HomeEaseTheme.textPrimary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: HomeEaseTheme.textSecondary, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
