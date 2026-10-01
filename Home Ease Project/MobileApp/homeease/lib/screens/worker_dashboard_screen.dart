import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({
    super.key,
    required this.bookings,
    required this.verificationStatus,
    this.workerName,
    required this.onAcceptBooking,
    required this.onRejectBooking,
    required this.onManageAvailability,
    required this.onOpenNotifications,
    required this.unreadNotificationsCount,
    required this.onSelectBooking,
    required this.onLogout,
    this.onBrowseAvailableJobs,
    this.onLanguageChanged,
  });

  final List<Booking> bookings;
  final String verificationStatus;
  final String? workerName;
  final ValueChanged<Booking> onAcceptBooking;
  final ValueChanged<Booking> onRejectBooking;
  final VoidCallback onManageAvailability;
  final VoidCallback onOpenNotifications;
  final int unreadNotificationsCount;
  final ValueChanged<Booking> onSelectBooking;
  final VoidCallback onLogout;
  final VoidCallback? onBrowseAvailableJobs;
  final VoidCallback? onLanguageChanged;

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final pendingRequests = widget.bookings.where((b) => b.status == 'Pending').toList();
    final acceptedJobs = widget.bookings.where((b) => b.status == 'Accepted').toList();

    final welcomeSubtitle = widget.workerName != null
        ? (isUrdu ? 'خوش آمدید، ${widget.workerName}' : 'Welcome back, ${widget.workerName}')
        : null;

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AppScaffold(
        title: LocalizationService.tr('workerDashboard'),
        subtitle: welcomeSubtitle,
        onLogout: widget.onLogout,
        trailing: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            LocalizationService.toggleLanguage();
            setState(() {});
            widget.onLanguageChanged?.call();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HomeEaseTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HomeEaseTheme.brandSoft.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate_rounded, size: 16, color: HomeEaseTheme.brand),
                const SizedBox(width: 4),
                Text(
                  isUrdu ? 'English' : 'اردو',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: HomeEaseTheme.brand,
                  ),
                ),
              ],
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onManageAvailability();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: HomeEaseCard(
                      color: HomeEaseTheme.cardDark,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: HomeEaseTheme.brand, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            LocalizationService.tr('availability'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onOpenNotifications();
                    },
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
                              if (widget.unreadNotificationsCount > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                    child: Text(
                                      '${widget.unreadNotificationsCount}',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LocalizationService.tr('notifications'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bidirectional Marketplace: Browse Available Household Gigs Banner
            if (widget.onBrowseAvailableJobs != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onBrowseAvailableJobs!();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.25),
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
                          child: const Icon(Icons.explore_rounded, color: Colors.white, size: 28),
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
                                  fontSize: 16,
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
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isUrdu ? 'دیکھیں' : 'Browse',
                            style: const TextStyle(
                              color: Color(0xFF0F766E),
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
                              widget.verificationStatus == 'PendingVerification'
                                  ? (isUrdu ? 'تصدیق کا عمل جاری ہے' : 'Verification Pending')
                                  : (isUrdu ? 'پروفائل غیر تصدیق شدہ' : 'Profile Unverified'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.verificationStatus == 'PendingVerification'
                                  ? (isUrdu
                                      ? 'ایڈمن آپ کی تفصیلات کا جائزہ لے رہا ہے۔ تصدیق کے بعد آپ تلاش میں ظاہر ہوں گے۔'
                                      : 'Admin is reviewing your details. Once verified, you will appear in search results.')
                                  : (isUrdu
                                      ? 'براہ کرم تصدیق کے لیے اپنی پروفائل اور شناختی کارڈ کی کاپی جمع کرائیں۔'
                                      : 'Please submit your profile and CNIC copy for verification.'),
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
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUrdu ? 'تصدیق شدہ ورکر بیج' : 'Verified Profile Badge',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isUrdu
                                  ? 'آپ کی پروفائل مکمل تصدیق شدہ ہے۔ آپ گھریلو تلاش کے نتائج میں نظر آ رہے ہیں۔'
                                  : 'Your profile is fully verified. You are visible in household search results.',
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
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
                    title: '${pendingRequests.length} ${isUrdu ? 'درخواستیں' : 'Requests'}',
                    subtitle: isUrdu ? 'جواب کے منتظر' : 'Pending response',
                    color: HomeEaseTheme.cardDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: '${acceptedJobs.length} ${isUrdu ? 'ملازمتیں' : 'Jobs'}',
                    subtitle: isUrdu ? 'تصدیق شدہ کام' : 'Confirmed tasks',
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
                  SectionLabel(LocalizationService.tr('incomingRequests')),
                  const SizedBox(height: 12),
                  if (pendingRequests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        isUrdu ? 'اس وقت کوئی نئی بکنگ درخواست نہیں ہے۔' : 'No pending booking requests.',
                        style: const TextStyle(color: HomeEaseTheme.muted),
                      ),
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
                              Row(
                                children: [
                                  Icon(
                                    LocalizationService.getCategoryIcon(booking.serviceCategoryId),
                                    color: LocalizationService.getCategoryColor(booking.serviceCategoryId),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isUrdu ? LocalizationService.tr(booking.serviceCategoryId.toLowerCase()) : booking.serviceCategoryId,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: LocalizationService.getCategoryColor(booking.serviceCategoryId),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: HomeEaseTheme.text, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
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
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        widget.onAcceptBooking(booking);
                                      },
                                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                      child: Text(isUrdu ? 'قبول کریں' : 'Accept'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        widget.onRejectBooking(booking);
                                      },
                                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                      child: Text(isUrdu ? 'مسترد کریں' : 'Decline'),
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
                  SectionLabel(isUrdu ? 'جاری کام اور معاہدے' : 'Active Jobs & Payments'),
                  const SizedBox(height: 12),
                  if (acceptedJobs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        isUrdu ? 'اس وقت کوئی فعال کام نہیں ہے۔' : 'No active jobs at the moment.',
                        style: const TextStyle(color: HomeEaseTheme.muted),
                      ),
                    )
                  else
                    ...acceptedJobs.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => widget.onSelectBooking(booking),
                          borderRadius: BorderRadius.circular(16),
                          child: HomeEaseCard(
                            color: HomeEaseTheme.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  LocalizationService.getCategoryIcon(booking.serviceCategoryId),
                                  color: LocalizationService.getCategoryColor(booking.serviceCategoryId),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${isUrdu ? LocalizationService.tr(booking.serviceCategoryId.toLowerCase()) : booking.serviceCategoryId} - ${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
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
