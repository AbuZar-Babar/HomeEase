import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/worker_profile.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class DisputeReportScreen extends StatefulWidget {
  const DisputeReportScreen({
    super.key,
    required this.booking,
    required this.onBack,
    required this.onSubmit,
  });

  final Booking booking;
  final VoidCallback onBack;
  final Function(String category, String desc, String proof) onSubmit;

  @override
  State<DisputeReportScreen> createState() => _DisputeReportScreenState();
}

class _DisputeReportScreenState extends State<DisputeReportScreen> {
  final TextEditingController _descController = TextEditingController();
  int _selectedCategoryIndex = 0;
  String? _evidenceDocumentPath;

  final List<Map<String, dynamic>> _disputeCategories = [
    {
      'title': 'Payment Discrepancy',
      'subtitle': 'Demanded additional cash or rate disagreement',
      'icon': Icons.payments_rounded,
      'color': HomeEaseTheme.brand,
    },
    {
      'title': 'Incomplete / Substandard Work',
      'subtitle': 'Agreed tasks were skipped or left incomplete',
      'icon': Icons.cleaning_services_rounded,
      'color': HomeEaseTheme.statusPending,
    },
    {
      'title': 'Unprofessional Behavior / Late',
      'subtitle': 'Significant unannounced delay or misconduct',
      'icon': Icons.person_off_rounded,
      'color': Colors.deepOrange,
    },
    {
      'title': 'Property Damage / Urgent Safety',
      'subtitle': 'High priority immediate admin intervention',
      'icon': Icons.shield_rounded,
      'color': HomeEaseTheme.statusConflict,
    },
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _attachEvidence() {
    HapticFeedback.lightImpact();
    setState(() {
      _evidenceDocumentPath =
          'evidence_dispute_${widget.booking.id.hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evidence photo/receipt attached successfully.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showUrgentHelplineModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: HomeEaseTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '24/7 Safety & Mediation Helpline',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: HomeEaseTheme.statusConflict),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Abbottabad Trust & Safety Team responds within 15 minutes for safety incidents.',
                  style: TextStyle(color: HomeEaseTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.statusConflict.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone_in_talk_rounded, color: HomeEaseTheme.statusConflict),
                  ),
                  title: const Text('Direct Safety Emergency Line', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('0992-111-4663 (Abbottabad Control Center)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dialing Abbottabad Safety Center: 0992-111-4663...')),
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
                  title: const Text('WhatsApp Dispute Mediation Desk', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Instant live agent response: +92 300 1234567'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening WhatsApp Mediation Support Desk...')),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final selectedCategory = _disputeCategories[_selectedCategoryIndex]['title'] as String;

    return AppScaffold(
      title: isUrdu ? 'تنازعہ درج کریں' : 'Dispute Resolution',
      subtitle: isUrdu
          ? 'ایبٹ آباد کسٹمر سپورٹ فوری جائزہ لے گی'
          : 'HomeEase Abbottabad mediation & admin arbitration',
      onBack: widget.onBack,
      trailing: IconButton(
        icon: const Icon(Icons.support_agent_rounded, color: HomeEaseTheme.brand),
        onPressed: _showUrgentHelplineModal,
        tooltip: 'Urgent Helpline',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Trust & SLA Banner
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
                  child: const Icon(Icons.verified_user_rounded, color: HomeEaseTheme.brand, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2-Hour Resolution Guarantee',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: HomeEaseTheme.brand,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All reported disputes are frozen and audited under the HomeEase Community Agreement.',
                        style: TextStyle(color: HomeEaseTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms),

          const SizedBox(height: 16),

          // 2. Selectable Dispute Categories
          const SectionLabel('Select Dispute Reason'),
          const SizedBox(height: 10),
          ..._disputeCategories.asMap().entries.map((entry) {
            final idx = entry.key;
            final cat = entry.value;
            final isSelected = _selectedCategoryIndex == idx;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedScaleTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategoryIndex = idx);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? HomeEaseTheme.white : HomeEaseTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: HomeEaseTheme.brand.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (cat['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cat['subtitle'] as String,
                              style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // 3. Detailed Incident Description
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Explain the issue in detail'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Please describe what happened, times, and any monetary differences. This is shared with the arbitration officer.',
                  ),
                ),
                const SizedBox(height: 16),
                const SectionLabel('Attach Photo / Receipt Proof'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _attachEvidence,
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _evidenceDocumentPath != null
                          ? HomeEaseTheme.brand.withValues(alpha: 0.05)
                          : HomeEaseTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _evidenceDocumentPath != null ? HomeEaseTheme.brand : HomeEaseTheme.outline,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _evidenceDocumentPath != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: HomeEaseTheme.statusVerified, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Photo attached: $_evidenceDocumentPath',
                                  style: const TextStyle(
                                    color: HomeEaseTheme.brand,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: HomeEaseTheme.textSecondary),
                                tooltip: 'Remove photo',
                                onPressed: () {
                                  setState(() => _evidenceDocumentPath = null);
                                },
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: HomeEaseTheme.brand, size: 24),
                              SizedBox(height: 4),
                              Text(
                                'Tap to take photo or attach from gallery',
                                style: TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                HomeEaseButton(
                  label: isUrdu ? 'تنازعہ جمع کروائیں' : 'Submit for Arbitration',
                  onPressed: () {
                    if (_descController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an explanation of the issue.')),
                      );
                      return;
                    }
                    widget.onSubmit(
                      selectedCategory,
                      _descController.text.trim(),
                      _evidenceDocumentPath ?? 'evidence_${widget.booking.id}.jpg',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Quick Emergency Mediation Card
          HomeEaseCard(
            color: HomeEaseTheme.surface,
            child: Row(
              children: [
                const Icon(Icons.phone_forwarded_rounded, color: HomeEaseTheme.brand, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Urgent Mediation Helpline',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.textPrimary),
                      ),
                      Text(
                        'Speak with a live supervisor immediately in Abbottabad.',
                        style: TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showUrgentHelplineModal,
                  child: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.bold, color: HomeEaseTheme.brand)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

