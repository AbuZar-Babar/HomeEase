import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/worker_profile.dart';
import '../services/job_repository.dart';
import '../services/localization_service.dart';
import '../services/supabase_auth_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({
    super.key,
    required this.onJobPosted,
    required this.onBack,
  });

  final ValueChanged<JobPost> onJobPosted;
  final VoidCallback onBack;

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  String _selectedCategory = 'Cook';
  String _selectedArea = 'Mandian';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  final List<String> _categories = ['Cook', 'Cleaner', 'Nanny', 'Caregiver', 'Maid'];
  final List<String> _areas = ['Mandian', 'Jhangi Syedan', 'Supply Bazaar', 'Nawan Shehr', 'PMA Kakul Road'];

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
              primary: HomeEaseTheme.primary,
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HomeEaseTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HomeEaseTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isUrdu
                              ? 'آپ کا پوسٹ کیا ہوا کام ایبٹ آباد کے قریبی تصدیق شدہ ورکرز کی فیڈ میں فوراً ظاہر ہوگا۔'
                              : 'Your open gig will be immediately broadcast to matching verified workers in Abbottabad.',
                          style: TextStyle(
                            fontSize: 13,
                            color: HomeEaseTheme.primaryDark,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category Selector
                Text(
                  LocalizationService.tr('selectCategory'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: HomeEaseTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final icon = LocalizationService.getCategoryIcon(cat);
                    final color = LocalizationService.getCategoryColor(cat);
                    return ChoiceChip(
                      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : color),
                      label: Text(LocalizationService.tr(cat.toLowerCase())),
                      selected: isSelected,
                      selectedColor: HomeEaseTheme.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : HomeEaseTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Job Title
                Text(
                  LocalizationService.tr('jobTitle'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: HomeEaseTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: isUrdu ? 'مثلاً: فیملی ڈنر کے لیے باورچی درکار ہے' : 'e.g., Dinner Cook Needed for Family',
                    prefixIcon: const Icon(Icons.title_rounded, color: HomeEaseTheme.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: HomeEaseTheme.outline),
                    ),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 18),

                // Locality Dropdown
                Text(
                  LocalizationService.tr('selectArea'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: HomeEaseTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HomeEaseTheme.outline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedArea,
                      isExpanded: true,
                      icon: const Icon(Icons.location_on_rounded, color: HomeEaseTheme.primary),
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
                Text(
                  isUrdu ? 'مطلوبہ تاریخ' : 'Required Date',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: HomeEaseTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: HomeEaseTheme.outline),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HomeEaseTheme.textPrimary),
                        ),
                        const Icon(Icons.calendar_today_rounded, color: HomeEaseTheme.primary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Budget (PKR)
                Text(
                  LocalizationService.tr('budget'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: HomeEaseTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g., 3000',
                    prefixIcon: const Icon(Icons.payments_outlined, color: HomeEaseTheme.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: HomeEaseTheme.outline),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please specify a budget';
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) return 'Enter a valid positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Task Scope Description
                Text(
                  isUrdu ? 'کام کی تفصیل اور تقاضے' : 'Task Scope & Specific Instructions',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: HomeEaseTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: isUrdu
                        ? 'تفصیل لکھیں جیسے کچن کی صفائی، برتن دھونا، یا مخصوص ڈشز وغیرہ'
                        : 'Describe specific tasks (e.g., deep kitchen cleanup, dishes, or specific dishes to cook)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: HomeEaseTheme.outline),
                    ),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please provide task description' : null,
                ),
                const SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomeEaseTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            LocalizationService.tr('submitPost'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
