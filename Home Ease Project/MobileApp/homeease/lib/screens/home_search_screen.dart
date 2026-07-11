import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({
    super.key,
    required this.services,
    required this.selectedServices,
    required this.featuredWorkers,
    required this.onToggleService,
    required this.onOpenWorkers,
    required this.onOpenWorker,
    required this.onLogout,
    required this.onOpenBookings,
    required this.onOpenNotifications,
    required this.unreadNotificationsCount,
  });

  final List<String> services;
  final Set<String> selectedServices;
  final List<WorkerProfile> featuredWorkers;
  final ValueChanged<String> onToggleService;
  final VoidCallback onOpenWorkers;
  final ValueChanged<WorkerProfile> onOpenWorker;
  final VoidCallback onLogout;
  final VoidCallback onOpenBookings;
  final VoidCallback onOpenNotifications;
  final int unreadNotificationsCount;

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _areaFilter = 'All Areas';
  String _experienceFilter = 'Any Experience';

  final List<String> _areas = ['All Areas', 'Mandian', 'Jhangi Syedan', 'Supply Bazaar', 'Nawan Shehr'];
  final List<String> _expRanges = ['Any Experience', '1-2 years', '3-5 years', '5+ years'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Local helper to filter workers list dynamically for local prototype
  List<WorkerProfile> _getFilteredWorkers() {
    return widget.featuredWorkers.where((worker) {
      // 1. Service filter
      if (widget.selectedServices.isNotEmpty) {
        final matchesService = widget.selectedServices.any((s) =>
            worker.role.toLowerCase().contains(s.toLowerCase()));
        if (!matchesService) return false;
      }

      // 2. Search query filter
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final matchesQuery = worker.name.toLowerCase().contains(query) ||
            worker.role.toLowerCase().contains(query) ||
            worker.bio.toLowerCase().contains(query);
        if (!matchesQuery) return false;
      }

      // 3. Area filter
      if (_areaFilter != 'All Areas') {
        if (!worker.location.toLowerCase().contains(_areaFilter.toLowerCase())) {
          return false;
        }
      }

      // 4. Experience filter
      if (_experienceFilter != 'Any Experience') {
        final expYears = worker.experienceYears;
        if (_experienceFilter == '1-2 years' && (expYears < 1 || expYears > 2)) return false;
        if (_experienceFilter == '3-5 years' && (expYears < 3 || expYears > 5)) return false;
        if (_experienceFilter == '5+ years' && expYears < 5) return false;
      }

      return true;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: HomeEaseTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.card,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Advanced Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: HomeEaseTheme.brand),
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel('Filter by Area'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _areaFilter,
                    dropdownColor: HomeEaseTheme.surface,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                    items: _areas.map((area) {
                      return DropdownMenuItem(value: area, child: Text(area, style: const TextStyle(color: HomeEaseTheme.text)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _areaFilter = val);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Experience Years'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _experienceFilter,
                    dropdownColor: HomeEaseTheme.surface,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                    items: _expRanges.map((exp) {
                      return DropdownMenuItem(value: exp, child: Text(exp, style: const TextStyle(color: HomeEaseTheme.text)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _experienceFilter = val);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  HomeEaseButton(
                    label: 'Apply Filters',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredWorkers();

    return AppScaffold(
      title: 'Find help nearby',
      onLogout: widget.onLogout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Bookings History Card Button
              Expanded(
                child: InkWell(
                  onTap: widget.onOpenBookings,
                  borderRadius: BorderRadius.circular(20),
                  child: const HomeEaseCard(
                    color: HomeEaseTheme.cardDark,
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_rounded, color: HomeEaseTheme.brand, size: 18),
                        SizedBox(width: 8),
                        Text('Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Notifications Card Button with unread count
              Expanded(
                child: InkWell(
                  onTap: widget.onOpenNotifications,
                  borderRadius: BorderRadius.circular(20),
                  child: HomeEaseCard(
                    color: HomeEaseTheme.card,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_rounded, color: HomeEaseTheme.brand, size: 18),
                            if (widget.unreadNotificationsCount > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                  child: Text(
                                    '${widget.unreadNotificationsCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HomeEaseCard(
            color: HomeEaseTheme.cardDark,
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified workers in Abbottabad',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: HomeEaseTheme.brand,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Quick filters, clear rates, and availability in one place.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: HomeEaseTheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: HomeEaseTheme.brand,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (text) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search cook, nanny, cleaner...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showFilterSheet,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.tune_rounded, color: HomeEaseTheme.brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.services.map((service) {
              final isSelected = widget.selectedServices.contains(service);
              return ChoiceChip(
                label: Text(service),
                selected: isSelected,
                onSelected: (_) => widget.onToggleService(service),
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
          const SizedBox(height: 16),
          HomeEaseCard(
            color: HomeEaseTheme.white,
            child: Row(
              children: [
                Expanded(
                  child: LabelValueChip(
                    label: 'Selected Filters',
                    value: widget.selectedServices.isEmpty ? 'All Services' : widget.selectedServices.join(', '),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LabelValueChip(
                    label: 'Matching Results',
                    value: '${filteredList.length} workers',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SectionLabel('Top picks'),
              const Spacer(),
              TextButton(
                onPressed: widget.onOpenWorkers,
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (filteredList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No workers matching active filters.', style: TextStyle(color: HomeEaseTheme.muted)),
              ),
            )
          else
            ...filteredList.map(
              (worker) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorkerListTile(
                  worker: worker,
                  onTap: () => widget.onOpenWorker(worker),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkerListTile extends StatelessWidget {
  const _WorkerListTile({required this.worker, required this.onTap});

  final WorkerProfile worker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: HomeEaseCard(
        color: HomeEaseTheme.white,
        child: Row(
          children: [
            const WorkerAvatar(circular: true, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${worker.name} - ${worker.role}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${worker.rating} rating  |  ${worker.location}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: HomeEaseTheme.brand),
          ],
        ),
      ),
    );
  }
}
