import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({
    super.key,
    required this.worker,
    required this.onBack,
    required this.onSubmit,
  });

  final WorkerProfile worker;
  final VoidCallback onBack;
  final Function(Map<String, dynamic> bookingData) onSubmit;

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: HomeEaseTheme.brand,
              onPrimary: HomeEaseTheme.white,
              onSurface: HomeEaseTheme.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? const TimeOfDay(hour: 9, minute: 0) : const TimeOfDay(hour: 17, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: HomeEaseTheme.brand,
              onPrimary: HomeEaseTheme.white,
              onSurface: HomeEaseTheme.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = widget.worker;
    final dateText = _selectedDate == null
        ? 'Select date'
        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    final startTimeText = _selectedStartTime == null
        ? 'Start time'
        : _selectedStartTime!.format(context);
    final endTimeText = _selectedEndTime == null
        ? 'End time'
        : _selectedEndTime!.format(context);

    return AppScaffold(
      title: 'Request booking',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeEaseCard(
            color: HomeEaseTheme.cardDark,
            child: Row(
              children: [
                const WorkerAvatar(circular: true, size: 58),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: HomeEaseTheme.brand),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${worker.role}  |  ${worker.rate}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HomeEaseTheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                // Date picker trigger button
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F0E6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateText, style: const TextStyle(color: HomeEaseTheme.text)),
                        const Icon(Icons.calendar_today_rounded, color: HomeEaseTheme.brandSoft),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F0E6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(startTimeText, style: const TextStyle(color: HomeEaseTheme.text, fontSize: 13)),
                              const Icon(Icons.access_time_rounded, color: HomeEaseTheme.brandSoft, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F0E6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(endTimeText, style: const TextStyle(color: HomeEaseTheme.text, fontSize: 13)),
                              const Icon(Icons.access_time_rounded, color: HomeEaseTheme.brandSoft, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(hintText: 'Service Address (e.g. House 4, Lane 2, Mandian)'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Notes for worker (special instructions)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          HomeEaseButton(
            label: 'Submit Request',
            onPressed: () {
              if (_selectedDate == null ||
                  _selectedStartTime == null ||
                  _selectedEndTime == null ||
                  _addressController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select date, time slots, and fill in the address.')),
                );
                return;
              }

              final sMin = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
              final eMin = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
              if (sMin >= eMin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Start time must be strictly before end time.')),
                );
                return;
              }

              final durationHours = (eMin - sMin) / 60.0;
              final rateVal = worker.hourlyRate > 0
                  ? worker.hourlyRate
                  : (double.tryParse(worker.rate.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1500.0);
              final dynamicTotal = durationHours * rateVal;

              widget.onSubmit({
                'date': _selectedDate,
                'startTime': _selectedStartTime,
                'endTime': _selectedEndTime,
                'address': _addressController.text.trim(),
                'notes': _notesController.text.trim(),
                'agreedAmount': dynamicTotal,
              });
            },
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              if (_selectedStartTime != null && _selectedEndTime != null) {
                final sMin = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
                final eMin = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
                if (eMin > sMin) {
                  final duration = (eMin - sMin) / 60.0;
                  final rateVal = worker.hourlyRate > 0
                      ? worker.hourlyRate
                      : (double.tryParse(worker.rate.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1500.0);
                  final total = duration * rateVal;
                  return Text(
                    'Total estimate: PKR ${total.toInt()} (${duration.toStringAsFixed(1)} hrs @ PKR ${rateVal.toInt()}/hr)',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: HomeEaseTheme.brandSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }
              }
              return Text(
                'Total estimate: ${worker.rate}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: HomeEaseTheme.brandSoft,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
