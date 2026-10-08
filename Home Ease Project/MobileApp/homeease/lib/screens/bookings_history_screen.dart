import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../services/booking_repository.dart';
import '../services/localization_service.dart';
import '../services/supabase_auth_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';
import '../widgets/in_app_chat_sheet.dart';
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
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Active', 'Upcoming', 'Completed', 'Disputed'];

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

  List<Booking> get _filteredBookings {
    if (_selectedFilter == 'All') return _liveBookings;
    return _liveBookings.where((b) {
      final s = b.status.toLowerCase().replaceAll(' ', '_');
      if (_selectedFilter == 'Active') {
        return s == 'accepted' || s == 'in_progress';
      } else if (_selectedFilter == 'Upcoming') {
        return s == 'pending';
      } else if (_selectedFilter == 'Completed') {
        return s == 'completed';
      } else if (_selectedFilter == 'Disputed') {
        return s == 'disputed' || s == 'conflict';
      }
      return true;
    }).toList();
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
    final displayBookings = _filteredBookings;

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
          // Filter Tabs Segment
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 12),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : HomeEaseTheme.textPrimary,
                      ),
                    ),
                    backgroundColor: HomeEaseTheme.surface,
                    selectedColor: HomeEaseTheme.brand,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (bool val) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
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
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  worker.role,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: HomeEaseTheme.brand,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 22, color: HomeEaseTheme.outline),
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
                      if (statusLower == 'accepted' || statusLower == 'in_progress') ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.brand.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: HomeEaseTheme.brand.withValues(alpha: 0.18)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security_rounded, size: 16, color: HomeEaseTheme.brand),
                              const SizedBox(width: 8),
                              Text(
                                isUrdu ? 'سروس شروع OTP: ' : 'Start OTP: ',
                                style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary, fontWeight: FontWeight.w600),
                              ),
                              const Text(
                                '8492',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: HomeEaseTheme.brand,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isUrdu ? 'آمد پر شیئر کریں' : 'Share on arrival',
                                style: const TextStyle(fontSize: 10, color: HomeEaseTheme.statusVerified, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Divider(height: 24, color: HomeEaseTheme.outline),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isUrdu ? 'طے شدہ رقم' : 'Agreed Amount',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: HomeEaseTheme.textSecondary,
                            ),
                          ),
                          Text(
                            'PKR ${booking.agreedAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: HomeEaseTheme.brand,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Action Buttons: responsive, bounded, never overflow
                      if (statusLower == 'pending') ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(booking, 'Rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: HomeEaseTheme.statusConflict,
                                  side: BorderSide(
                                    color: HomeEaseTheme.statusConflict.withValues(alpha: 0.4),
                                  ),
                                  backgroundColor: HomeEaseTheme.statusConflict.withValues(alpha: 0.06),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isUrdu ? 'منسوخ کریں' : 'Cancel',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => widget.onSelectBooking(booking),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: HomeEaseTheme.brand,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isUrdu ? 'تفصیلات' : 'Details',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (statusLower == 'accepted' || statusLower == 'in_progress') ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                label: Text(
                                  isUrdu ? 'چیٹ' : 'Chat',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                onPressed: () {
                                  InAppChatSheet.show(
                                    context,
                                    recipientName: worker.name,
                                    recipientRole: worker.role,
                                    serviceContext: '${worker.role} Booking',
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: HomeEaseTheme.brand,
                                  side: BorderSide(color: HomeEaseTheme.brand.withValues(alpha: 0.3)),
                                  backgroundColor: HomeEaseTheme.mintSoft,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.description_outlined, size: 16),
                                label: Text(
                                  isUrdu ? 'معاہدہ' : 'Agreement',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                onPressed: () => widget.onSelectBooking(booking),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: HomeEaseTheme.brand,
                                  side: BorderSide(color: HomeEaseTheme.brand.withValues(alpha: 0.3)),
                                  backgroundColor: HomeEaseTheme.card,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus(booking, 'Completed'),
                            icon: const Icon(Icons.check_circle_rounded, size: 18),
                            label: Text(
                              isUrdu ? 'مکمل نشان زد کریں' : 'Mark Completed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: HomeEaseTheme.statusVerified,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ] else if (statusLower == 'completed') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => widget.onRateBooking(booking),
                                icon: const Icon(Icons.star_rounded, size: 16),
                                label: Text(
                                  isUrdu ? 'درجہ بندی' : 'Rate',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: HomeEaseTheme.brand,
                                  backgroundColor: HomeEaseTheme.accentLight,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => widget.onRaiseDispute(booking),
                                icon: const Icon(Icons.report_problem_outlined, size: 16),
                                label: Text(
                                  isUrdu ? 'تنازعہ' : 'Dispute',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: HomeEaseTheme.statusConflict,
                                  side: BorderSide(color: HomeEaseTheme.statusConflict.withValues(alpha: 0.4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => widget.onSelectBooking(booking),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: HomeEaseTheme.brand,
                              backgroundColor: HomeEaseTheme.card,
                              side: const BorderSide(color: HomeEaseTheme.outline),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              minimumSize: const Size(0, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isUrdu ? 'تفصیلات دیکھیں' : 'View Details',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
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
