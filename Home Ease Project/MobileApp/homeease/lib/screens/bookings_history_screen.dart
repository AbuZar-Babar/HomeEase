import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class BookingsHistoryScreen extends StatelessWidget {
  const BookingsHistoryScreen({
    super.key,
    required this.bookings,
    required this.workers,
    required this.onBack,
    required this.onSelectBooking,
    required this.onRateBooking,
    required this.onRaiseDispute,
  });

  final List<Booking> bookings;
  final List<WorkerProfile> workers;
  final VoidCallback onBack;
  final ValueChanged<Booking> onSelectBooking;
  final ValueChanged<Booking> onRateBooking;
  final ValueChanged<Booking> onRaiseDispute;

  WorkerProfile _getWorker(String id) {
    return workers.firstWhere(
      (w) => w.id == id,
      orElse: () => workers.first,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Disputed':
        return Colors.red;
      case 'Cancelled':
      case 'Rejected':
        return Colors.grey;
      default:
        return HomeEaseTheme.brandSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Your bookings',
      subtitle: 'Track status, view agreements, and upload payments.',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bookings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.book_online_rounded,
                      size: 64,
                      color: HomeEaseTheme.cardDark,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No bookings found.',
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
            ...bookings.map((booking) {
              final worker = _getWorker(booking.workerId);
              final dateStr =
                  '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}';
              final timeStr =
                  '${booking.startTime.format(context)} - ${booking.endTime.format(context)}';

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
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status,
                              style: TextStyle(
                                color: _getStatusColor(booking.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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
                            children: [
                              if (booking.status == 'Accepted')
                                TextButton(
                                  onPressed: () => onSelectBooking(booking),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HomeEaseTheme.white,
                                    backgroundColor: HomeEaseTheme.brand,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('View Agreement'),
                                )
                              else
                                TextButton(
                                  onPressed: () => onSelectBooking(booking),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HomeEaseTheme.brand,
                                    backgroundColor: HomeEaseTheme.card,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('Details'),
                                ),
                              if (booking.status == 'Completed') ...[
                                TextButton(
                                  onPressed: () => onRateBooking(booking),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HomeEaseTheme.brand,
                                    backgroundColor: HomeEaseTheme.cardDark,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('Rate'),
                                ),
                                TextButton(
                                  onPressed: () => onRaiseDispute(booking),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  child: const Text('Dispute'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
