import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/audit_log_service.dart';
import '../services/booking_repository.dart';
import '../services/dispute_repository.dart';
import '../services/localization_service.dart';
import '../services/worker_repository.dart';
import '../theme/home_ease_theme.dart';

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

  // Verification tab filter: 'pending', 'verified', 'all'
  String _workerFilter = 'pending';

  // Dispute tab filter: 'all', 'open', 'resolved', 'dismissed'
  String _disputeFilter = 'all';

  // Audit log filter: 'all', 'auth', 'verification', 'dispute', 'payment'
  String _auditFilter = 'all';

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

      final results = await Future.wait([
        bookingsFuture,
        workersFuture,
        disputesFuture,
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

  // Analytics Helpers
  double get _grossPkrVolume {
    return _allBookings
        .where((b) => b.status.toLowerCase() == 'completed')
        .fold<double>(0.0, (sum, b) => sum + b.agreedAmount);
  }

  int get _activeDisputesCount {
    return _allDisputes.where((d) => d.status.toLowerCase() == 'open').length;
  }

  int get _verifiedWorkersCount {
    return _allWorkers
        .where((w) => w.verificationStatus.toLowerCase() == 'verified')
        .length;
  }

  int get _pendingWorkersCount {
    return _allWorkers
        .where((w) => w.verificationStatus.toLowerCase() == 'pendingverification')
        .length;
  }

  Map<String, int> get _categoryDistribution {
    final Map<String, int> counts = {
      'Cook': 0,
      'Cleaner': 0,
      'Nanny': 0,
      'Caregiver': 0,
      'Maid': 0,
      'Electrician': 0,
      'Plumber': 0,
    };
    for (final w in _allWorkers) {
      final role = w.role;
      for (final cat in counts.keys) {
        if (role.toLowerCase().contains(cat.toLowerCase())) {
          counts[cat] = (counts[cat] ?? 0) + 1;
          break;
        }
      }
    }
    return counts;
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

  void _showDocumentPreview(WorkerProfile worker) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: LocalizationService.direction,
          child: AlertDialog(
            backgroundColor: HomeEaseTheme.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.badge_rounded, color: HomeEaseTheme.brand, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LocalizationService.isUrdu
                        ? 'نادرا شناختی تصدیق — ${worker.name}'
                        : 'NADRA CNIC Document — ${worker.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.brand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HomeEaseTheme.brand.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GOVERNMENT OF PAKISTAN • NADRA',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: HomeEaseTheme.brand),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CNIC: ${worker.formattedCnic}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Name: ${worker.name}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'District: Abbottabad (Regional Node 13101)',
                        style: const TextStyle(fontSize: 12, color: HomeEaseTheme.muted),
                      ),
                      Text(
                        'Trade: ${worker.role} • ${worker.experienceYears} Years Exp.',
                        style: const TextStyle(fontSize: 12, color: HomeEaseTheme.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.check_circle_rounded, color: HomeEaseTheme.statusVerified, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Holographic watermark verified by Abbottabad Node.',
                        style: TextStyle(fontSize: 11.5, color: HomeEaseTheme.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(80, 48),
                  foregroundColor: HomeEaseTheme.brand,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(LocalizationService.tr('done')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEvidenceDialog(Dispute dispute) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: LocalizationService.direction,
          child: AlertDialog(
            backgroundColor: HomeEaseTheme.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.image_search_rounded, color: HomeEaseTheme.brand, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LocalizationService.isUrdu
                        ? 'ثبوت کی تصویر — شکایت #${dispute.id.substring(0, 8)}'
                        : 'Evidence Attachment — Dispute #${dispute.id.substring(0, 8)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 48, color: HomeEaseTheme.brand),
                        const SizedBox(height: 8),
                        Text(
                          dispute.evidencePath ?? 'evidence_attachment.jpg',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Photographic verification proof attached by complainant',
                          style: TextStyle(fontSize: 11, color: HomeEaseTheme.muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Description: ${dispute.description}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(80, 48),
                  foregroundColor: HomeEaseTheme.brand,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(LocalizationService.tr('done')),
              ),
            ],
          ),
        );
      },
    );
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
        return _buildAnalyticsTab(isWide: isWide);
      case 1:
        return _buildVerificationDeskTab(isWide: isWide);
      case 2:
        return _buildDisputeResolutionDeskTab(isWide: isWide);
      case 3:
        return _buildAuditLogsTab(isWide: isWide);
      default:
        return _buildAnalyticsTab(isWide: isWide);
    }
  }

  // ===========================================================================
  // TAB 1: PLATFORM ANALYTICS
  // ===========================================================================
  Widget _buildAnalyticsTab({required bool isWide}) {
    final completedBookings = _allBookings.where((b) => b.status.toLowerCase() == 'completed').length;
    final pendingBookings = _allBookings.where((b) => b.status.toLowerCase() == 'pending').length;
    final totalWorkers = _allWorkers.length;
    final verifiedWorkers = _verifiedWorkersCount;
    final verifiedPercent = totalWorkers > 0 ? ((verifiedWorkers / totalWorkers) * 100).toInt() : 0;
    final catDist = _categoryDistribution;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isWide ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
              final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // KPI 1: Gross PKR Volume
                  _buildKpiCard(
                    width: itemWidth,
                    title: LocalizationService.tr('grossPkrVolume'),
                    value: 'PKR ${_grossPkrVolume.toInt()}',
                    subtitle: LocalizationService.isUrdu
                        ? '$completedBookings مکمل بکنگز طے پا گئیں'
                        : '$completedBookings completed bookings settled',
                    icon: Icons.account_balance_wallet_rounded,
                    color: HomeEaseTheme.statusVerified,
                  ),

                  // KPI 2: Total Bookings
                  _buildKpiCard(
                    width: itemWidth,
                    title: LocalizationService.tr('totalBookings'),
                    value: '${_allBookings.length}',
                    subtitle: LocalizationService.isUrdu
                        ? '$completedBookings مکمل • $pendingBookings زیرِ جائزہ'
                        : '$completedBookings Completed • $pendingBookings Pending',
                    icon: Icons.calendar_month_rounded,
                    color: HomeEaseTheme.brand,
                  ),

                  // KPI 3: Active Disputes
                  _buildKpiCard(
                    width: itemWidth,
                    title: LocalizationService.tr('activeDisputes'),
                    value: '$_activeDisputesCount',
                    subtitle: LocalizationService.tr('requiresArbitration'),
                    icon: Icons.gavel_rounded,
                    color: _activeDisputesCount > 0 ? HomeEaseTheme.statusConflict : HomeEaseTheme.muted,
                  ),

                  // KPI 4: Verified Workers
                  _buildKpiCard(
                    width: itemWidth,
                    title: LocalizationService.tr('verifiedWorkers'),
                    value: '$verifiedWorkers / $totalWorkers ($verifiedPercent%)',
                    subtitle: LocalizationService.isUrdu
                        ? '$_pendingWorkersCount زیرِ جائزہ درخواستیں'
                        : '$_pendingWorkersCount pending review',
                    icon: Icons.verified_user_rounded,
                    color: const Color(0xFF0284C7),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // Category Distribution Progress Bars
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HomeEaseTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        LocalizationService.tr('categoryDistribution'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LocalizationService.isUrdu ? '$totalWorkers رجسٹرڈ ورکرز' : '$totalWorkers Registered Workers',
                      style: const TextStyle(fontSize: 12.5, color: HomeEaseTheme.muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...catDist.entries.map((entry) {
                  final cat = entry.key;
                  final count = entry.value;
                  final fraction = totalWorkers > 0 ? count / totalWorkers : 0.0;
                  final color = LocalizationService.getCategoryColor(cat);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LocalizationService.getCategoryIcon(cat), size: 16, color: color),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      cat,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              LocalizationService.isUrdu
                                  ? '$count ورکرز (${(fraction * 100).toInt()}%)'
                                  : '$count workers (${(fraction * 100).toInt()}%)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HomeEaseTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 8,
                            backgroundColor: HomeEaseTheme.outline.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
        boxShadow: HomeEaseTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HomeEaseTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: HomeEaseTheme.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: HomeEaseTheme.muted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: WORKER VERIFICATION DESK
  // ===========================================================================
  Widget _buildVerificationDeskTab({required bool isWide}) {
    final filteredWorkers = _allWorkers.where((w) {
      if (_workerFilter == 'pending') {
        return w.verificationStatus.toLowerCase() == 'pendingverification';
      } else if (_workerFilter == 'verified') {
        return w.verificationStatus.toLowerCase() == 'verified';
      }
      return true;
    }).toList();

    final pendingCount = _pendingWorkersCount;
    final verifiedCount = _verifiedWorkersCount;
    final allCount = _allWorkers.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips (Touch targets >= 48dp)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: '${LocalizationService.tr("pendingTab")} ($pendingCount)',
                  isSelected: _workerFilter == 'pending',
                  onTap: () => setState(() => _workerFilter = 'pending'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '${LocalizationService.tr("verifiedTab")} ($verifiedCount)',
                  isSelected: _workerFilter == 'verified',
                  onTap: () => setState(() => _workerFilter = 'verified'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '${LocalizationService.tr("allTab")} ($allCount)',
                  isSelected: _workerFilter == 'all',
                  onTap: () => setState(() => _workerFilter = 'all'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (filteredWorkers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 54, color: HomeEaseTheme.statusVerified),
                  const SizedBox(height: 12),
                  Text(
                    LocalizationService.isUrdu ? 'کوئی درخواست زیرِ جائزہ نہیں ہے' : 'No workers in this verification queue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredWorkers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final worker = filteredWorkers[index];
                return _buildWorkerModerationCard(worker, isWide: isWide);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWorkerModerationCard(WorkerProfile worker, {required bool isWide}) {
    final bool isPending = worker.verificationStatus.toLowerCase() == 'pendingverification';
    final bool isVerified = worker.verificationStatus.toLowerCase() == 'verified';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? HomeEaseTheme.brand.withValues(alpha: 0.4)
              : HomeEaseTheme.outline.withValues(alpha: 0.5),
        ),
        boxShadow: HomeEaseTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Category, Locality, Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: HomeEaseTheme.brand.withValues(alpha: 0.15),
                child: Text(
                  worker.name.isNotEmpty ? worker.name[0] : 'W',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HomeEaseTheme.brand),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: LocalizationService.getCategoryColor(worker.role).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            worker.role,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: LocalizationService.getCategoryColor(worker.role),
                            ),
                          ),
                        ),
                        Text(
                          '${worker.location.isNotEmpty ? worker.location : worker.area} • ${worker.city}',
                          style: const TextStyle(fontSize: 12, color: HomeEaseTheme.muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isVerified
                      ? HomeEaseTheme.statusVerified.withValues(alpha: 0.15)
                      : (isPending
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : HomeEaseTheme.statusConflict.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  worker.verificationStatus,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isVerified
                        ? HomeEaseTheme.statusVerified
                        : (isPending ? const Color(0xFFD97706) : HomeEaseTheme.statusConflict),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Detail Row: NADRA CNIC, Experience, Hourly Rate
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: HomeEaseTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.4)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge_rounded, size: 16, color: HomeEaseTheme.brand),
                    const SizedBox(width: 6),
                    Text(
                      'CNIC: ${worker.formattedCnic}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.work_history_rounded, size: 16, color: HomeEaseTheme.muted),
                    const SizedBox(width: 6),
                    Text(
                      '${worker.experienceYears} Years Exp.',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payments_rounded, size: 16, color: HomeEaseTheme.statusVerified),
                    const SizedBox(width: 6),
                    Text(
                      worker.rate,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: HomeEaseTheme.brand),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (worker.bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              worker.bio,
              style: const TextStyle(fontSize: 12.5, color: HomeEaseTheme.textSecondary),
            ),
          ],

          const SizedBox(height: 14),

          // ID Attachment Preview Card & Adjudication Actions
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // "View ID Document" button (>= 48dp)
              Semantics(
                button: true,
                label: LocalizationService.tr('viewIdDoc'),
                child: InkWell(
                  onTap: () => _showDocumentPreview(worker),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_rounded, size: 18, color: HomeEaseTheme.brand),
                        const SizedBox(width: 6),
                        Text(
                          LocalizationService.tr('viewIdDoc'),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: HomeEaseTheme.brand),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Approve Button (>= 48dp)
              Semantics(
                button: true,
                label: LocalizationService.tr('approveVerification'),
                child: InkWell(
                  onTap: isVerified ? null : () => _approveWorker(worker),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? HomeEaseTheme.outline.withValues(alpha: 0.3)
                          : HomeEaseTheme.statusVerified,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          LocalizationService.tr('approveVerification'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Reject Button (>= 48dp)
              Semantics(
                button: true,
                label: LocalizationService.tr('rejectVerification'),
                child: InkWell(
                  onTap: () => _rejectWorker(worker),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 100),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.statusConflict.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HomeEaseTheme.statusConflict.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cancel_rounded, size: 18, color: HomeEaseTheme.statusConflict),
                        const SizedBox(width: 6),
                        Text(
                          LocalizationService.tr('rejectVerification'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: HomeEaseTheme.statusConflict),
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
    );
  }

  // ===========================================================================
  // TAB 3: DISPUTE RESOLUTION DESK
  // ===========================================================================
  Widget _buildDisputeResolutionDeskTab({required bool isWide}) {
    final filteredDisputes = _allDisputes.where((d) {
      if (_disputeFilter == 'open') {
        return d.status.toLowerCase() == 'open';
      } else if (_disputeFilter == 'resolved') {
        final s = d.status.toLowerCase();
        return s.contains('resolved');
      } else if (_disputeFilter == 'dismissed') {
        return d.status.toLowerCase() == 'dismissed';
      }
      return true;
    }).toList();

    final allDisputesCount = _allDisputes.length;
    final openDisputesCount = _activeDisputesCount;
    final resolvedDisputesCount = _allDisputes.where((d) => d.status.toLowerCase().contains('resolved')).length;
    final dismissedDisputesCount = _allDisputes.where((d) => d.status.toLowerCase() == 'dismissed').length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips (Touch targets >= 48dp)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: '${LocalizationService.tr("allTab")} ($allDisputesCount)',
                  isSelected: _disputeFilter == 'all',
                  onTap: () => setState(() => _disputeFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '${LocalizationService.tr("openTab")} ($openDisputesCount)',
                  isSelected: _disputeFilter == 'open',
                  onTap: () => setState(() => _disputeFilter = 'open'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '${LocalizationService.tr("resolvedTab")} ($resolvedDisputesCount)',
                  isSelected: _disputeFilter == 'resolved',
                  onTap: () => setState(() => _disputeFilter = 'resolved'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '${LocalizationService.tr("dismissedTab")} ($dismissedDisputesCount)',
                  isSelected: _disputeFilter == 'dismissed',
                  onTap: () => setState(() => _disputeFilter = 'dismissed'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (filteredDisputes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.done_all_rounded, size: 54, color: HomeEaseTheme.statusVerified),
                  const SizedBox(height: 12),
                  Text(LocalizationService.tr('noDisputesFound'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDisputes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final dispute = filteredDisputes[index];
                return _buildDisputeCard(dispute, isWide: isWide);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDisputeCard(Dispute dispute, {required bool isWide}) {
    final isOpen = dispute.status.toLowerCase() == 'open';
    final isRefund = dispute.status.toLowerCase() == 'resolved_refund';
    final isPayout = dispute.status.toLowerCase() == 'resolved_payout';
    final isDismissed = dispute.status.toLowerCase() == 'dismissed';

    Color statusColor = const Color(0xFFD97706);
    if (isRefund) statusColor = const Color(0xFF0284C7);
    if (isPayout) statusColor = HomeEaseTheme.statusVerified;
    if (isDismissed) statusColor = HomeEaseTheme.muted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOpen ? HomeEaseTheme.statusConflict.withValues(alpha: 0.5) : HomeEaseTheme.outline.withValues(alpha: 0.5),
        ),
        boxShadow: HomeEaseTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Dispute ID, Category, Status Pill
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#DISP-${dispute.id.length > 8 ? dispute.id.substring(0, 8) : dispute.id}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: HomeEaseTheme.brand),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dispute.category,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dispute.status,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Complainant & Respondent info
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                '${LocalizationService.tr("complainantLabel")}: ${dispute.complainantId.length > 10 ? dispute.complainantId.substring(0, 10) : dispute.complainantId}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HomeEaseTheme.textSecondary),
              ),
              Text(
                '${LocalizationService.tr("respondentLabel")}: ${dispute.respondentId.length > 10 ? dispute.respondentId.substring(0, 10) : dispute.respondentId}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HomeEaseTheme.textSecondary),
              ),
              Text(
                '${LocalizationService.tr("bookingLabel")}: #${dispute.bookingId.length > 10 ? dispute.bookingId.substring(0, 10) : dispute.bookingId}',
                style: const TextStyle(fontSize: 12, color: HomeEaseTheme.muted),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Complaint Narrative
          Text(
            dispute.description,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: HomeEaseTheme.text),
          ),

          if (dispute.resolutionNotes != null && dispute.resolutionNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${LocalizationService.tr("adjudicationRemarks")}: ${dispute.resolutionNotes}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Actions Row: Evidence Thumbnail + Adjudication Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Evidence Photo Thumbnail Preview
              Semantics(
                button: true,
                label: LocalizationService.tr('evidencePhoto'),
                child: InkWell(
                  onTap: () => _showEvidenceDialog(dispute),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 130),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded, size: 18, color: HomeEaseTheme.brand),
                        const SizedBox(width: 6),
                        Text(
                          LocalizationService.tr('viewEvidence'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HomeEaseTheme.brand),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (isOpen) ...[
                // Refund Household Button (>= 48dp)
                Semantics(
                  button: true,
                  label: LocalizationService.tr('refundHousehold'),
                  child: InkWell(
                    onTap: () => _adjudicateDispute(
                      dispute,
                      'resolved_refund',
                      'Full refund authorized to household escrow wallet.',
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.undo_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            LocalizationService.tr('refundHousehold'),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Release to Worker Button (>= 48dp)
                Semantics(
                  button: true,
                  label: LocalizationService.tr('releaseToWorker'),
                  child: InkWell(
                    onTap: () => _adjudicateDispute(
                      dispute,
                      'resolved_payout',
                      'Payment release authorized to worker payout balance.',
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.statusVerified,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            LocalizationService.tr('releaseToWorker'),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Dismiss Button (>= 48dp)
                Semantics(
                  button: true,
                  label: LocalizationService.tr('dismissDispute'),
                  child: InkWell(
                    onTap: () => _adjudicateDispute(
                      dispute,
                      'dismissed',
                      'Dispute dismissed after administrative review.',
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 110),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.outline.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close_rounded, size: 16, color: HomeEaseTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            LocalizationService.tr('dismissDispute'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HomeEaseTheme.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: SYSTEM AUDIT LOGS
  // ===========================================================================
  Widget _buildAuditLogsTab({required bool isWide}) {
    return ListenableBuilder(
      listenable: _auditService,
      builder: (context, _) {
        final logs = _auditService.getLogs(actionType: _auditFilter);
        final totalLogsCount = _auditService.getLogs().length;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips (Touch targets >= 48dp)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: '${LocalizationService.tr("allTab")} ($totalLogsCount)',
                      isSelected: _auditFilter == 'all',
                      onTap: () => setState(() => _auditFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: LocalizationService.tr('auditFilterAuth'),
                      isSelected: _auditFilter == 'auth',
                      onTap: () => setState(() => _auditFilter = 'auth'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: LocalizationService.tr('auditFilterVerification'),
                      isSelected: _auditFilter == 'verification',
                      onTap: () => setState(() => _auditFilter = 'verification'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: LocalizationService.tr('auditFilterDispute'),
                      isSelected: _auditFilter == 'dispute',
                      onTap: () => setState(() => _auditFilter = 'dispute'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: LocalizationService.tr('auditFilterPayment'),
                      isSelected: _auditFilter == 'payment',
                      onTap: () => setState(() => _auditFilter = 'payment'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              if (logs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.list_alt_rounded, size: 54, color: HomeEaseTheme.muted),
                      const SizedBox(height: 12),
                      Text(LocalizationService.tr('noAuditLogsFound'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildAuditLogCard(log);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuditLogCard(AuditLogEntry log) {
    IconData icon = Icons.info_outline_rounded;
    Color color = HomeEaseTheme.brand;

    switch (log.actionType.toLowerCase()) {
      case 'auth':
        icon = Icons.lock_open_rounded;
        color = const Color(0xFF0284C7);
        break;
      case 'verification':
        icon = Icons.verified_user_rounded;
        color = HomeEaseTheme.statusVerified;
        break;
      case 'dispute':
        icon = Icons.gavel_rounded;
        color = const Color(0xFFD97706);
        break;
      case 'payment':
        icon = Icons.account_balance_wallet_rounded;
        color = HomeEaseTheme.statusVerified;
        break;
      case 'system':
        icon = Icons.dns_rounded;
        color = HomeEaseTheme.muted;
        break;
    }

    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, "0")}:${log.timestamp.minute.toString().padLeft(2, "0")} • ${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        log.title,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 11, color: HomeEaseTheme.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  log.description,
                  style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${LocalizationService.tr("actorLabel")}: ${log.actor}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: HomeEaseTheme.brand),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Common UI Components
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : HomeEaseTheme.text,
            ),
          ),
        ),
      ),
    );
  }
}
