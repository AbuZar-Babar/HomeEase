import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../theme/home_ease_theme.dart';
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
  String _selectedCategory = 'Payment discrepancy';
  String? _evidenceDocumentPath;

  final List<String> _categories = [
    'Payment discrepancy',
    'Service incomplete',
    'Behavior issues',
    'Scheduling conflict',
    'Other',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _attachEvidence() {
    HapticFeedback.lightImpact();
    setState(() {
      _evidenceDocumentPath = 'evidence_${widget.booking.id.hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evidence photo attached successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Raise dispute',
      subtitle: 'Specify the issue details for admin arbitration.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Dispute Category'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  dropdownColor: HomeEaseTheme.surface,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: const TextStyle(color: HomeEaseTheme.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 18),
                const SectionLabel('Explain the issue'),
                const SizedBox(height: 10),
                TextField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Please detail exactly what occurred. Provide as much context as possible.',
                  ),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Upload Evidence (Receipt/Photo)'),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _attachEvidence,
                  child: Container(
                    height: 90,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _evidenceDocumentPath != null
                          ? HomeEaseTheme.accentLight.withValues(alpha: 0.3)
                          : HomeEaseTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _evidenceDocumentPath != null
                            ? HomeEaseTheme.brand
                            : HomeEaseTheme.outline,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _evidenceDocumentPath != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: HomeEaseTheme.statusVerified),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Evidence attached: $_evidenceDocumentPath',
                                  style: const TextStyle(
                                    color: HomeEaseTheme.brand,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: HomeEaseTheme.muted),
                                onPressed: () {
                                  setState(() {
                                    _evidenceDocumentPath = null;
                                  });
                                },
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, color: HomeEaseTheme.brand, size: 28),
                              SizedBox(height: 4),
                              Text('Tap to attach screenshot/photo evidence', style: TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                HomeEaseButton(
                  label: 'Submit Dispute',
                  onPressed: () {
                    if (_descController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please explain the issue details.')),
                      );
                      return;
                    }
                    widget.onSubmit(
                      _selectedCategory,
                      _descController.text,
                      _evidenceDocumentPath ?? 'evidence_${widget.booking.id}.jpg',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
