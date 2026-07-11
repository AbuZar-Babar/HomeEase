import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class WorkerListScreen extends StatelessWidget {
  const WorkerListScreen({
    super.key,
    required this.workers,
    required this.onBack,
    required this.onSelectWorker,
  });

  final List<WorkerProfile> workers;
  final VoidCallback onBack;
  final ValueChanged<WorkerProfile> onSelectWorker;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Workers near you',
      onBack: onBack,
      child: Column(
        children: workers.map((worker) {
          final highlightCard = worker.name == 'Sana Gul'
              ? HomeEaseTheme.cardDark
              : HomeEaseTheme.white;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: () => onSelectWorker(worker),
              borderRadius: BorderRadius.circular(28),
              child: HomeEaseCard(
                color: highlightCard,
                child: Row(
                  children: [
                    const WorkerAvatar(size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            worker.rate,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: HomeEaseTheme.brandSoft),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${worker.highlight}  |  ${worker.rating} stars',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: HomeEaseTheme.brand,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
