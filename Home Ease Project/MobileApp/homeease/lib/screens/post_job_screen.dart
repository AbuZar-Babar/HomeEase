import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample_data.dart';
import '../models/worker_profile.dart';
import '../services/job_repository.dart';
import '../services/localization_service.dart';
import '../services/supabase_auth_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({
    super.key,
    required this.onJobPosted,
    this.onBack,
    this.existingJobs = const [],
    this.applications = const [],
    this.onAcceptApplication,
    this.bottomNavigationBar,
    this.onToggleLanguage,
    this.onOpenNotifications,
    this.unreadNotificationsCount,
    this.onLogout,
  });

  final ValueChanged<JobPost> onJobPosted;
  final VoidCallback? onBack;
  final List<JobPost> existingJobs;
  final List<JobApplication> applications;
  final ValueChanged<JobApplication>? onAcceptApplication;
  final Widget? bottomNavigationBar;
  final VoidCallback? onToggleLanguage;
  final VoidCallback? onOpenNotifications;
  final int? unreadNotificationsCount;
  final VoidCallback? onLogout;

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController(text: '2500');

  String _selectedCategory = 'Cook';
  String _selectedArea = 'Mandian';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  final List<String> _categories = ['Cook', 'Cleaner', 'Nanny', 'Caregiver', 'Maid'];
  final List<String> _areas = ['Mandian', 'Jhangi Syedan', 'Supply Bazaar', 'Nawan Shehr', 'PMA Kakul Road'];
  final List<double> _presetBudgets = [1500, 2500, 4000, 6000];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: HomeEaseTheme.brand,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: HomeEaseTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      try {
        final budgetVal = double.tryParse(_budgetController.text.trim()) ?? 2500.0;
        final coords = SampleData.localityCoordinates[_selectedArea] ?? {'lat': 34.1983, 'lon': 73.2425};
        final user = SupabaseAuthService().currentUser;
        final authClient = SupabaseAuthService().client;
        final authId = authClient?.auth.currentUser?.id;
        final effectiveHouseholdId = user?.id ?? authId ?? '00000000-0000-0000-0000-000000000001';

        final newPost = JobPost(
          id: 'job_${DateTime.now().millisecondsSinceEpoch}',
          householdId: effectiveHouseholdId,
          householdName: user?.fullName ?? 'Household Employer',
          title: _titleController.text.trim(),
          serviceCategory: _selectedCategory,
          description: _descriptionController.text.trim(),
          city: 'Abbottabad',
          area: _selectedArea,
          latitude: coords['lat']!,
          longitude: coords['lon']!,
          budget: budgetVal,
          requiredDate: _selectedDate,
          status: 'open',
          createdAt: DateTime.now(),
        );

        final created = await JobRepository().createJob(newPost);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.tr('postSuccess'))),
        );
        _titleController.clear();
        _descriptionController.clear();
        widget.onJobPosted(created);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating job: $e')),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AppScaffold(
        title: LocalizationService.tr('postGigTitle'),
        subtitle: isUrdu
            ? 'مقامی ورکرز کے لیے کام کی تفصیلات شائع کریں'
            : 'Publish task details for local Abbottabad workers to apply',
        onBack: widget.onBack,
        roleBadge: widget.onBack == null ? 'Household' : null,
        onToggleLanguage: widget.onToggleLanguage,
        onOpenNotifications: widget.onOpenNotifications,
        unreadNotificationsCount: widget.unreadNotificationsCount,
        onLogout: widget.onLogout,
        bottomNavigationBar: widget.bottomNavigationBar,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card with Teal Trust Styling
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HomeEaseTheme.accentLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HomeEaseTheme.brand.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.brand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isUrdu
                            ? 'آپ کا پوسٹ کیا ہوا کام ایبٹ آباد کے قریبی تصدیق شدہ ورکرز کی فیڈ میں فوراً ظاہر ہوگا۔'
                            : 'Your open gig will be immediately broadcast to matching verified workers in Abbottabad.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: HomeEaseTheme.brand,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              SectionLabel(LocalizationService.tr('selectCategory')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final icon = LocalizationService.getCategoryIcon(cat);
                  return ChoiceChip(
                    avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : HomeEaseTheme.brand),
                    label: Text(LocalizationService.tr(cat.toLowerCase())),
                    selected: isSelected,
                    selectedColor: HomeEaseTheme.brand,
                    backgroundColor: HomeEaseTheme.white,
                    side: BorderSide(
                      color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : HomeEaseTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Job Title
              SectionLabel(LocalizationService.tr('jobTitle')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: isUrdu ? 'مثلاً: فیملی ڈنر کے لیے باورچی درکار ہے' : 'e.g., Dinner Cook Needed for Family',
                  prefixIcon: const Icon(Icons.title_rounded, color: HomeEaseTheme.brand),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 18),

              // Locality Dropdown
              SectionLabel(LocalizationService.tr('selectArea')),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: HomeEaseTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HomeEaseTheme.outline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedArea,
                    isExpanded: true,
                    icon: const Icon(Icons.location_on_rounded, color: HomeEaseTheme.brand),
                    items: _areas.map((a) {
                      return DropdownMenuItem(
                        value: a,
                        child: Text(a, style: const TextStyle(fontSize: 14, color: HomeEaseTheme.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedArea = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Required Date
              SectionLabel(isUrdu ? 'مطلوبہ تاریخ' : 'Required Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HomeEaseTheme.outline),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HomeEaseTheme.textPrimary),
                      ),
                      const Icon(Icons.calendar_today_rounded, color: HomeEaseTheme.brand, size: 19),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Budget (PKR) with Quick Preset Chips
              SectionLabel(LocalizationService.tr('budget')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: 'PKR ',
                  hintText: 'e.g., 2500',
                  prefixIcon: Icon(Icons.payments_outlined, color: HomeEaseTheme.brand),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please specify a budget';
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) return 'Enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _presetBudgets.map((b) {
                  final isSelected = _budgetController.text == b.toInt().toString();
                  return ActionChip(
                    label: Text('Rs. ${b.toInt()}'),
                    backgroundColor: isSelected ? HomeEaseTheme.accentLight : HomeEaseTheme.card,
                    side: BorderSide(color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.textSecondary,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _budgetController.text = b.toInt().toString();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Task Scope Description
              SectionLabel(isUrdu ? 'کام کی تفصیل اور تقاضے' : 'Task Scope & Instructions'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isUrdu
                      ? 'تفصیل لکھیں جیسے کچن کی صفائی، برتن دھونا، یا مخصوص ڈشز وغیرہ'
                      : 'Describe specific tasks (e.g., deep kitchen cleanup, dishes, or specific dishes to cook)',
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please provide task description' : null,
              ),
              const SizedBox(height: 24),

              // Submit Button
              HomeEaseButton(
                label: _isSubmitting ? 'Publishing...' : LocalizationService.tr('submitPost'),
                icon: Icons.send_rounded,
                onPressed: _isSubmitting ? () {} : _submit,
              ),

              // Existing Gigs List & Applications Received
              if (widget.existingJobs.isNotEmpty) ...[
                const SizedBox(height: 28),
                SectionLabel(isUrdu ? 'آپ کی شائع کردہ جابز اور موصولہ درخواستیں' : 'Your Posted Gigs & Applications'),
                const SizedBox(height: 10),
                ...widget.existingJobs.take(5).map((job) {
                  final jobApps = widget.applications.where((a) => a.jobPostId == job.id).toList();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HomeEaseCard(
                      color: HomeEaseTheme.white,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LocalizationService.getCategoryIcon(job.serviceCategory),
                                color: HomeEaseTheme.brand,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${job.area} • PKR ${job.budget.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, color: HomeEaseTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: HomeEaseTheme.accentLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  job.status.toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: HomeEaseTheme.brand),
                                ),
                              ),
                            ],
                          ),
                          if (jobApps.isNotEmpty) ...[
                            const Divider(height: 20, color: HomeEaseTheme.outline),
                            Row(
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 16, color: HomeEaseTheme.brand),
                                const SizedBox(width: 6),
                                Text(
                                  isUrdu
                                      ? 'موصولہ تجاویز (${jobApps.length}):'
                                      : 'Proposals Received (${jobApps.length}):',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: HomeEaseTheme.brand),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...jobApps.map((app) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: HomeEaseTheme.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: HomeEaseTheme.outline),
                                ),
                                child: Row(
                                  children: [
                                    const WorkerAvatar(circular: true, size: 36),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            app.workerName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            'Bid: PKR ${app.proposedRate.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 11, color: HomeEaseTheme.brand, fontWeight: FontWeight.bold),
                                          ),
                                          if (app.notes.isNotEmpty)
                                            Text(
                                              '"${app.notes}"',
                                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: HomeEaseTheme.textSecondary),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (widget.onAcceptApplication != null && app.status.toLowerCase() == 'pending')
                                      ElevatedButton(
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          widget.onAcceptApplication!(app);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: HomeEaseTheme.statusVerified,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: const Size(60, 32),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          isUrdu ? 'قبول کریں' : 'Accept',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: HomeEaseTheme.accentLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          app.status.toUpperCase(),
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: HomeEaseTheme.brand),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
