import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.initialRole,
    required this.onCreateAccount,
    required this.onBack,
    required this.onSignIn,
  });

  final String initialRole;
  final Function(String role, Map<String, dynamic> data) onCreateAccount;
  final VoidCallback onBack;
  final VoidCallback onSignIn;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late String _selectedRole;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // Worker specific fields
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String _selectedCategory = 'Cleaner';
  String? _simulatedCnicPath;

  final List<String> _serviceCategories = ['Cleaner', 'Cook', 'Nanny', 'Caregiver', 'Maid'];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _rateController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _simulateCnicUpload() {
    HapticFeedback.lightImpact();
    setState(() {
      _simulatedCnicPath = 'assets/mock/cnic_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulated: CNIC document photo uploaded.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = _selectedRole == 'Worker';

    return AppScaffold(
      title: 'Create your account',
      subtitle: isWorker
          ? 'Set up your worker profile and join the platform.'
          : 'Set up your household profile and start requesting services.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeEaseCard(
            color: HomeEaseTheme.card,
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Household', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand)),
                    value: 'Household',
                    groupValue: _selectedRole,
                    activeColor: HomeEaseTheme.brand,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedRole = val);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Worker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand)),
                    value: 'Worker',
                    groupValue: _selectedRole,
                    activeColor: HomeEaseTheme.brand,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedRole = val);
                      }
                    },
                  ),
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
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Full name'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'Email address'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(hintText: 'Phone number'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Create password'),
                ),
                
                // Animated Worker specific input section
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWorker) ...[
                        const Divider(height: 32, color: HomeEaseTheme.background),
                        const Text(
                          'Professional Profile Details',
                          style: TextStyle(fontWeight: FontWeight.bold, color: HomeEaseTheme.brand, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          dropdownColor: HomeEaseTheme.surface,
                          decoration: const InputDecoration(
                            hintText: 'Select service type',
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          items: _serviceCategories.map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(color: HomeEaseTheme.text)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _rateController,
                          decoration: const InputDecoration(hintText: 'Expected rate (e.g. PKR 3,000 / visit)'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _experienceController,
                          decoration: const InputDecoration(hintText: 'Experience (e.g. 4 years)'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _bioController,
                          maxLines: 2,
                          decoration: const InputDecoration(hintText: 'Tell households about yourself...'),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _simulateCnicUpload,
                          child: Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: HomeEaseTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: HomeEaseTheme.card, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: _simulatedCnicPath != null
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('CNIC Photo Added', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.upload_file_rounded, color: HomeEaseTheme.brand, size: 24),
                                      SizedBox(height: 4),
                                      Text('Upload CNIC/ID card copy for verification', style: TextStyle(fontSize: 11)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                HomeEaseButton(
                  label: 'Create Account',
                  onPressed: () {
                    if (_nameController.text.trim().isEmpty ||
                        _emailController.text.trim().isEmpty ||
                        _phoneController.text.trim().isEmpty ||
                        _passController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill out all basic details.')),
                      );
                      return;
                    }
                    if (isWorker) {
                      if (_rateController.text.trim().isEmpty ||
                          _experienceController.text.trim().isEmpty ||
                          _simulatedCnicPath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter expected rate, experience, and upload CNIC details.')),
                        );
                        return;
                      }
                    }

                    // Collect data
                    final Map<String, dynamic> data = {
                      'name': _nameController.text.trim(),
                      'email': _emailController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'password': _passController.text.trim(),
                    };

                    if (isWorker) {
                      data['category'] = _selectedCategory;
                      data['rate'] = _rateController.text.trim();
                      data['experience'] = _experienceController.text.trim();
                      data['bio'] = _bioController.text.trim();
                      data['cnicPath'] = _simulatedCnicPath;
                    }

                    widget.onCreateAccount(_selectedRole, data);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              HomeEaseTextAction(label: 'Sign in', onTap: widget.onSignIn),
            ],
          ),
        ],
      ),
    );
  }
}
