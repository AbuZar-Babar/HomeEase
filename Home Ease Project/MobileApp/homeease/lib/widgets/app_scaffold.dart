import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.onBack,
    this.onLogout,
    this.trailing,
    this.leading,
    this.roleBadge,
    this.unreadNotificationsCount,
    this.onOpenNotifications,
    this.onToggleLanguage,
    this.bottomNavigationBar,
    this.padding,
    this.child = const SizedBox.shrink(),
  });

  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  final Widget? trailing;
  final Widget? leading;
  final String? roleBadge;
  final int? unreadNotificationsCount;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onToggleLanguage;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTopBar = (onBack == null && leading == null) &&
        (roleBadge != null || onOpenNotifications != null || onToggleLanguage != null);

    return Scaffold(
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: padding ?? const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 540 ? 480 : constraints.maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: leading!,
                      )
                    else if (onBack != null)
                      _BackHeader(
                        onBack: onBack!,
                        trailing: trailing,
                        onLogout: onLogout,
                      )
                    else if (hasTopBar)
                      _TopAppBar(
                        roleBadge: roleBadge,
                        unreadCount: unreadNotificationsCount ?? 0,
                        onOpenNotifications: onOpenNotifications,
                        onToggleLanguage: onToggleLanguage,
                        trailing: trailing,
                        onLogout: onLogout,
                      ),

                    if (title != null) ...[
                      SizedBox(height: (onBack == null && leading == null && !hasTopBar) ? 0 : 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title!,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: HomeEaseTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (onBack == null && !hasTopBar) ...[
                            ?trailing,
                            if (onLogout != null)
                              IconButton(
                                icon: const Icon(Icons.logout_rounded, color: HomeEaseTheme.brand),
                                onPressed: onLogout,
                              ),
                          ],
                        ],
                      ),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: HomeEaseTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({
    this.roleBadge,
    this.unreadCount = 0,
    this.onOpenNotifications,
    this.onToggleLanguage,
    this.trailing,
    this.onLogout,
  });

  final String? roleBadge;
  final int unreadCount;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onToggleLanguage;
  final Widget? trailing;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Brand Logo & Role Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: HomeEaseTheme.brand,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: HomeEaseTheme.brand.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'H',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'HomeEase',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: HomeEaseTheme.brand,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (roleBadge != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.accentLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleBadge!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: HomeEaseTheme.brand,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Spacer(),

          // Compact Language Switcher
          if (onToggleLanguage != null)
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggleLanguage!();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: HomeEaseTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HomeEaseTheme.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate_rounded, size: 15, color: HomeEaseTheme.brand),
                    const SizedBox(width: 4),
                    Text(
                      LocalizationService.isUrdu ? 'English' : 'اردو',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: HomeEaseTheme.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Notification Bell with Unread Badge
          if (onOpenNotifications != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onOpenNotifications!();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: HomeEaseTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HomeEaseTheme.outline),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: HomeEaseTheme.textPrimary, size: 20),
                    if (unreadCount > 0)
                      Positioned(
                        right: 7,
                        top: 7,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: HomeEaseTheme.statusConflict,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          ?trailing,

          if (onLogout != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: HomeEaseTheme.muted, size: 20),
              tooltip: 'Logout',
              onPressed: () {
                HapticFeedback.lightImpact();
                onLogout!();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({
    required this.onBack,
    this.trailing,
    this.onLogout,
  });

  final VoidCallback onBack;
  final Widget? trailing;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onBack();
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: HomeEaseTheme.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HomeEaseTheme.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: HomeEaseTheme.textPrimary,
              size: 16,
            ),
          ),
        ),
        const Spacer(),
        ?trailing,
        if (onLogout != null)
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: HomeEaseTheme.muted),
            onPressed: onLogout,
          ),
      ],
    );
  }
}

/// Ergonomic Bottom Navigation Bar adhering to HCI standards (48+ dp targets, clear active states, haptic feedback)
class HomeEaseBottomNav extends StatelessWidget {
  const HomeEaseBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isWorker,
    this.unreadCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isWorker;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;

    final householdItems = [
      _NavItemData(
        icon: Icons.search_rounded,
        activeIcon: Icons.search_rounded,
        label: isUrdu ? 'تلاش' : 'Explore',
      ),
      _NavItemData(
        icon: Icons.post_add_rounded,
        activeIcon: Icons.post_add_rounded,
        label: isUrdu ? 'ملازمتیں' : 'Jobs',
      ),
      _NavItemData(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: isUrdu ? 'بکنگز' : 'Bookings',
      ),
      _NavItemData(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: isUrdu ? 'پروفائل' : 'Profile',
      ),
    ];

    final workerItems = [
      _NavItemData(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: isUrdu ? 'ڈیش بورڈ' : 'Dashboard',
      ),
      _NavItemData(
        icon: Icons.work_outline_rounded,
        activeIcon: Icons.work_rounded,
        label: isUrdu ? 'کام تلاش کریں' : 'Find Gigs',
      ),
      _NavItemData(
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment_rounded,
        label: isUrdu ? 'میرے کام' : 'My Jobs',
      ),
      _NavItemData(
        icon: Icons.event_available_outlined,
        activeIcon: Icons.event_available_rounded,
        label: isUrdu ? 'دستیابی' : 'Availability',
      ),
    ];

    final items = isWorker ? workerItems : householdItems;

    return Container(
      decoration: BoxDecoration(
        color: HomeEaseTheme.white,
        border: const Border(
          top: BorderSide(color: HomeEaseTheme.outline, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(index);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? HomeEaseTheme.accentLight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? HomeEaseTheme.brand
                              : HomeEaseTheme.muted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? HomeEaseTheme.brand
                              : HomeEaseTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
