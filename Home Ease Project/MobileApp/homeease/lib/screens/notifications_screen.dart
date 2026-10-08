import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.notifications,
    required this.onBack,
    required this.onClearAll,
    required this.onMarkAsRead,
  });

  final List<NotificationModel> notifications;
  final VoidCallback onBack;
  final VoidCallback onClearAll;
  final ValueChanged<NotificationModel> onMarkAsRead;

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Booking':
        return Icons.calendar_month_rounded;
      case 'Payment':
        return Icons.receipt_long_rounded;
      case 'Dispute':
        return Icons.gavel_rounded;
      case 'Verification':
        return Icons.verified_user_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Booking':
        return HomeEaseTheme.statusInfo;
      case 'Payment':
        return HomeEaseTheme.statusVerified;
      case 'Dispute':
        return HomeEaseTheme.statusConflict;
      case 'Verification':
        return HomeEaseTheme.brandSoft;
      default:
        return HomeEaseTheme.brand;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notifications',
      subtitle: 'Stay updated on bookings and payments.',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notifications.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearAll,
                icon: const Icon(Icons.clear_all_rounded, color: HomeEaseTheme.brandSoft),
                label: const Text('Clear All', style: TextStyle(color: HomeEaseTheme.brandSoft)),
              ),
            ),
          if (notifications.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: HomeEaseTheme.cardDark,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No new notifications.',
                      style: TextStyle(
                        fontSize: 16,
                        color: HomeEaseTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...notifications.map((notif) {
              final dateStr =
                  '${notif.createdAt.hour.toString().padLeft(2, '0')}:${notif.createdAt.minute.toString().padLeft(2, '0')}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onMarkAsRead(notif),
                  borderRadius: BorderRadius.circular(24),
                  child: HomeEaseCard(
                    color: notif.isRead ? HomeEaseTheme.white : HomeEaseTheme.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _getColorForType(notif.type).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(notif.type),
                            color: _getColorForType(notif.type),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontWeight: notif.isRead ? FontWeight.bold : FontWeight.w900,
                                        fontSize: 14,
                                        color: HomeEaseTheme.text,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: notif.isRead ? HomeEaseTheme.muted : HomeEaseTheme.text,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: HomeEaseTheme.brandSoft,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
