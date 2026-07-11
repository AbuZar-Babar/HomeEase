import 'package:flutter/material.dart';

import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class WorkerAvailabilityScreen extends StatefulWidget {
  const WorkerAvailabilityScreen({
    super.key,
    required this.initialStatus,
    required this.initialSlots,
    required this.onBack,
    required this.onSave,
  });

  final String initialStatus;
  final List<String> initialSlots; // e.g. ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
  final VoidCallback onBack;
  final Function(String status, List<String> slots) onSave;

  @override
  State<WorkerAvailabilityScreen> createState() => _WorkerAvailabilityScreenState();
}

class _WorkerAvailabilityScreenState extends State<WorkerAvailabilityScreen> {
  late String _currentStatus;
  late Set<String> _selectedSlots;

  final List<String> _daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _selectedSlots = Set.from(widget.initialSlots);
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedSlots.contains(day)) {
        _selectedSlots.remove(day);
      } else {
        _selectedSlots.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Availability manager',
      subtitle: 'Set your status and active work days.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('General Status'),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  title: const Text('Available Today', style: TextStyle(color: HomeEaseTheme.text)),
                  value: 'Available today',
                  groupValue: _currentStatus,
                  activeColor: HomeEaseTheme.brand,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _currentStatus = val);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Busy / Booked out', style: TextStyle(color: HomeEaseTheme.text)),
                  value: 'Busy',
                  groupValue: _currentStatus,
                  activeColor: HomeEaseTheme.brand,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _currentStatus = val);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Away / On Leave', style: TextStyle(color: HomeEaseTheme.text)),
                  value: 'Away',
                  groupValue: _currentStatus,
                  activeColor: HomeEaseTheme.brand,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _currentStatus = val);
                    }
                  },
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
                const SectionLabel('Weekly Work Days'),
                const SizedBox(height: 8),
                Text(
                  'Select the days when you are open to receiving booking requests:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _daysOfWeek.map((day) {
                    final isSelected = _selectedSlots.contains(day);
                    return ChoiceChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (_) => _toggleDay(day),
                      labelStyle: TextStyle(
                        color: isSelected ? HomeEaseTheme.white : HomeEaseTheme.brand,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: HomeEaseTheme.brand,
                      backgroundColor: HomeEaseTheme.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                HomeEaseButton(
                  label: 'Save Availability Settings',
                  onPressed: () {
                    widget.onSave(_currentStatus, _selectedSlots.toList());
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
