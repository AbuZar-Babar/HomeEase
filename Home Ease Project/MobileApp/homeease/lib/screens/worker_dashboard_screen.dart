import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/booking_repository.dart';
import '../services/localization_service.dart';
import '../services/supabase_auth_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';
import '../widgets/animated_scale_button.dart';
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
      if (mounted && (user != null || fresh.isNotEmpty)) {
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
          _liveBookings[idx] = updated;
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
          _liveBookings[idx] = updated;
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
          _liveBookings[idx] = updated;
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
              constraints: const BoxConstraints(),
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
            // Bidirectional Marketplace: Browse Available Household Gigs Banner
            if (widget.onBrowseAvailableJobs != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onBrowseAvailableJobs!();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [HomeEaseTheme.brand, HomeEaseTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: HomeEaseTheme.brand.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.explore_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocalizationService.tr('browseJobs'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isUrdu
                                    ? 'ایبٹ آباد کے گھرانوں کی پوسٹ کردہ جابز دیکھیں اور اپلائی کریں'
                                    : 'Find and apply for open domestic tasks near you in Abbottabad',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isUrdu ? 'دیکھیں' : 'Browse',
                            style: const TextStyle(
                              color: HomeEaseTheme.brand,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

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
                                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                                        label: Text(
                                          isUrdu ? 'مکمل کریں' : 'Mark Completed',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: HomeEaseTheme.statusVerified,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
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
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: Text(
                                          isUrdu ? 'معاہدہ دیکھیں' : 'View Agreement',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
