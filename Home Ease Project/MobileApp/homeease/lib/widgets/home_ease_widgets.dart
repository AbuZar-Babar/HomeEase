import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/home_ease_theme.dart';

class HomeEaseButton extends StatelessWidget {
  const HomeEaseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary
              ? HomeEaseTheme.brand
              : HomeEaseTheme.cardDark,
          foregroundColor: isPrimary
              ? HomeEaseTheme.white
              : HomeEaseTheme.textPrimary,
          elevation: isPrimary ? 1.5 : 0,
          shadowColor: isPrimary ? HomeEaseTheme.brand.withValues(alpha: 0.3) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: HomeEaseTheme.outline, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeEaseTextAction extends StatelessWidget {
  const HomeEaseTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.alignment = Alignment.center,
  });

  final String label;
  final VoidCallback onTap;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        style: TextButton.styleFrom(
          foregroundColor: HomeEaseTheme.brand,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class HomeEaseCard extends StatelessWidget {
  const HomeEaseCard({
    super.key,
    required this.child,
    this.color = HomeEaseTheme.white,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isWhite = color == HomeEaseTheme.white || color == Colors.white;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: HomeEaseTheme.outline.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: isWhite
            ? [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: HomeEaseTheme.textPrimary,
            letterSpacing: -0.2,
          ),
    );
  }
}

class WorkerAvatar extends StatelessWidget {
  const WorkerAvatar({super.key, this.size = 56, this.circular = false});

  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE6FFFA), Color(0xFFCCFBF1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(circular ? size / 2 : 18),
        border: Border.all(
          color: HomeEaseTheme.brandSoft.withValues(alpha: 0.35),
          width: 1.4,
        ),
      ),
      child: Icon(
        Icons.home_repair_service_rounded,
        color: HomeEaseTheme.brand,
        size: size * 0.46,
      ),
    );
  }
}

class LabelValueChip extends StatelessWidget {
  const LabelValueChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: HomeEaseTheme.muted,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HomeEaseTheme.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
