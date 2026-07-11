import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({
    super.key,
    required this.bookings,
    required this.verificationStatus,
    required this.onAcceptBooking,
    required this.onRejectBooking,
    required this.onManageAvailability,
    required this.onOpenNotifications,
    required this.unreadNotificationsCount,
    required this.onSelectBooking,
    required this.onLogout,
  });

  final List<Booking> bookings;
  final String verificationStatus;
  final ValueChanged<Booking> onAcceptBooking;
  final ValueChanged<Booking> onRejectBooking;
  final VoidCallback onManageAvailability;
  final VoidCallback onOpenNotifications;
  final int unreadNotificationsCount;
  final ValueChanged<Booking> onSelectBooking;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final pendingRequests = bookings.where((b) => b.status == 'Pending').toList();
    final acceptedJobs = bookings.where((b) => b.status == 'Accepted').toList();

    return AppScaffold(
      title: 'Worker dashboard',
      onLogout: onLogout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onManageAvailability,
                  borderRadius: BorderRadius.circular(20),
                  child: const HomeEaseCard(
                    color: HomeEaseTheme.cardDark,
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_rounded, color: HomeEaseTheme.brand, size: 18),
                        SizedBox(width: 8),
                        Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onOpenNotifications,
                  borderRadius: BorderRadius.circular(20),
                  child: HomeEaseCard(
                    color: HomeEaseTheme.card,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_rounded, color: HomeEaseTheme.brand, size: 18),
                            if (unreadNotificationsCount > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                  child: Text(
                                    '$unreadNotificationsCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Verification Status Banner
          if (verificationStatus != 'Verified')
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: HomeEaseCard(
                color: Colors.orange.shade50,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verificationStatus == 'PendingVerification'
                                ? 'Verification Pending'
                                : 'Profile Unverified',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            verificationStatus == 'PendingVerification'
                                ? 'Admin is reviewing your details. Once verified, you will appear in search results.'
                                : 'Please submit your profile and CNIC copy for verification.',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
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
                color: Colors.green.shade50,
                padding: const EdgeInsets.all(14),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Colors.green, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verified Profile Badge',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your profile is fully verified. You are visible in household search results.',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: '${pendingRequests.length} Requests',
                  subtitle: 'Pending response',
                  color: HomeEaseTheme.cardDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: '${acceptedJobs.length} Jobs',
                  subtitle: 'Confirmed tasks',
                  color: HomeEaseTheme.card,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Incoming Booking Requests'),
                const SizedBox(height: 12),
                if (pendingRequests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No pending booking requests.', style: TextStyle(color: HomeEaseTheme.muted)),
                  )
                else
                  ...pendingRequests.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: HomeEaseCard(
                        color: HomeEaseTheme.surface,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date: ${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: HomeEaseTheme.text),
                            ),
                            Text('Time: ${booking.startTime.format(context)} - ${booking.endTime.format(context)}'),
                            Text('Location: ${booking.address}'),
                            if (booking.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Notes: "${booking.notes}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => onAcceptBooking(booking),
                                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Accept'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => onRejectBooking(booking),
                                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Decline'),
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
          const SizedBox(height: 16),
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Active Jobs & Payments'),
                const SizedBox(height: 12),
                if (acceptedJobs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('No active jobs at the moment.', style: TextStyle(color: HomeEaseTheme.muted)),
                  )
                else
                  ...acceptedJobs.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => onSelectBooking(booking),
                        borderRadius: BorderRadius.circular(16),
                        child: HomeEaseCard(
                          color: HomeEaseTheme.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.work_rounded, color: HomeEaseTheme.brand),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Job on ${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text('Time: ${booking.startTime.format(context)}', style: const TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: HomeEaseTheme.brand),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HomeEaseCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
