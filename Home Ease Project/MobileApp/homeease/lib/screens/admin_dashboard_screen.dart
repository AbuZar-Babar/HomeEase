import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/audit_log_service.dart';
import '../services/booking_repository.dart';
import '../services/dispute_repository.dart';
import '../services/localization_service.dart';
import '../services/notification_service.dart';
import '../services/worker_repository.dart';
import '../theme/home_ease_theme.dart';
import 'admin/analytics_desk.dart';
import 'admin/audit_logs_desk.dart';
import 'admin/disputes_desk.dart';
import 'admin/verification_desk.dart';

/// Milestone 3: Responsive Web & Mobile Admin Governance & Moderation Dashboard.
///
/// Features:
/// - Dual-screen responsiveness: Breakpoint `constraints.maxWidth >= 900dp`
///   * Desktop/Web (>= 900dp): Persistent left sidebar (260dp) + multi-column grid/feed.
///   * Mobile (< 900dp): Top app bar + compact tab selector + single-column feed.
/// - Tab 1: Platform Analytics (Gross PKR volume, total bookings, active disputes, verified workers, category bars).
/// - Tab 2: Worker Verification Desk (NADRA CNIC format, bio, experience, 1-tap Approve/Reject).
/// - Tab 3: Dispute Resolution Desk (live feed, evidence thumbnail, Refund/Payout/Dismiss actions).
/// - Tab 4: System Audit Logs (chronological timeline of platform events).
/// - Strict touch targets >= 48x48dp across all interactive controls.
/// - Full bi-directional English (LTR) and Urdu (RTL) support.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onLogout,
    this.onLanguageChanged,
  });

  final VoidCallback onLogout;
  final VoidCallback? onLanguageChanged;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTabIndex = 0; // 0: Analytics, 1: Verification, 2: Disputes, 3: Audit Logs
  bool _isLoading = true;

  // Data cache
  List<Booking> _allBookings = [];
  List<WorkerProfile> _allWorkers = [];
  List<Dispute> _allDisputes = [];

  final AuditLogService _auditService = AuditLogService();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final bookingsFuture = BookingRepository().fetchAllBookings();
      final workersFuture = WorkerRepository().fetchAllWorkersAdmin();
      final disputesFuture = DisputeRepository().fetchAllDisputes();
      final auditLogsFuture = _auditService.fetchLiveLogs();

      final results = await Future.wait([
        bookingsFuture,
        workersFuture,
        disputesFuture,
        auditLogsFuture,
      ]);

      if (mounted) {
        setState(() {
          _allBookings = results[0] as List<Booking>;
          _allWorkers = results[1] as List<WorkerProfile>;
          _allDisputes = results[2] as List<Dispute>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AdminDashboardScreen._loadAllData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Badges for sidebar & tabs
  int get _activeDisputesCount {
    return _allDisputes.where((d) => d.status.toLowerCase() == 'open').length;
  }

  int get _pendingWorkersCount {
    return _allWorkers
        .where((w) => w.verificationStatus.toLowerCase() == 'pendingverification')
        .length;
  }

  // Worker Moderation Actions
  Future<void> _approveWorker(WorkerProfile worker) async {
    HapticFeedback.mediumImpact();
    final updated = await WorkerRepository().updateWorkerVerificationStatus(
      workerId: worker.id,
      status: 'Verified',
    );
    if (updated != null) {
      _auditService.logEvent(
        actionType: 'verification',
        title: 'Worker Verification Approved',
        description:
            'Approved ${worker.name} (${worker.role}) with CNIC ${worker.formattedCnic} in ${worker.location}.',
        actor: 'Admin (admin@homeease.com)',
        severity: 'success',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.isUrdu
                  ? '${worker.name} کی تصدیق منظور کر لی گئی ہے۔'
                  : 'Worker ${worker.name} approved as Verified.',
            ),
            backgroundColor: HomeEaseTheme.statusVerified,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadAllData();
      }
    }
  }

  Future<void> _rejectWorker(WorkerProfile worker) async {
    HapticFeedback.heavyImpact();
    final updated = await WorkerRepository().updateWorkerVerificationStatus(
      workerId: worker.id,
      status: 'Rejected',
    );
    if (updated != null) {
      _auditService.logEvent(
        actionType: 'verification',
        title: 'Worker Verification Rejected',
        description:
            'Rejected verification for ${worker.name} (${worker.role}) due to credential mismatch.',
        actor: 'Admin (admin@homeease.com)',
        severity: 'danger',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.isUrdu
                  ? '${worker.name} کی تصدیق مسترد کر دی گئی۔'
                  : 'Worker ${worker.name} verification rejected.',
            ),
            backgroundColor: HomeEaseTheme.statusConflict,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadAllData();
      }
    }
  }

  // Dispute Adjudication Actions
  Future<void> _adjudicateDispute(Dispute dispute, String resolutionStatus, String notes) async {
    HapticFeedback.mediumImpact();
    try {
      await DisputeRepository().resolveDispute(
        disputeId: dispute.id,
        resolutionStatus: resolutionStatus,
        resolutionNotes: notes,
        adminId: 'admin_1',
      );

      await BookingRepository().updateBookingDisputeResolution(
        bookingId: dispute.bookingId,
        resolutionStatus: resolutionStatus,
      );

      final String actionTitle = resolutionStatus == 'resolved_refund'
          ? 'Dispute Refund Authorized'
          : (resolutionStatus == 'resolved_payout'
              ? 'Dispute Payout Released'
              : 'Dispute Dismissed');

      final String severity = resolutionStatus == 'resolved_refund'
          ? 'info'
          : (resolutionStatus == 'resolved_payout' ? 'success' : 'warning');

      _auditService.logEvent(
        actionType: 'dispute',
        title: actionTitle,
        description:
            'Dispute #${dispute.id.substring(0, 8)} adjudicated with status $resolutionStatus: $notes',
        actor: 'Admin (admin@homeease.com)',
        severity: severity,
      );

      NotificationService().addNotification(
        NotificationModel(
          id: 'notif_disp_${DateTime.now().millisecondsSinceEpoch}',
          userId: dispute.complainantId,
          title: actionTitle,
          titleUrdu: resolutionStatus == 'resolved_refund'
              ? 'شکایت برائے واپسی رقم منظور'
              : (resolutionStatus == 'resolved_payout'
                  ? 'شکایت: ورکر کو ادائیگی جاری'
                  : 'شکایت خارج کر دی گئی'),
          message:
              'Dispute #${dispute.id.length > 8 ? dispute.id.substring(0, 8) : dispute.id} has been adjudicated: $notes',
          messageUrdu:
              'شکایت #${dispute.id.length > 8 ? dispute.id.substring(0, 8) : dispute.id} کا فیصلہ کر دیا گیا ہے۔',
          type: 'Dispute',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.isUrdu
                  ? 'شکایت کا فیصلہ درج کر دیا گیا: $actionTitle'
                  : 'Dispute adjudicated: $actionTitle',
            ),
            backgroundColor: HomeEaseTheme.brand,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadAllData();
      }
    } catch (e) {
      debugPrint('Error adjudicating dispute: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: LocalizationService.direction,
      child: Scaffold(
        backgroundColor: HomeEaseTheme.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 900;
              if (isWide) {
                return _buildDesktopLayout();
              } else {
                return _buildMobileLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP / WEB LAYOUT (>= 900dp)
  // ===========================================================================
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Persistent Left Sidebar (260dp width)
        _buildSidebar(),

        // Vertical Divider
        Container(width: 1, color: HomeEaseTheme.outline.withValues(alpha: 0.4)),

        // Main Content Pane
        Expanded(
          child: Column(
            children: [
              _buildTopHeader(isWide: true),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildActiveTabContent(isWide: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    final navItems = [
      {'title': LocalizationService.tr('platformAnalytics'), 'icon': Icons.insights_rounded, 'badge': 0},
      {'title': LocalizationService.tr('workerVerificationDesk'), 'icon': Icons.verified_user_rounded, 'badge': _pendingWorkersCount},
      {'title': LocalizationService.tr('disputeResolutionDesk'), 'icon': Icons.gavel_rounded, 'badge': _activeDisputesCount},
      {'title': LocalizationService.tr('systemAuditLogs'), 'icon': Icons.history_edu_rounded, 'badge': 0},
    ];

    return Container(
      width: 260,
      color: HomeEaseTheme.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HomeEaseTheme.brand, Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: HomeEaseTheme.brandGlow,
                ),
                child: const Center(
                  child: Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HomeEase',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: HomeEaseTheme.brand,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      LocalizationService.tr('adminDashboard'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: HomeEaseTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Navigation Links
          Expanded(
            child: ListView.separated(
              itemCount: navItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = _selectedTabIndex == index;
                final badgeCount = item['badge'] as int;

                return Semantics(
                  button: true,
                  label: item['title'] as String,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTabIndex = index);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? HomeEaseTheme.brand : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 20,
                            color: isSelected ? Colors.white : HomeEaseTheme.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? Colors.white : HomeEaseTheme.text,
                              ),
                            ),
                          ),
                          if (badgeCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : HomeEaseTheme.statusConflict,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? HomeEaseTheme.brand : Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Admin Profile Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HomeEaseTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: HomeEaseTheme.brand.withValues(alpha: 0.15),
                  child: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: HomeEaseTheme.brand),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.tr('administrator'),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      const Text(
                        'admin@homeease.com',
                        style: TextStyle(fontSize: 11, color: HomeEaseTheme.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Logout Button
          Semantics(
            button: true,
            label: LocalizationService.tr('logout'),
            child: InkWell(
              onTap: widget.onLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HomeEaseTheme.statusConflict.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HomeEaseTheme.statusConflict.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 18, color: HomeEaseTheme.statusConflict),
                    const SizedBox(width: 8),
                    Text(
                      LocalizationService.tr('logout'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: HomeEaseTheme.statusConflict,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT (< 900dp)
  // ===========================================================================
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildTopHeader(isWide: false),
        _buildMobileTabBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildActiveTabContent(isWide: false),
        ),
      ],
    );
  }

  Widget _buildTopHeader({required bool isWide}) {
    final titles = [
      LocalizationService.tr('platformAnalytics'),
      LocalizationService.tr('workerVerificationDesk'),
      LocalizationService.tr('disputeResolutionDesk'),
      LocalizationService.tr('systemAuditLogs'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        border: Border(
          bottom: BorderSide(color: HomeEaseTheme.outline.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: HomeEaseTheme.brand,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWide ? titles[_selectedTabIndex] : LocalizationService.tr('homeEaseAdmin'),
                  style: TextStyle(
                    fontSize: isWide ? 20 : 16,
                    fontWeight: FontWeight.w800,
                    color: HomeEaseTheme.text,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: HomeEaseTheme.statusVerified,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        LocalizationService.tr('abbottabadRegionalNode'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: HomeEaseTheme.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Language Toggle Pill (minSize >= 48dp)
          Semantics(
            button: true,
            label: 'Language Toggle ${LocalizationService.isUrdu ? "English" : "اردو"}',
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  LocalizationService.toggleLanguage();
                });
                widget.onLanguageChanged?.call();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HomeEaseTheme.brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HomeEaseTheme.brand.withValues(alpha: 0.3)),
                ),
                child: Text(
                  LocalizationService.isUrdu ? 'English' : 'اردو',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: HomeEaseTheme.brand,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Refresh Button (minSize >= 48dp)
          Semantics(
            button: true,
            label: LocalizationService.tr('refresh'),
            child: InkWell(
              onTap: _loadAllData,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HomeEaseTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.refresh_rounded, size: 20, color: HomeEaseTheme.brand),
              ),
            ),
          ),

          if (!isWide) ...[
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: LocalizationService.tr('logout'),
              child: InkWell(
                onTap: widget.onLogout,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(Icons.logout_rounded, size: 20, color: HomeEaseTheme.statusConflict),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileTabBar() {
    final tabs = [
      {'label': LocalizationService.tr('platformAnalytics'), 'badge': 0},
      {'label': LocalizationService.tr('workerVerificationDesk'), 'badge': _pendingWorkersCount},
      {'label': LocalizationService.tr('disputeResolutionDesk'), 'badge': _activeDisputesCount},
      {'label': LocalizationService.tr('systemAuditLogs'), 'badge': 0},
    ];

    return Container(
      height: 56,
      color: HomeEaseTheme.card,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          final item = tabs[index];
          final badge = item['badge'] as int;

          return Semantics(
            button: true,
            label: item['label'] as String,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabIndex = index);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? HomeEaseTheme.brand
                        : HomeEaseTheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : HomeEaseTheme.text,
                      ),
                    ),
                    if (badge > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : HomeEaseTheme.statusConflict,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badge',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? HomeEaseTheme.brand : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // ACTIVE TAB ROUTER
  // ===========================================================================
  Widget _buildActiveTabContent({required bool isWide}) {
    switch (_selectedTabIndex) {
      case 0:
        return AnalyticsDesk(
          bookings: _allBookings,
          workers: _allWorkers,
          disputes: _allDisputes,
          isWide: isWide,
          onRefresh: _loadAllData,
        );
      case 1:
        return VerificationDesk(
          workers: _allWorkers,
          isWide: isWide,
          onApproveWorker: _approveWorker,
          onRejectWorker: _rejectWorker,
        );
      case 2:
        return DisputesDesk(
          disputes: _allDisputes,
          isWide: isWide,
          onAdjudicateDispute: _adjudicateDispute,
        );
      case 3:
        return AuditLogsDesk(
          auditService: _auditService,
          isWide: isWide,
        );
      default:
        return AnalyticsDesk(
          bookings: _allBookings,
          workers: _allWorkers,
          disputes: _allDisputes,
          isWide: isWide,
        );
    }
  }
}
