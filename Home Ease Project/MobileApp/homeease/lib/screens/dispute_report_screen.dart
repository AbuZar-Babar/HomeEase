import 'package:flutter/material.dart';

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
  String? _simulatedProofPath;

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

  void _simulateProofSelect() {
    setState(() {
      _simulatedProofPath = 'assets/mock/proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulated: Proof image selected.')),
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
                  value: _selectedCategory,
                  dropdownColor: HomeEaseTheme.surface,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: const TextStyle(color: HomeEaseTheme.text)),
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
                  onTap: _simulateProofSelect,
                  child: Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: HomeEaseTheme.card,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _simulatedProofPath != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Evidence Photo Selected',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, color: HomeEaseTheme.brand, size: 28),
                              SizedBox(height: 4),
                              Text('Select screenshot/photo proof', style: TextStyle(fontSize: 12)),
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
                      _simulatedProofPath ?? 'assets/mock/default_proof.jpg',
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
