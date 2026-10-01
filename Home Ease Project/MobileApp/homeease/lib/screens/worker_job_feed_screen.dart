import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../services/job_repository.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';

class WorkerJobFeedScreen extends StatefulWidget {
  const WorkerJobFeedScreen({
    super.key,
    required this.jobPosts,
    required this.currentWorker,
    required this.onApply,
    required this.onBack,
  });

  final List<JobPost> jobPosts;
  final WorkerProfile currentWorker;
  final ValueChanged<JobApplication> onApply;
  final VoidCallback onBack;

  @override
  State<WorkerJobFeedScreen> createState() => _WorkerJobFeedScreenState();
}

class _WorkerJobFeedScreenState extends State<WorkerJobFeedScreen> {
  String _selectedCategory = 'All';
  final Set<String> _appliedJobIds = {};
  List<JobPost> _liveJobs = [];
  bool _isLoading = false;
  bool _isApplying = false;

  final List<String> _filters = ['All', 'Cook', 'Cleaner', 'Nanny', 'Caregiver', 'Maid'];

  @override
  void initState() {
    super.initState();
    _liveJobs = List.from(widget.jobPosts);
    _fetchLiveJobsAndApplications();
  }

  @override
  void didUpdateWidget(WorkerJobFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jobPosts != oldWidget.jobPosts) {
      _liveJobs = List.from(widget.jobPosts);
    }
  }

  Future<void> _fetchLiveJobsAndApplications() async {
    setState(() => _isLoading = true);
    try {
      final categoryFilter = _selectedCategory != 'All' ? _selectedCategory : null;
      final jobsFuture = JobRepository().fetchOpenJobs(category: categoryFilter);
      final appsFuture = JobRepository().fetchApplicationsForWorker(widget.currentWorker.id);

      final results = await Future.wait([jobsFuture, appsFuture]);
      final jobs = results[0] as List<JobPost>;
      final apps = results[1] as List<JobApplication>;

      if (mounted) {
        setState(() {
          _liveJobs = jobs;
          for (final a in apps) {
            _appliedJobIds.add(a.jobPostId);
            _appliedJobIds.add(IdMapping.toJobUuid(a.jobPostId));
          }
        });
      }
    } catch (e) {
      debugPrint('WorkerJobFeedScreen error loading jobs: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applyOneTap(JobPost job) async {
    final alreadyApplied = _appliedJobIds.contains(job.id) ||
        _appliedJobIds.any((id) => IdMapping.matchesJob(id, job.id));
    if (alreadyApplied || _isApplying) return;

    setState(() => _isApplying = true);
    try {
      final application = JobApplication(
        id: 'app_${DateTime.now().millisecondsSinceEpoch}',
        jobPostId: job.id,
        workerId: widget.currentWorker.id,
        workerName: widget.currentWorker.name,
        workerRole: widget.currentWorker.role,
        workerRating: widget.currentWorker.rating,
        proposedRate: job.budget,
        notes: LocalizationService.isUrdu
            ? 'میں مطلوبہ تاریخ پر معیاری کام کے لیے دستیاب ہوں۔'
            : 'Available on required date with complete tools.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      final created = await JobRepository().applyForJob(application);
      if (!mounted) return;
      setState(() {
        _appliedJobIds.add(job.id);
        _appliedJobIds.add(IdMapping.toJobUuid(job.id));
      });
      widget.onApply(created);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.isUrdu
                ? '1-ٹیپ کے ذریعے درخواست کامیابی سے جمع ہو گئی!'
                : 'Applied with 1-tap! Application submitted.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  void _showApplyDialog(JobPost job) {
    final proposedRateController = TextEditingController(text: job.budget.toStringAsFixed(0));
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LocalizationService.getCategoryIcon(job.serviceCategory),
                      color: HomeEaseTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: HomeEaseTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${job.area} • PKR ${job.budget.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: HomeEaseTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: HomeEaseTheme.outline),
              const SizedBox(height: 12),
              Text(
                LocalizationService.isUrdu ? 'آپ کا مجوزہ معاوضہ (روپے)' : 'Your Proposed Rate (PKR)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: HomeEaseTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: proposedRateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'PKR ',
                  filled: true,
                  fillColor: HomeEaseTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HomeEaseTheme.outline),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                LocalizationService.isUrdu
                    ? 'مختصر پیغام یا وقت کی وضاحت (اختیاری)'
                    : 'Message or availability note (Optional)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: HomeEaseTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: LocalizationService.isUrdu
                      ? 'مثلاً: میں وقت پر پہنچ جاؤں گا اور تمام کام معیاری کروں گا۔'
                      : 'e.g., I am available at this time and have 4+ years experience.',
                  filled: true,
                  fillColor: HomeEaseTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HomeEaseTheme.outline),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeEaseTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isApplying
                      ? null
                      : () async {
                          final proposedRate =
                              double.tryParse(proposedRateController.text.trim()) ?? job.budget;
                          final app = JobApplication(
                            id: 'app_${DateTime.now().millisecondsSinceEpoch}',
                            jobPostId: job.id,
                            workerId: widget.currentWorker.id,
                            workerName: widget.currentWorker.name,
                            workerRole: widget.currentWorker.role,
                            workerRating: widget.currentWorker.rating,
                            proposedRate: proposedRate,
                            notes: notesController.text.trim(),
                            status: 'pending',
                            appliedAt: DateTime.now(),
                          );
                          Navigator.pop(ctx);
                          setState(() => _isApplying = true);
                          try {
                            final created = await JobRepository().applyForJob(app);
                            if (!mounted) return;
                            setState(() {
                              _appliedJobIds.add(job.id);
                              _appliedJobIds.add(IdMapping.toJobUuid(job.id));
                            });
                            widget.onApply(created);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(LocalizationService.tr('applySuccess'))),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Application error: $e')),
                            );
                          } finally {
                            if (mounted) setState(() => _isApplying = false);
                          }
                        },
                  child: Text(
                    LocalizationService.tr('applyNow'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final candidateJobs = _liveJobs;
    final activeJobs = candidateJobs.where((p) => p.status == 'open').toList();

    final filteredJobs = activeJobs.where((p) {
      if (_selectedCategory == 'All') return true;
      return p.serviceCategory.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AppScaffold(
        title: LocalizationService.tr('availableJobsTitle'),
        subtitle: isUrdu
            ? 'ایبٹ آباد کے گھرانوں کی جانب سے شائع کردہ اوپن کام تلاش کریں'
            : 'Explore open gig requests posted by local households in Abbottabad',
        onBack: widget.onBack,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: HomeEaseTheme.brand),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: HomeEaseTheme.brand),
              onPressed: _fetchLiveJobsAndApplications,
              tooltip: 'Refresh feed',
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _selectedCategory == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        f == 'All'
                            ? LocalizationService.tr('allWorkers')
                            : LocalizationService.tr(f.toLowerCase()),
                      ),
                      selected: isSelected,
                      selectedColor: HomeEaseTheme.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : HomeEaseTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedCategory = f);
                          _fetchLiveJobsAndApplications();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Job List Feed
            if (filteredJobs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_off_outlined,
                        size: 54,
                        color: HomeEaseTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        LocalizationService.tr('noJobsFound'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: HomeEaseTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _fetchLiveJobsAndApplications,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeEaseTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredJobs.map((job) {
                final isApplied = _appliedJobIds.contains(job.id) ||
                    _appliedJobIds.any((id) => IdMapping.matchesJob(id, job.id));
                final icon = LocalizationService.getCategoryIcon(job.serviceCategory);
                final color = LocalizationService.getCategoryColor(job.serviceCategory);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: HomeEaseTheme.outline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Category tag & Budget badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 14, color: color),
                                  const SizedBox(width: 5),
                                  Text(
                                    LocalizationService.tr(job.serviceCategory.toLowerCase()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: HomeEaseTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PKR ${job.budget.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: HomeEaseTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: HomeEaseTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Description
                        Text(
                          job.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: HomeEaseTheme.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),

                        // Meta details row: Area, Date, Household
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: HomeEaseTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              job.area,
                              style: const TextStyle(
                                fontSize: 12,
                                color: HomeEaseTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: HomeEaseTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${job.requiredDate.day}/${job.requiredDate.month}/${job.requiredDate.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: HomeEaseTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons: 1-Tap Apply & Custom Bid
                        SizedBox(
                          width: double.infinity,
                          child: isApplied
                              ? Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isUrdu ? 'درخواست بھیج دی گئی' : 'Applied',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: SizedBox(
                                        height: 42,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: HomeEaseTheme.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                          onPressed: _isApplying ? null : () => _applyOneTap(job),
                                          icon: const Icon(Icons.bolt_rounded, size: 18),
                                          label: Text(
                                            isUrdu ? '1-ٹیپ اپلائی' : '1-Tap Apply',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: SizedBox(
                                        height: 42,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: HomeEaseTheme.primary,
                                            side: const BorderSide(color: HomeEaseTheme.primary),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          onPressed: () => _showApplyDialog(job),
                                          child: Text(
                                            isUrdu ? 'کسٹم آفر' : 'Custom Bid',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
