import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../services/booking_repository.dart';
import '../services/localization_service.dart';
import '../services/supabase_auth_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';
import '../widgets/shimmer_loading.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BookingsHistoryScreen extends StatefulWidget {
  const BookingsHistoryScreen({
    super.key,
    required this.bookings,
    required this.workers,
    this.onBack,
    required this.onSelectBooking,
    required this.onRateBooking,
    required this.onRaiseDispute,
    this.onRefresh,
    this.onStatusChanged,
    this.bottomNavigationBar,
    this.roleBadge,
    this.onToggleLanguage,
    this.onOpenNotifications,
    this.unreadNotificationsCount,
    this.onLogout,
  });

  final List<Booking> bookings;
  final List<WorkerProfile> workers;
  final VoidCallback? onBack;
  final ValueChanged<Booking> onSelectBooking;
  final ValueChanged<Booking> onRateBooking;
  final ValueChanged<Booking> onRaiseDispute;
  final Future<void> Function()? onRefresh;
  final ValueChanged<Booking>? onStatusChanged;
  final Widget? bottomNavigationBar;
  final String? roleBadge;
  final VoidCallback? onToggleLanguage;
  final VoidCallback? onOpenNotifications;
  final int? unreadNotificationsCount;
  final VoidCallback? onLogout;

  @override
  State<BookingsHistoryScreen> createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends State<BookingsHistoryScreen> {
  late List<Booking> _liveBookings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _liveBookings = List.from(widget.bookings);
    _fetchLiveBookings();
  }

  @override
  void didUpdateWidget(BookingsHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookings != oldWidget.bookings) {
      _liveBookings = List.from(widget.bookings);
    }
  }

  Future<void> _fetchLiveBookings() async {
    setState(() => _isLoading = true);
    try {
      final auth = SupabaseAuthService();
      final user = auth.currentUser;
      final isWorker = (user?.role.toLowerCase() == 'worker') ||
          (widget.roleBadge?.toLowerCase() == 'worker');
      final effectiveId = user?.id ??
          (isWorker
              ? '00000000-0000-0000-0000-000000000010'
              : '00000000-0000-0000-0000-000000000001');

      final fresh = isWorker
          ? await BookingRepository().fetchBookingsForWorker(effectiveId)
          : await BookingRepository().fetchBookingsForHousehold(effectiveId);

      if (mounted && (user != null || fresh.isNotEmpty)) {
        setState(() {
          _liveBookings = fresh;
        });
      }
    } catch (e) {
      debugPrint('Error fetching live bookings in history screen: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(Booking booking, String newStatus) async {
    try {
      final updated = await BookingRepository().updateBookingStatus(booking.id, newStatus);
      if (!mounted) return;
      setState(() {
        final idx = _liveBookings.indexWhere((b) => IdMapping.matchesBooking(b.id, booking.id));
        if (idx != -1) {
          _liveBookings[idx] = updated;
        }
      });
      widget.onStatusChanged?.call(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.isUrdu
                ? 'بکنگ کی حیثیت $newStatus پر اپ ڈیٹ ہو گئی۔'
                : 'Booking status updated to $newStatus.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final fallback = booking.copyWith(status: newStatus);
      setState(() {
        final idx = _liveBookings.indexWhere((b) => IdMapping.matchesBooking(b.id, booking.id));
        if (idx != -1) {
          _liveBookings[idx] = fallback;
        }
      });
      widget.onStatusChanged?.call(fallback);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.isUrdu
                ? 'حیثیت $newStatus پر تبدیل ہو گئی۔'
                : 'Status updated to $newStatus.',
          ),
        ),
      );
    }
  }

  WorkerProfile _getWorker(String id) {
    return widget.workers.firstWhere(
      (w) => IdMapping.matchesWorker(w.id, id),
      orElse: () => widget.workers.isNotEmpty
          ? widget.workers.first
          : WorkerProfile(
              id: id,
              name: 'Domestic Worker',
              role: 'Worker',
              rating: 4.8,
              rate: 'PKR 1500/hr',
              experience: '3+ years',
              availability: 'Available',
              location: 'Abbottabad',
              description: 'Verified worker in Abbottabad',
              highlight: 'Top rated',
              area: 'Abbottabad',
              hourlyRate: 1500,
              skillTags: const ['Domestic Work'],
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
        return HomeEaseTheme.statusPending;
      case 'accepted':
      case 'in_progress':
        return HomeEaseTheme.statusVerified;
      case 'completed':
        return HomeEaseTheme.statusVerified;
      case 'disputed':
      case 'conflict':
        return HomeEaseTheme.statusConflict;
      case 'cancelled':
      case 'rejected':
        return HomeEaseTheme.muted;
      default:
        return HomeEaseTheme.brand;
    }
  }

  String _formatStatus(String status) {
    if (!LocalizationService.isUrdu) return status;
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
        return 'زیر التواء';
      case 'accepted':
        return 'منظور شدہ';
      case 'in_progress':
        return 'جاری';
      case 'completed':
        return 'مکمل';
      case 'rejected':
        return 'مسترد';
      case 'cancelled':
        return 'منسوخ';
      case 'disputed':
      case 'conflict':
        return 'تنازعہ';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final displayBookings = _liveBookings;

    return AppScaffold(
      title: isUrdu ? 'آپ کی بکنگز' : 'Your bookings',
      subtitle: isUrdu
          ? 'حیثیت، معاہدے اور بکنگز دیکھیں اور سنبھالیں۔'
          : 'Track status, view agreements, and manage bookings.',
      onBack: widget.onBack,
      roleBadge: widget.roleBadge,
      onToggleLanguage: widget.onToggleLanguage,
      onOpenNotifications: widget.onOpenNotifications,
      unreadNotificationsCount: widget.unreadNotificationsCount,
      onLogout: widget.onLogout,
      bottomNavigationBar: widget.bottomNavigationBar,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: HomeEaseTheme.brand),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: HomeEaseTheme.brand),
            onPressed: () async {
              await _fetchLiveBookings();
              if (widget.onRefresh != null) {
                await widget.onRefresh!();
              }
            },
            tooltip: isUrdu ? 'تازہ کریں' : 'Refresh bookings',
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading && _liveBookings.isEmpty)
            Column(
              children: const [
                ShimmerJobCard(),
                ShimmerJobCard(),
                ShimmerJobCard(),
              ],
            )
          else if (displayBookings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(
                      Icons.book_online_rounded,
                      size: 64,
                      color: HomeEaseTheme.cardDark,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isUrdu ? 'کوئی بکنگ نہیں ملی۔' : 'No bookings found.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: HomeEaseTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _fetchLiveBookings,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(isUrdu ? 'دوبارہ چیک کریں' : 'Check again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HomeEaseTheme.brand,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...displayBookings.asMap().entries.map((entry) {
              final index = entry.key;
              final booking = entry.value;
              final worker = _getWorker(booking.workerId);
              final dateStr =
                  '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}';
              final timeStr =
                  '${booking.startTime.format(context)} - ${booking.endTime.format(context)}';
              final statusLower = booking.status.toLowerCase().replaceAll(' ', '_');

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: HomeEaseCard(
                  color: HomeEaseTheme.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  worker.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  worker.role,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(booking.status).withValues(alpha: 0.28),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(booking.status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _formatStatus(booking.status),
                                  style: TextStyle(
                                    color: _getStatusColor(booking.status),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: HomeEaseTheme.background),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: HomeEaseTheme.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 18),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: HomeEaseTheme.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(timeStr, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: HomeEaseTheme.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.address,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PKR ${booking.agreedAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: HomeEaseTheme.brand,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (statusLower == 'pending') ...[
                                TextButton(
                                  onPressed: () => _updateStatus(booking, 'Rejected'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HomeEaseTheme.statusConflict,
                                    backgroundColor: HomeEaseTheme.statusConflict.withValues(alpha: 0.1),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    minimumSize: const Size(48, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(isUrdu ? 'منسوخ کریں' : 'Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => widget.onSelectBooking(booking),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HomeEaseTheme.brand,
                                    backgroundColor: HomeEaseTheme.card,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    minimumSize: const Size(48, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(isUrdu ? 'تفصیلات' : 'Details'),
                                ),
                              ] else if (statusLower == 'accepted' || statusLower == 'in_progress') ...[
                                TextButton(
                                  onPressed: () => _updateStatus(booking, 'Completed'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: HomeEaseTheme.statusVerified,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    minimumSize: const Size(48, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(isUrdu ? 'مکمل نشان زد کریں' : 'Mark Completed'),
                                ),
                                TextButton(
                                  onPressed: () => widget.onSelectBooking(booking),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HomeEaseTheme.white,
                                    backgroundColor: HomeEaseTheme.brand,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    minimumSize: const Size(48, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(isUrdu ? 'معاہدہ دیکھیں' : 'View Agreement'),
                                ),
                              ] else if (statusLower == 'completed') ...[
                                TextButton(
                                  onPressed: () => widget.onRateBooking(booking),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HomeEaseTheme.brand,
                                    backgroundColor: HomeEaseTheme.accentLight,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    minimumSize: const Size(48, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(isUrdu ? 'درجہ بندی' : 'Rate'),
                                ),
                                TextButton(
                                  onPressed: () => widget.onRaiseDispute(booking),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HomeEaseTheme.statusConflict,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    minimumSize: const Size(48, 44),
                                  ),
                                  child: Text(isUrdu ? 'تنازعہ' : 'Dispute'),
                                ),
                              ] else ...[
                                TextButton(
                                  onPressed: () => widget.onSelectBooking(booking),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HomeEaseTheme.brand,
                                    backgroundColor: HomeEaseTheme.card,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    minimumSize: const Size(48, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(isUrdu ? 'تفصیلات' : 'Details'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
            }),
        ],
      ),
    );
  }
}
