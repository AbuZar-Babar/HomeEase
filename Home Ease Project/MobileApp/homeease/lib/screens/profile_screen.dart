import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/localization_service.dart';
import '../services/supabase_auth_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.userRole,
    required this.onLogout,
    required this.onLanguageChanged,
    this.totalBookings = 0,
    this.totalPostedGigs = 0,
    this.bottomNavigationBar,
    this.onOpenNotifications,
    this.unreadNotificationsCount,
  });

  final String userRole;
  final VoidCallback onLogout;
  final VoidCallback onLanguageChanged;
  final int totalBookings;
  final int totalPostedGigs;
  final Widget? bottomNavigationBar;
  final VoidCallback? onOpenNotifications;
  final int? unreadNotificationsCount;

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final currentUser = SupabaseAuthService().currentUser;
    final userName = currentUser?.fullName ?? (isUrdu ? 'صارف' : 'Household Employer');
    final userEmail = currentUser?.email ?? 'household@homeease.com';
    final userPhone = currentUser?.phone ?? '+92 312 9876543';

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AppScaffold(
        title: isUrdu ? 'میری پروفائل' : 'My Profile',
        subtitle: isUrdu
          ? 'اکاؤنٹ کی تفصیلات اور سیٹنگز'
          : 'Account settings, addresses, and platform preferences',
        roleBadge: userRole,
        onToggleLanguage: () {
          LocalizationService.toggleLanguage();
          onLanguageChanged();
        },
        onOpenNotifications: onOpenNotifications,
        unreadNotificationsCount: unreadNotificationsCount,
        onLogout: onLogout,
        bottomNavigationBar: bottomNavigationBar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            HomeEaseCard(
              color: HomeEaseTheme.white,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.brand,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'H',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: HomeEaseTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: HomeEaseTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.accentLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$userRole • Abbottabad',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: HomeEaseTheme.brand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: HomeEaseCard(
                    color: HomeEaseTheme.card,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.assignment_turned_in_rounded, color: HomeEaseTheme.brand, size: 22),
                        const SizedBox(height: 8),
                        Text(
                          '$totalBookings',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: HomeEaseTheme.textPrimary,
                          ),
                        ),
                        Text(
                          isUrdu ? 'کل بکنگز' : 'Total Bookings',
                          style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HomeEaseCard(
                    color: HomeEaseTheme.card,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.post_add_rounded, color: HomeEaseTheme.brand, size: 22),
                        const SizedBox(height: 8),
                        Text(
                          '$totalPostedGigs',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: HomeEaseTheme.textPrimary,
                          ),
                        ),
                        Text(
                          isUrdu ? 'پوسٹ کردہ جابز' : 'Posted Gigs',
                          style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Personal & Contact Info Card
            HomeEaseCard(
              color: HomeEaseTheme.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(isUrdu ? 'رابطہ اور پتہ' : 'Contact & Address'),
                  const SizedBox(height: 12),
                  _ProfileDetailItem(
                    icon: Icons.phone_outlined,
                    label: isUrdu ? 'فون نمبر' : 'Phone Number',
                    value: userPhone,
                  ),
                  const Divider(height: 20, color: HomeEaseTheme.outline),
                  _ProfileDetailItem(
                    icon: Icons.location_on_outlined,
                    label: isUrdu ? 'بنیادی پتہ' : 'Primary Locality',
                    value: 'Mandian, Abbottabad, Khyber Pakhtunkhwa',
                  ),
                  const Divider(height: 20, color: HomeEaseTheme.outline),
                  _ProfileDetailItem(
                    icon: Icons.shield_outlined,
                    label: isUrdu ? 'حفاظتی تصدیق' : 'Security Status',
                    value: isUrdu ? 'شناختی کارڈ تصدیق شدہ' : 'CNIC Verified • 2FA Active',
                    valueColor: HomeEaseTheme.statusVerified,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preferences Card
            HomeEaseCard(
              color: HomeEaseTheme.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(isUrdu ? 'ترجیحات' : 'Preferences'),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      LocalizationService.toggleLanguage();
                      onLanguageChanged();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: HomeEaseTheme.card,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.language_rounded, color: HomeEaseTheme.brand, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isUrdu ? 'ایپ کی زبان' : 'App Language',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  isUrdu ? 'اردو (فعال)' : 'English (Active)',
                                  style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: HomeEaseTheme.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isUrdu ? 'English میں بدلیں' : 'Switch to اردو',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: HomeEaseTheme.brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            HomeEaseButton(
              label: isUrdu ? 'لاگ آؤٹ کریں' : 'Log Out',
              isPrimary: false,
              icon: Icons.logout_rounded,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isUrdu ? 'لاگ آؤٹ کی تصدیق' : 'Confirm Logout'),
                    content: Text(
                      isUrdu
                          ? 'کیا آپ واقعی اپنے اکاؤنٹ سے لاگ آؤٹ کرنا چاہتے ہیں؟'
                          : 'Are you sure you want to sign out of HomeEase?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: HomeEaseTheme.statusConflict,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          onLogout();
                        },
                        child: Text(isUrdu ? 'لاگ آؤٹ' : 'Log Out'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailItem extends StatelessWidget {
  const _ProfileDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: HomeEaseTheme.brand),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: HomeEaseTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? HomeEaseTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
