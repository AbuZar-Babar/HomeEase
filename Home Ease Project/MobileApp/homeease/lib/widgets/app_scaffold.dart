import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import 'animated_scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

    return Directionality(
      textDirection: LocalizationService.direction,
      child: Scaffold(
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
                              if (trailing != null) trailing!,
                              if (onLogout != null)
                                IconButton(
                                  icon: const Icon(Icons.logout_rounded, color: HomeEaseTheme.brand),
                                  tooltip: 'Logout',
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
          Flexible(
            fit: FlexFit.loose,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
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
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'HomeEase',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: HomeEaseTheme.brand,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (roleBadge != null)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.accentLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            roleBadge!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
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
          const SizedBox(width: 6),
          const Spacer(),

          // Actions row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact Language Switcher with 48dp touch target
              if (onToggleLanguage != null)
                Semantics(
                  label: LocalizationService.isUrdu ? 'انگریزی زبان میں تبدیل کریں' : 'Switch to Urdu language',
                  button: true,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onToggleLanguage!();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.8)),
                        boxShadow: HomeEaseTheme.cardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.translate_rounded, size: 15, color: HomeEaseTheme.brand),
                          const SizedBox(width: 5),
                          Text(
                            LocalizationService.isUrdu ? 'English' : 'اردو',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: HomeEaseTheme.brand,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Notification Bell with Unread Badge (48dp touch target)
              if (onOpenNotifications != null) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: unreadCount > 0 ? 'Notifications, $unreadCount unread' : 'Notifications',
                  button: true,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onOpenNotifications!();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.8)),
                        boxShadow: HomeEaseTheme.cardShadow,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: HomeEaseTheme.textPrimary, size: 21),
                          if (unreadCount > 0)
                            Positioned(
                              right: 9,
                              top: 9,
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
                ),
              ],

              if (trailing != null) trailing!,

              if (onLogout != null) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.8)),
                    boxShadow: HomeEaseTheme.cardShadow,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded, color: HomeEaseTheme.muted, size: 19),
                    tooltip: 'Logout',
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onLogout!();
                    },
                  ),
                ),
              ],
            ],
          ),
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
        Semantics(
          label: 'Back',
          button: true,
          child: AnimatedScaleTap(
            onTap: onBack,
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: HomeEaseTheme.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HomeEaseTheme.outline),
                boxShadow: HomeEaseTheme.cardShadow,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: HomeEaseTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
        if (onLogout != null)
          Semantics(
            label: 'Logout',
            button: true,
            child: AnimatedScaleTap(
              onTap: onLogout,
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8.0),
                child: const Icon(Icons.logout_rounded, color: HomeEaseTheme.muted, size: 20),
              ),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.05, end: 0, curve: Curves.easeOutCubic);
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

    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Container(
      decoration: BoxDecoration(
        color: HomeEaseTheme.white,
        border: Border(
          top: BorderSide(
            color: HomeEaseTheme.outline.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: Semantics(
                  label: item.label,
                  selected: isSelected,
                  button: true,
                  child: AnimatedScaleTap(
                    scaleFactor: 0.92,
                    onTap: () => onTap(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 16 : 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? HomeEaseTheme.accentLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected
                                    ? HomeEaseTheme.brand
                                    : HomeEaseTheme.muted,
                                size: 22,
                              ),
                              if (unreadCount > 0 && ((!isWorker && index == 2) || (isWorker && index == 0)))
                                Positioned(
                                  top: -2,
                                  right: -4,
                                  child: disableAnimations
                                      ? Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: HomeEaseTheme.statusConflict,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: HomeEaseTheme.statusConflict,
                                            shape: BoxShape.circle,
                                          ),
                                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                          begin: const Offset(0.8, 0.8),
                                          end: const Offset(1.2, 1.2),
                                          duration: 800.ms,
                                        ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? HomeEaseTheme.brand
                              : HomeEaseTheme.muted,
                          fontFamily: 'Roboto',
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
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
