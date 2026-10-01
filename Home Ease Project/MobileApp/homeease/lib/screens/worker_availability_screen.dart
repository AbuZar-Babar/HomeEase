import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class WorkerAvailabilityScreen extends StatefulWidget {
  const WorkerAvailabilityScreen({
    super.key,
    required this.initialStatus,
    required this.initialSlots,
    this.verificationStatus = 'Verified',
    this.onBack,
    required this.onSave,
    this.bottomNavigationBar,
    this.roleBadge,
    this.onToggleLanguage,
    this.onOpenNotifications,
    this.unreadNotificationsCount,
    this.onLogout,
  });

  final String initialStatus;
  final List<String> initialSlots; // e.g. ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
  final String verificationStatus;
  final VoidCallback? onBack;
  final Function(String status, List<String> slots) onSave;
  final Widget? bottomNavigationBar;
  final String? roleBadge;
  final VoidCallback? onToggleLanguage;
  final VoidCallback? onOpenNotifications;
  final int? unreadNotificationsCount;
  final VoidCallback? onLogout;

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

  final Map<String, String> _urduDays = {
    'Mon': 'پیر',
    'Tue': 'منگل',
    'Wed': 'بدھ',
    'Thu': 'جمعرات',
    'Fri': 'جمعہ',
    'Sat': 'ہفتہ',
    'Sun': 'اتوار',
  };

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
    final isUrdu = LocalizationService.isUrdu;

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AppScaffold(
        title: isUrdu ? 'دستیابی کا انتظام' : 'Availability manager',
        subtitle: isUrdu ? 'اپنی موجودگی اور کام کے دن منتخب کریں' : 'Set your status and active work days.',
        onBack: widget.onBack,
        roleBadge: widget.roleBadge,
        onToggleLanguage: widget.onToggleLanguage,
        onOpenNotifications: widget.onOpenNotifications,
        unreadNotificationsCount: widget.unreadNotificationsCount,
        onLogout: widget.onLogout,
        bottomNavigationBar: widget.bottomNavigationBar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verification Status Card
            if (widget.verificationStatus == 'Verified')
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: HomeEaseCard(
                  color: const Color(0xFFECFDF5), // Emerald 50
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: HomeEaseTheme.statusVerified, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUrdu ? 'تصدیق شدہ ورکر بیج' : 'Verified Profile Badge',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: HomeEaseTheme.statusVerified, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isUrdu
                                  ? 'آپ کی پروفائل مکمل تصدیق شدہ ہے۔ آپ گھریلو تلاش کے نتائج میں نظر آ رہے ہیں۔'
                                  : 'Your profile is verified. You are active and visible in search.',
                              style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
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
                  color: const Color(0xFFFFFBEB), // Amber 50
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: HomeEaseTheme.statusPending, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.verificationStatus == 'PendingVerification'
                                  ? (isUrdu ? 'تصدیق کا عمل جاری ہے' : 'Verification In-Review')
                                  : (isUrdu ? 'پروفائل غیر تصدیق شدہ' : 'Profile Unverified'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: HomeEaseTheme.statusPending, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.verificationStatus == 'PendingVerification'
                                  ? (isUrdu
                                      ? 'ایڈمن آپ کی تفصیلات کا جائزہ لے رہا ہے۔'
                                      : 'Admin is reviewing your details.')
                                  : (isUrdu
                                      ? 'براہ کرم تصدیق کے لیے شناختی کارڈ جمع کرائیں۔'
                                      : 'Please submit documents for verification.'),
                              style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // General Status Card
            HomeEaseCard(
              color: HomeEaseTheme.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(isUrdu ? 'عمومی حالت' : 'General Status'),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: Text(isUrdu ? 'آج دستیاب ہے' : 'Available Today', style: const TextStyle(color: HomeEaseTheme.text)),
                    value: 'Available today',
                    groupValue: _currentStatus,
                    activeColor: HomeEaseTheme.brand,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.lightImpact();
                        setState(() => _currentStatus = val);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(isUrdu ? 'مصروف / بک شدہ' : 'Busy / Booked out', style: const TextStyle(color: HomeEaseTheme.text)),
                    value: 'Busy',
                    groupValue: _currentStatus,
                    activeColor: HomeEaseTheme.brand,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.lightImpact();
                        setState(() => _currentStatus = val);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(isUrdu ? 'چھٹی پر / غیر حاضر' : 'Away / On Leave', style: const TextStyle(color: HomeEaseTheme.text)),
                    value: 'Away',
                    groupValue: _currentStatus,
                    activeColor: HomeEaseTheme.brand,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.lightImpact();
                        setState(() => _currentStatus = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weekly Work Days Card
            HomeEaseCard(
              color: HomeEaseTheme.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(isUrdu ? 'ہفتہ وار کام کے دن' : 'Weekly Work Days'),
                  const SizedBox(height: 8),
                  Text(
                    isUrdu
                        ? 'وہ دن منتخب کریں جب آپ بکنگ کی درخواستیں وصول کرنے کے لیے تیار ہوں:'
                        : 'Select the days when you are open to receiving booking requests:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _daysOfWeek.map((day) {
                      final isSelected = _selectedSlots.contains(day);
                      final displayLabel = isUrdu ? (_urduDays[day] ?? day) : day;
                      return ChoiceChip(
                        label: Text(displayLabel),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.lightImpact();
                          _toggleDay(day);
                        },
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
                    label: isUrdu ? 'دستیابی کی ترتیبات محفوظ کریں' : 'Save Availability Settings',
                    onPressed: () {
                      widget.onSave(_currentStatus, _selectedSlots.toList());
                    },
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
