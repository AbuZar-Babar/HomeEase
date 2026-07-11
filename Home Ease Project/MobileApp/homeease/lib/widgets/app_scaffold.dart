import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/home_ease_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.onBack,
    this.onLogout,
    required this.child,
  });

  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 520
                      ? 460
                      : constraints.maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (onBack != null) _BackHeader(onBack: onBack!),
                    if (title != null) ...[
                      SizedBox(height: onBack == null ? 0 : 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(title!, style: theme.textTheme.headlineMedium),
                          ),
                          if (onLogout != null)
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: HomeEaseTheme.brand),
                              onPressed: onLogout,
                            ),
                        ],
                      ),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(subtitle!, style: theme.textTheme.bodyLarge),
                    ],
                    const SizedBox(height: 20),
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

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.onBack});

  final VoidCallback onBack;

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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: HomeEaseTheme.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: HomeEaseTheme.text,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
