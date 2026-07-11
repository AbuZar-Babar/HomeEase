import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/home_ease_theme.dart';

class HomeEaseButton extends StatelessWidget {
  const HomeEaseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary
              ? HomeEaseTheme.brand
              : HomeEaseTheme.cardDark,
          foregroundColor: isPrimary
              ? HomeEaseTheme.white
              : HomeEaseTheme.brand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
          foregroundColor: HomeEaseTheme.brandSoft,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
    this.color = HomeEaseTheme.card,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
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
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
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
        color: HomeEaseTheme.cardDark,
        borderRadius: BorderRadius.circular(circular ? size / 2 : 18),
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
        color: HomeEaseTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HomeEaseTheme.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
