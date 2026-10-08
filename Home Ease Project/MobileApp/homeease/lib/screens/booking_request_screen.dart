import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/booking_repository.dart';
import '../services/localization_service.dart';
import '../services/supabase_auth_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';
import '../widgets/animated_scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({
    super.key,
    required this.worker,
    required this.onBack,
    required this.onSubmit,
    this.roleBadge,
    this.onToggleLanguage,
    this.onOpenNotifications,
    this.unreadNotificationsCount,
    this.onLogout,
  });

  final WorkerProfile worker;
  final VoidCallback onBack;
  final ValueChanged<Booking> onSubmit;
  final String? roleBadge;
  final VoidCallback? onToggleLanguage;
  final VoidCallback? onOpenNotifications;
  final int? unreadNotificationsCount;
  final VoidCallback? onLogout;

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
              ? 'Worker already has an existing booking during this slot on ${BookingRepository.formatDate(_selectedDate!)}.'
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
              onSurface: HomeEaseTheme.textPrimary,
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
              onSurface: HomeEaseTheme.textPrimary,
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

    final isUrdu = LocalizationService.isUrdu;
    if (_selectedDate == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? 'براہ کرم تاریخ، اوقات اور پتہ درج کریں۔'
                : 'Please select date, time slots, and fill in the address.',
          ),
        ),
      );
      return;
    }

    final sMin = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final eMin = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
    if (sMin >= eMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? 'شروع کا وقت ختم ہونے سے پہلے ہونا چاہیے۔'
                : 'Start time must be strictly before end time.',
          ),
        ),
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

      final created = await BookingRepository().createBooking(newBooking);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? 'بکنگ کی درخواست کامیابی سے جمع ہو گئی۔'
                : 'Booking request submitted successfully.',
          ),
        ),
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
          backgroundColor: HomeEaseTheme.statusConflict,
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
    final isUrdu = LocalizationService.isUrdu;
    final worker = widget.worker;
    final dateText = _selectedDate == null
        ? (isUrdu ? 'سروس کی تاریخ منتخب کریں' : 'Select service date')
        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    final startTimeText = _selectedStartTime == null
        ? (isUrdu ? 'شروع کا وقت' : 'Start time')
        : _selectedStartTime!.format(context);
    final endTimeText = _selectedEndTime == null
        ? (isUrdu ? 'ختم ہونے کا وقت' : 'End time')
        : _selectedEndTime!.format(context);

    final dynamicAmount = _calculateDynamicAmount();
    final durationHours = (_selectedStartTime != null && _selectedEndTime != null)
        ? ((_selectedEndTime!.hour * 60 + _selectedEndTime!.minute) -
                (_selectedStartTime!.hour * 60 + _selectedStartTime!.minute)) /
            60.0
        : null;

    final hourlyRate = _getHourlyRate().toInt();

    return AppScaffold(
      title: isUrdu ? 'بکنگ کی درخواست' : 'Request Booking',
      subtitle: isUrdu
          ? 'ملاقات کی تفصیلات درج کریں اور وقت کا تصادم نہ ہو۔'
          : 'Specify appointment details and avoid overlaps.',
      onBack: widget.onBack,
      roleBadge: widget.roleBadge,
      onToggleLanguage: widget.onToggleLanguage,
      onOpenNotifications: widget.onOpenNotifications,
      unreadNotificationsCount: widget.unreadNotificationsCount,
      onLogout: widget.onLogout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker Profile Summary Card
          HomeEaseCard(
            color: HomeEaseTheme.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const WorkerAvatar(circular: true, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: HomeEaseTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            worker.role,
                            style: const TextStyle(fontSize: 12, color: HomeEaseTheme.brand, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isUrdu ? '• Rs. $hourlyRate فی گھنٹہ' : '• Rs. $hourlyRate/hr',
                            style: const TextStyle(
                              color: HomeEaseTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Service Schedule & Conflict Check
          HomeEaseCard(
            color: HomeEaseTheme.white,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(isUrdu ? 'شیڈول اور اوقات' : 'Schedule & Time Slots'),
                const SizedBox(height: 10),

                // Quick Date Pills
                Row(
                  children: [
                    Expanded(
                      child: AnimatedScaleTap(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedDate = DateTime.now());
                          _checkSlotAvailability();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: (_selectedDate != null &&
                                    _selectedDate!.day == DateTime.now().day &&
                                    _selectedDate!.month == DateTime.now().month)
                                ? HomeEaseTheme.brand
                                : HomeEaseTheme.mintSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isUrdu ? 'آج' : 'Today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: (_selectedDate != null &&
                                      _selectedDate!.day == DateTime.now().day &&
                                      _selectedDate!.month == DateTime.now().month)
                                  ? Colors.white
                                  : HomeEaseTheme.brand,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedScaleTap(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedDate = DateTime.now().add(const Duration(days: 1)));
                          _checkSlotAvailability();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: (_selectedDate != null &&
                                    _selectedDate!.day == DateTime.now().add(const Duration(days: 1)).day &&
                                    _selectedDate!.month == DateTime.now().add(const Duration(days: 1)).month)
                                ? HomeEaseTheme.brand
                                : HomeEaseTheme.mintSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isUrdu ? 'کل' : 'Tomorrow',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: (_selectedDate != null &&
                                      _selectedDate!.day == DateTime.now().add(const Duration(days: 1)).day &&
                                      _selectedDate!.month == DateTime.now().add(const Duration(days: 1)).month)
                                  ? Colors.white
                                  : HomeEaseTheme.brand,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedScaleTap(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: HomeEaseTheme.outline),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_month_outlined, size: 14, color: HomeEaseTheme.brand),
                              const SizedBox(width: 4),
                              Text(
                                isUrdu ? 'دیگر تاریخ' : 'Custom',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: HomeEaseTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date picker display container
                AnimatedScaleTap(
                  onTap: _pickDate,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HomeEaseTheme.outline),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateText,
                          style: TextStyle(
                            color: _selectedDate == null ? HomeEaseTheme.muted : HomeEaseTheme.textPrimary,
                            fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded, color: HomeEaseTheme.brand, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Preset Slot Quick Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: Text(isUrdu ? 'صبح (9-12)' : 'Morning (9 AM - 12 PM)'),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HomeEaseTheme.brand),
                        backgroundColor: HomeEaseTheme.mintSoft,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onPressed: () {
                          setState(() {
                            _selectedStartTime = const TimeOfDay(hour: 9, minute: 0);
                            _selectedEndTime = const TimeOfDay(hour: 12, minute: 0);
                          });
                          _checkSlotAvailability();
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: Text(isUrdu ? 'دوپہر (2-5)' : 'Afternoon (2 PM - 5 PM)'),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HomeEaseTheme.brand),
                        backgroundColor: HomeEaseTheme.mintSoft,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onPressed: () {
                          setState(() {
                            _selectedStartTime = const TimeOfDay(hour: 14, minute: 0);
                            _selectedEndTime = const TimeOfDay(hour: 17, minute: 0);
                          });
                          _checkSlotAvailability();
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: Text(isUrdu ? 'مکمل دن (9-5)' : 'Full Day (9 AM - 5 PM)'),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HomeEaseTheme.brand),
                        backgroundColor: HomeEaseTheme.mintSoft,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onPressed: () {
                          setState(() {
                            _selectedStartTime = const TimeOfDay(hour: 9, minute: 0);
                            _selectedEndTime = const TimeOfDay(hour: 17, minute: 0);
                          });
                          _checkSlotAvailability();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: AnimatedScaleTap(
                        onTap: () => _pickTime(true),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: HomeEaseTheme.outline),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                startTimeText,
                                style: TextStyle(
                                  color: _selectedStartTime == null ? HomeEaseTheme.muted : HomeEaseTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: _selectedStartTime == null ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                              const Icon(Icons.access_time_rounded, color: HomeEaseTheme.brand, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedScaleTap(
                        onTap: () => _pickTime(false),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: HomeEaseTheme.outline),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                endTimeText,
                                style: TextStyle(
                                  color: _selectedEndTime == null ? HomeEaseTheme.muted : HomeEaseTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: _selectedEndTime == null ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                              const Icon(Icons.access_time_rounded, color: HomeEaseTheme.brand, size: 18),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: HomeEaseTheme.brand),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isUrdu ? 'دستیابی چیک کی جا رہی ہے...' : 'Checking slot availability...',
                          style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 150.ms)
                else if (_hasConflict == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2), // Red 50
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: HomeEaseTheme.statusConflict.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: HomeEaseTheme.statusConflict, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _conflictMessage ??
                                (isUrdu
                                    ? 'یہ وقت پہلے سے کسی بکنگ کے ساتھ تصادم کر رہا ہے۔'
                                    : 'Time slot overlaps with an existing booking.'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: HomeEaseTheme.statusConflict,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 200.ms).shake(duration: 300.ms, hz: 4)
                else if (_hasConflict == false && durationHours != null && durationHours > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5), // Emerald 50
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: HomeEaseTheme.statusVerified.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: HomeEaseTheme.statusVerified, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isUrdu
                                ? 'وقت دستیاب ہے: ${durationHours.toStringAsFixed(1)} گھنٹے ($startTimeText - $endTimeText)'
                                : 'Slot available: ${durationHours.toStringAsFixed(1)} hrs ($startTimeText - $endTimeText)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: HomeEaseTheme.statusVerified,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutBack),

                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: isUrdu
                        ? 'سروس کا پتہ (مثلاً مکان 4، گلی 2، منڈیان، ایبٹ آباد)'
                        : 'Service Address (e.g. House 4, Lane 2, Mandian, Abbottabad)',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: HomeEaseTheme.brand),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: isUrdu
                        ? 'ورکر کے لیے ہدایات یا رسائی کی تفصیلات'
                        : 'Notes for worker (special instructions or access details)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Total Estimate Callout
          if (dynamicAmount != null && durationHours != null && durationHours > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HomeEaseTheme.accentLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HomeEaseTheme.brand.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrdu ? 'کل متوقع رقم' : 'Total Estimated Amount',
                        style: const TextStyle(fontSize: 11, color: HomeEaseTheme.brand, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'PKR ${dynamicAmount.toInt()}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: HomeEaseTheme.brand),
                      ),
                    ],
                  ),
                  Text(
                    isUrdu
                        ? '${durationHours.toStringAsFixed(1)} گھنٹے @ Rs. $hourlyRate/hr'
                        : '${durationHours.toStringAsFixed(1)} hrs @ Rs. $hourlyRate/hr',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: HomeEaseTheme.brand),
                  ),
                ],
              ),
            ),

          // Submit CTA
          HomeEaseButton(
            label: _isSubmitting
                ? (isUrdu ? 'تصدیق ہو رہی ہے...' : 'Validating slot...')
                : (isUrdu ? 'بکنگ کی درخواست جمع کروائیں' : 'Submit Booking Request'),
            icon: Icons.check_circle_rounded,
            onPressed: () {
              if (!_isSubmitting) {
                _submitBooking();
              }
            },
          ),
        ],
      ),
    );
  }
}
