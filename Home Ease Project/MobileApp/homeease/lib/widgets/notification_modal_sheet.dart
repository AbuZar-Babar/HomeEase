import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/notification_model.dart';
import '../services/localization_service.dart';
import '../services/notification_service.dart';
import '../theme/home_ease_theme.dart';

export '../models/notification_model.dart';
export '../services/notification_service.dart';

/// Serene Hearth In-App Notification Center Modal Sheet.
///
/// Features:
/// - Sleek modal bottom sheet with modern rounded card layout.
/// - Live Supabase fetch on open with graceful offline fallback.
/// - Unread badge tracking and live count updates.
/// - Filter chips for Payments, Bookings, Disputes, and Verification.
/// - Strict >= 48x48dp touch targets on all interactive elements.
/// - Full bilingual support (English LTR / Urdu RTL).
class NotificationModalSheet extends StatefulWidget {
  const NotificationModalSheet({
    super.key,
    this.userId,
    this.role,
    this.onNotificationTap,
  });

  final String? userId;
  final String? role;
  final ValueChanged<NotificationModel>? onNotificationTap;

  /// Shows the Notification Center as a sleek modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    String? userId,
    String? role,
    ValueChanged<NotificationModel>? onNotificationTap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationModalSheet(
        userId: userId,
        role: role,
        onNotificationTap: onNotificationTap,
      ),
    );
  }

  @override
  State<NotificationModalSheet> createState() => _NotificationModalSheetState();
}

