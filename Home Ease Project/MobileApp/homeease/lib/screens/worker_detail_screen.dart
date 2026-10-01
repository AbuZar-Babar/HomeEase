import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/worker_profile.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class WorkerDetailScreen extends StatefulWidget {
  const WorkerDetailScreen({
    super.key,
    required this.worker,
    required this.onBack,
    required this.onBookNow,
  });

  final WorkerProfile worker;
  final VoidCallback onBack;
  final VoidCallback onBookNow;

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  bool _isBookmarked = false;

  void _toggleBookmark() {
    HapticFeedback.lightImpact();
    setState(() => _isBookmarked = !_isBookmarked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked
              ? '${widget.worker.name} added to your saved workers.'
              : '${widget.worker.name} removed from saved workers.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDirectContactModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Direct Contact',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: HomeEaseTheme.brand,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Reach out directly to ${widget.worker.name} for schedule pre-checks or urgent inquiries in Abbottabad.',
                  style: const TextStyle(color: HomeEaseTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone_rounded, color: HomeEaseTheme.brand),
                  ),
                  title: const Text('Direct Phone Call', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('+92 312 9845120 • Abbottabad Mobile Network'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Simulating call to ${widget.worker.name} (+92 312 9845120)...'),
                      ),
                    );
                  },
                ),
                const Divider(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.statusVerified.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_rounded, color: HomeEaseTheme.statusVerified),
                  ),
                  title: const Text('WhatsApp Chat', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Fast response within 15 minutes'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening WhatsApp conversation with ${widget.worker.name}...'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _shareProfile() {
    HapticFeedback.lightImpact();
    Clipboard.setData(
      ClipboardData(
        text: 'Hire ${widget.worker.name} (${widget.worker.role}) in Abbottabad on HomeEase! Rating: ${widget.worker.rating}/5.0.',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Worker profile link copied to clipboard! Share anywhere.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final worker = widget.worker;

    // Derived mock reviews for authentic social proof
    final mockReviews = [
      {
        'author': 'Dr. Tariq Mahmood',
        'location': 'Jadoon Phase 2, Abbottabad',
        'rating': 5,
        'date': '2 days ago',
        'comment': 'Extremely punctual, thorough cleaning and highly trustworthy. Handled our kitchen deep clean with great care.',
      },
      {
        'author': 'Saima Noor',
        'location': 'Mandian, Abbottabad',
        'rating': 5,
        'date': '1 week ago',
        'comment': 'Very polite and skilled. Completed the entire laundry and ironing before scheduled time. Will hire again!',
      },
      {
        'author': 'Major (R) Kamran',
        'location': 'Supply Road, Abbottabad',
        'rating': 4,
        'date': '3 weeks ago',
        'comment': 'Reliable service provider. Verified CNIC gave our family peace of mind. Transparent rate.',
      },
    ];

    return AppScaffold(
      title: isUrdu ? 'ورکر پروفائل' : 'Worker Profile',
      subtitle: isUrdu
          ? 'تصدیق شدہ تفصیلات اور تجربہ'
          : 'Verified credentials and performance record',
      onBack: widget.onBack,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? HomeEaseTheme.brand : HomeEaseTheme.textSecondary,
            ),
            onPressed: _toggleBookmark,
            tooltip: 'Save worker',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: HomeEaseTheme.textSecondary),
            onPressed: _shareProfile,
            tooltip: 'Share profile',
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Worker Hero Header Card
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WorkerAvatar(size: 76, circular: true),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  worker.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: HomeEaseTheme.brand,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: HomeEaseTheme.statusVerified.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 12, color: HomeEaseTheme.statusVerified),
                                    SizedBox(width: 4),
                                    Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: HomeEaseTheme.statusVerified,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                LocalizationService.getCategoryIcon(worker.role),
                                size: 16,
                                color: LocalizationService.getCategoryColor(worker.role),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isUrdu ? LocalizationService.tr(worker.role.toLowerCase()) : worker.role,
                                style: const TextStyle(
                                  color: HomeEaseTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: HomeEaseTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                worker.location,
                                style: const TextStyle(color: HomeEaseTheme.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                '${worker.rating} (${worker.reviewsCount} reviews)',
                                style: const TextStyle(
                                  color: HomeEaseTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28, color: HomeEaseTheme.outline),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBadge(
                      label: isUrdu ? 'تجربہ' : 'Experience',
                      value: worker.experience,
                      icon: Icons.work_history_rounded,
                    ),
                    Container(height: 30, width: 1, color: HomeEaseTheme.outline),
                    _StatBadge(
                      label: isUrdu ? 'معاوضہ' : 'Hourly Rate',
                      value: worker.rate,
                      icon: Icons.payments_outlined,
                    ),
                    Container(height: 30, width: 1, color: HomeEaseTheme.outline),
                    _StatBadge(
                      label: isUrdu ? 'دستیابی' : 'Status',
                      value: worker.availability,
                      icon: Icons.event_available_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0),

          const SizedBox(height: 16),

          // 2. Trust & Verification Badge Bar
          HomeEaseCard(
            color: HomeEaseTheme.brand.withValues(alpha: 0.05),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.brand.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: HomeEaseTheme.brand, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NADRA CNIC & Police Verified',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: HomeEaseTheme.brand,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Background check cleared for Abbottabad residential safety.',
                        style: TextStyle(color: HomeEaseTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: HomeEaseTheme.statusVerified, size: 20),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. About & Bio Card
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('About Worker'),
                const SizedBox(height: 8),
                Text(
                  worker.description.isNotEmpty
                      ? worker.description
                      : 'Professional domestic worker operating across Abbottabad with verified service track record, punctuality, and client satisfaction.',
                  style: const TextStyle(
                    color: HomeEaseTheme.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (worker.skillTags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const SectionLabel('Skills & Specializations'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: worker.skillTags.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.cardDark.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: HomeEaseTheme.outline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 14, color: HomeEaseTheme.brand),
                            const SizedBox(width: 4),
                            Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: HomeEaseTheme.brand,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Transparent Rates Breakdown Card
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Pricing Structure'),
                const SizedBox(height: 10),
                _PricingRow(label: 'Standard Hourly Rate', price: worker.rate),
                _PricingRow(label: 'Full Day Service (8 Hours)', price: 'PKR 4,500 - 6,000'),
                _PricingRow(label: 'Deep Clean / Urgent Task', price: 'Standard + PKR 300', isLast: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. Authentic Client Reviews Section
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionLabel('Client Reviews'),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${worker.rating} / 5.0',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...mockReviews.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  final isLast = idx == mockReviews.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r['author'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.textPrimary),
                            ),
                            Text(
                              r['date'] as String,
                              style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              r['location'] as String,
                              style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                            ),
                            const Spacer(),
                            Row(
                              children: List.generate(
                                r['rating'] as int,
                                (_) => const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r['comment'] as String,
                          style: const TextStyle(fontSize: 12, color: HomeEaseTheme.text, height: 1.4),
                        ),
                        if (!isLast) const Divider(height: 18, color: HomeEaseTheme.outline),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 6. Sticky Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _showDirectContactModal,
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: Text(isUrdu ? 'رابطہ' : 'Contact'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HomeEaseTheme.brand,
                      side: const BorderSide(color: HomeEaseTheme.brand, width: 1.5),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: AnimatedScaleTap(
                    onTap: widget.onBookNow,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.brand,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: HomeEaseTheme.brand.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isUrdu ? 'بکنگ کا وقت چنیں' : 'Book Appointment',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
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
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: HomeEaseTheme.brand),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
        ),
      ],
    );
  }
}

class _PricingRow extends StatelessWidget {
  const _PricingRow({
    required this.label,
    required this.price,
    this.isLast = false,
  });

  final String label;
  final String price;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: HomeEaseTheme.textSecondary)),
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: HomeEaseTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

