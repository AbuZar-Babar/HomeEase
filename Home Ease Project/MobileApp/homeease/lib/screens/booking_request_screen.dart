import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../services/booking_repository.dart';
import '../services/supabase_auth_service.dart';
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
  final ValueChanged<Booking> onSubmit;

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  bool _isSubmitting = false;
  bool _isCheckingConflict = false;
  bool? _hasConflict;
  String? _conflictMessage;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _getHourlyRate() {
    if (widget.worker.hourlyRate > 0) return widget.worker.hourlyRate;
    final digitsOnly = widget.worker.rate.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digitsOnly) ?? 1500.0;
  }

  double? _calculateDynamicAmount() {
    if (_selectedStartTime == null || _selectedEndTime == null) return null;
    final sMin = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final eMin = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
    if (eMin <= sMin) return null;
    return BookingConflictEngine.calculateTotalAmount(
      start: _selectedStartTime!,
      end: _selectedEndTime!,
      hourlyRate: _getHourlyRate(),
    );
  }

  Future<void> _checkSlotAvailability() async {
    if (_selectedDate == null || _selectedStartTime == null || _selectedEndTime == null) return;
    final sMin = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final eMin = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
    if (sMin >= eMin) {
      setState(() {
        _hasConflict = true;
        _conflictMessage = 'Start time must be strictly before end time.';
      });
      return;
    }

    setState(() => _isCheckingConflict = true);
    try {
      final conflict = await BookingRepository().hasConflict(
        workerId: widget.worker.id,
        date: _selectedDate!,
        startTime: _selectedStartTime!,
        endTime: _selectedEndTime!,
      );
      if (mounted) {
        setState(() {
          _hasConflict = conflict;
          _conflictMessage = conflict
              ? 'Worker already has a booking during this slot on ${BookingRepository.formatDate(_selectedDate!)}.'
              : null;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCheckingConflict = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
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
      _checkSlotAvailability();
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_selectedStartTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_selectedEndTime ?? const TimeOfDay(hour: 12, minute: 0)),
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
      _checkSlotAvailability();
    }
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting) return;

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

    setState(() => _isSubmitting = true);

    try {
      final rateVal = _getHourlyRate();
      final dynamicTotal = BookingConflictEngine.calculateTotalAmount(
        start: _selectedStartTime!,
        end: _selectedEndTime!,
        hourlyRate: rateVal,
      );

      final auth = SupabaseAuthService();
      final householdId = auth.currentUser?.id ??
          auth.client?.auth.currentUser?.id ??
          '00000000-0000-0000-0000-000000000001';

      final newBooking = Booking(
        id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
        householdId: householdId,
        workerId: widget.worker.id,
        serviceCategoryId: widget.worker.role,
        bookingDate: _selectedDate!,
        startTime: _selectedStartTime!,
        endTime: _selectedEndTime!,
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        agreedAmount: dynamicTotal,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      // Validate interval conflict ($S_req < E_exist AND E_req > S_exist) & create booking
      final created = await BookingRepository().createBooking(newBooking);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request submitted successfully.')),
      );

      widget.onSubmit(created);
    } on BookingConflictException catch (e) {
      if (!mounted) return;
      setState(() {
        _hasConflict = true;
        _conflictMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(e.message)),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

    final dynamicAmount = _calculateDynamicAmount();
    final durationHours = (_selectedStartTime != null && _selectedEndTime != null)
        ? ((_selectedEndTime!.hour * 60 + _selectedEndTime!.minute) -
                (_selectedStartTime!.hour * 60 + _selectedStartTime!.minute)) /
            60.0
        : null;

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
                        '${worker.role}  |  PKR ${_getHourlyRate().toInt()}/hr',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HomeEaseTheme.text,
                          fontWeight: FontWeight.w600,
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

                // Real-time conflict feedback banner
                if (_isCheckingConflict)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: HomeEaseTheme.brand),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Checking slot availability...',
                          style: TextStyle(fontSize: 12, color: HomeEaseTheme.text),
                        ),
                      ],
                    ),
                  )
                else if (_hasConflict == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _conflictMessage ?? 'Time slot overlaps with an existing booking.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_hasConflict == false && durationHours != null && durationHours > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Slot available: ${durationHours.toStringAsFixed(1)} hrs ($startTimeText - $endTimeText)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Service Address (e.g. House 4, Lane 2, Mandian, Abbottabad)',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Notes for worker (special instructions)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          HomeEaseButton(
            label: _isSubmitting ? 'Validating slot...' : 'Submit Request',
            onPressed: () {
              if (!_isSubmitting) {
                _submitBooking();
              }
            },
          ),
          const SizedBox(height: 12),
          if (dynamicAmount != null && durationHours != null && durationHours > 0)
            Text(
              'Total estimate: PKR ${dynamicAmount.toInt()} (${durationHours.toStringAsFixed(1)} hrs @ PKR ${_getHourlyRate().toInt()}/hr)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: HomeEaseTheme.brandSoft,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text(
              'Rate: PKR ${_getHourlyRate().toInt()}/hr',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: HomeEaseTheme.brandSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
