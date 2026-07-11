import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class WorkerDetailScreen extends StatelessWidget {
  const WorkerDetailScreen({
    super.key,
    required this.worker,
    required this.onBack,
    required this.onBookNow,
  });

  final WorkerProfile worker;
  final VoidCallback onBack;
  final VoidCallback onBookNow;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      onBack: onBack,
      child: Column(
        children: [
          HomeEaseCard(
            color: HomeEaseTheme.cardDark,
            child: Column(
              children: [
                const WorkerAvatar(size: 92, circular: true),
                const SizedBox(height: 16),
                Text(
                  worker.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: HomeEaseTheme.brand),
                ),
                const SizedBox(height: 6),
                Text(
                  '${worker.role}  |  ${worker.highlight}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: HomeEaseTheme.brandSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    LabelValueChip(label: 'Rate', value: worker.rate),
                    LabelValueChip(label: 'Rating', value: '${worker.rating}'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  worker.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: HomeEaseTheme.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Experience', value: worker.experience),
                _DetailRow(label: 'Rate', value: worker.rate),
                _DetailRow(label: 'Availability', value: worker.availability),
                _DetailRow(
                  label: 'Location',
                  value: worker.location,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          HomeEaseButton(label: 'Book Now', onPressed: onBookNow),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