class _NotificationModalSheetState extends State<NotificationModalSheet> {
  final NotificationService _service = NotificationService();
  String _selectedFilter = 'all'; // 'all', 'payment', 'booking', 'dispute', 'verification'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await _service.fetchNotifications(userId: widget.userId, role: widget.role);
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(DateTime dt, bool isUrdu) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return isUrdu ? 'ابھی' : 'Just now';
    } else if (diff.inMinutes < 60) {
      return isUrdu ? '${diff.inMinutes} منٹ پہلے' : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return isUrdu ? '${diff.inHours} گھنٹے پہلے' : '${diff.inHours}h ago';
    } else {
      return isUrdu ? '${diff.inDays} دن پہلے' : '${diff.inDays}d ago';
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.calendar_month_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'dispute':
        return Icons.gavel_rounded;
      case 'verification':
        return Icons.verified_user_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return const Color(0xFF0284C7); // Sky blue
      case 'payment':
        return HomeEaseTheme.statusVerified; // Emerald
      case 'dispute':
        return HomeEaseTheme.statusConflict; // Rose / Red
      case 'verification':
        return HomeEaseTheme.brand; // Teal
      default:
        return HomeEaseTheme.brand;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: LocalizationService.direction,
      child: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          final allNotifications = _service.notifications;
          final filteredNotifications = allNotifications.where((n) {
            if (_selectedFilter == 'all') return true;
            return n.type.toLowerCase() == _selectedFilter;
          }).toList();

          final unreadCount = _service.unreadCount;

          return Container(
            height: size.height * 0.85,
            decoration: const BoxDecoration(
              color: HomeEaseTheme.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.outline.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Top Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      // Bell Icon with Glow Container
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.brand.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: HomeEaseTheme.brand,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Unread Count Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isUrdu ? 'اطلاعات' : 'Notifications',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: HomeEaseTheme.textPrimary,
                                  ),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: HomeEaseTheme.statusConflict,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount ${isUrdu ? "نئی" : "new"}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isUrdu
                                  ? 'بکنگز، ادائیگیوں اور تصدیق کے الرٹس'
                                  : 'Bookings, payments & verification alerts',
                              style: const TextStyle(
                                fontSize: 12,
                                color: HomeEaseTheme.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mark All Read Button (>= 48x48dp)
                      if (allNotifications.any((n) => !n.isRead))
                        Semantics(
                          button: true,
                          label: isUrdu ? 'تمام پڑھ لی گئیں' : 'Mark all read',
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _service.markAllAsRead();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: const Icon(
                                Icons.done_all_rounded,
                                color: HomeEaseTheme.brand,
                                size: 22,
                              ),
                            ),
                          ),
                        ),

                      // Clear All Button (>= 48x48dp)
                      if (allNotifications.isNotEmpty)
                        Semantics(
                          button: true,
                          label: isUrdu ? 'تمام صاف کریں' : 'Clear all',
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _service.clearAll();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: const Icon(
                                Icons.delete_sweep_rounded,
                                color: HomeEaseTheme.muted,
                                size: 22,
                              ),
                            ),
                          ),
                        ),

                      // Close Button (>= 48x48dp)
                      Semantics(
                        button: true,
                        label: isUrdu ? 'بند کریں' : 'Close',
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close_rounded,
                              color: HomeEaseTheme.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: HomeEaseTheme.outline),

                // Category Filter Pills (>= 48dp touch height)
                SizedBox(
                  height: 64,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _buildFilterChip('all', isUrdu ? 'تمام' : 'All', allNotifications.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'payment',
                        isUrdu ? 'ادائیگیاں' : 'Payments',
                        allNotifications.where((n) => n.type.toLowerCase() == 'payment').length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'booking',
                        isUrdu ? 'بکنگز' : 'Bookings',
                        allNotifications.where((n) => n.type.toLowerCase() == 'booking').length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'dispute',
                        isUrdu ? 'تنازعات' : 'Disputes',
                        allNotifications.where((n) => n.type.toLowerCase() == 'dispute').length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'verification',
                        isUrdu ? 'تصدیق' : 'Verification',
                        allNotifications.where((n) => n.type.toLowerCase() == 'verification').length,
                      ),
                    ],
                  ),
                ),

                // Main Notifications List / Empty State
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: HomeEaseTheme.brand),
                        )
                      : filteredNotifications.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: HomeEaseTheme.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: HomeEaseTheme.outline.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none_rounded,
                                        size: 36,
                                        color: HomeEaseTheme.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isUrdu ? 'کوئی اطلاع موجود نہیں ہے' : 'No notifications yet',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: HomeEaseTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isUrdu
                                          ? 'جب بکنگز، ادائیگیاں، یا تصدیق تبدیل ہوگی تو یہاں الرٹ موصول ہوگا۔'
                                          : 'You will receive updates when bookings, escrow payments, or verification change.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: HomeEaseTheme.muted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: filteredNotifications.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final notif = filteredNotifications[index];
                                final iconColor = _getColorForType(notif.type);
                                final icon = _getIconForType(notif.type);

                                return Semantics(
                                  button: true,
                                  label: '${notif.localizedTitle(isUrdu)}, ${notif.isRead ? "read" : "unread"}',
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _service.markAsRead(notif.id);
                                      widget.onNotificationTap?.call(notif);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      constraints: const BoxConstraints(minHeight: 64),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: notif.isRead
                                            ? HomeEaseTheme.surface
                                            : HomeEaseTheme.brand.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: notif.isRead
                                              ? HomeEaseTheme.outline.withValues(alpha: 0.6)
                                              : HomeEaseTheme.brand.withValues(alpha: 0.35),
                                          width: notif.isRead ? 1.0 : 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Category Icon
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: iconColor.withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(icon, color: iconColor, size: 20),
                                          ),
                                          const SizedBox(width: 12),

                                          // Narrative
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notif.localizedTitle(isUrdu),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: notif.isRead
                                                              ? FontWeight.w700
                                                              : FontWeight.w800,
                                                          color: HomeEaseTheme.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _formatTimestamp(notif.createdAt, isUrdu),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                        color: HomeEaseTheme.muted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  notif.localizedMessage(isUrdu),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: notif.isRead
                                                        ? HomeEaseTheme.textSecondary
                                                        : HomeEaseTheme.textPrimary,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Unread Indicator Dot
                                          if (!notif.isRead) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              width: 9,
                                              height: 9,
                                              decoration: const BoxDecoration(
                                                color: HomeEaseTheme.statusConflict,
                                                shape: BoxShape.circle,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, int count) {
    final isSelected = _selectedFilter == filterKey;

    return Semantics(
      button: true,
      label: '$label ($count)',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = filterKey);
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
              color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : HomeEaseTheme.textPrimary,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : HomeEaseTheme.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.brand,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
