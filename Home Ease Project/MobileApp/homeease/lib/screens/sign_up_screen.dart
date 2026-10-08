import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/home_ease_theme.dart';
import '../widgets/animated_scale_button.dart';

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
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // Worker specific fields
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String _selectedCategory = 'Cleaner';
  String? _cnicDocumentPath;

  final List<String> _serviceCategories = [
    'Cleaner',
    'Cook',
    'Nanny',
    'Caregiver',
    'Maid',
    'Electrician',
    'Plumber',
    'Painter',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole.isNotEmpty ? widget.initialRole : 'Household';
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

  void _attachCnicDocument() {
    HapticFeedback.lightImpact();
    setState(() {
      _cnicDocumentPath = 'cnic_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('CNIC verification document attached.'),
          ],
        ),
        backgroundColor: HomeEaseTheme.statusVerified,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleSubmit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passController.text;
    final isWorker = _selectedRole == 'Worker';

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Please fill in all basic account details.')),
            ],
          ),
          backgroundColor: HomeEaseTheme.statusConflict,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (password.length < 6) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Password must be at least 6 characters.')),
            ],
          ),
          backgroundColor: HomeEaseTheme.statusConflict,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (isWorker) {
      if (_rateController.text.trim().isEmpty ||
          _experienceController.text.trim().isEmpty ||
          _cnicDocumentPath == null) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Please enter expected rate, experience, and upload CNIC.')),
              ],
            ),
            backgroundColor: HomeEaseTheme.statusConflict,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };

    if (isWorker) {
      data['category'] = _selectedCategory;
      data['rate'] = _rateController.text.trim();
      data['experience'] = _experienceController.text.trim();
      data['bio'] = _bioController.text.trim().isNotEmpty
          ? _bioController.text.trim()
          : 'Dedicated service professional';
      data['cnicPath'] = _cnicDocumentPath;
    }

    widget.onCreateAccount(_selectedRole, data);
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = _selectedRole == 'Worker';
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: HomeEaseTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 500;
            final isSmall = constraints.maxWidth < 360;
            final horizontalPadding = isWide ? 32.0 : (isSmall ? 16.0 : 20.0);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isKeyboardOpen ? 12.0 : 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back Button Header
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 22),
                            color: HomeEaseTheme.brand,
                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                            onPressed: widget.onBack,
                            tooltip: 'Back to Sign In',
                          ),
                        ),
                      ),

                      // Header Hero Section
                      _buildHeaderHero(isWorker, isSmall),
                      const SizedBox(height: 22),

                      // Role Switcher Tabs
                      _buildRoleSelector()
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 18),

                      // Main Sign Up Form Card
                      _buildFormCard(isWorker, isWide)
                          .animate()
                          .fadeIn(duration: 450.ms, delay: 200.ms)
                          .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 20),

                      // Footer "Already have an account? Sign in"
                      _buildFooterAction()
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderHero(bool isWorker, bool isSmall) {
    return Column(
      children: [
        Container(
          width: isSmall ? 56 : 64,
          height: isSmall ? 56 : 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HomeEaseTheme.brand,
                Color(0xFF0D9488),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: HomeEaseTheme.brandGlow,
          ),
          child: Center(
            child: Icon(
              isWorker ? Icons.badge_rounded : Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        )
            .animate()
            .scale(duration: 450.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 350.ms),

        const SizedBox(height: 14),

        Text(
          'Create Your Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmall ? 23 : 26,
            fontWeight: FontWeight.w800,
            color: HomeEaseTheme.text,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 80.ms)
            .slideY(begin: -0.1, end: 0),

        const SizedBox(height: 6),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            isWorker
                ? 'Join as a service professional & find jobs nearby'
                : 'Join as a household & hire trusted local helpers',
            key: ValueKey(isWorker),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 12.5 : 13.5,
              fontWeight: FontWeight.w500,
              color: HomeEaseTheme.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleTabItem(
              title: 'Household',
              subtitle: 'Request services',
              icon: Icons.home_rounded,
              isSelected: _selectedRole == 'Household',
              onTap: () {
                if (_selectedRole != 'Household') {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRole = 'Household');
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildRoleTabItem(
              title: 'Worker',
              subtitle: 'Offer services',
              icon: Icons.handyman_rounded,
              isSelected: _selectedRole == 'Worker',
              onTap: () {
                if (_selectedRole != 'Worker') {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRole = 'Worker');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTabItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedScaleTap(
      onTap: onTap,
      scaleFactor: 0.96,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? HomeEaseTheme.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected ? HomeEaseTheme.brandGlow : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : HomeEaseTheme.muted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : HomeEaseTheme.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : HomeEaseTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isWorker, bool isWide) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: HomeEaseTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
        boxShadow: HomeEaseTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Header
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: HomeEaseTheme.brand,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 14),

          // Full Name
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'e.g. Fatima Ali',
            icon: Icons.person_outline_rounded,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'name@example.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          // Phone Number
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+92 300 1234567',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          // Password
          _buildPasswordField(),

          // Worker Details Section (Smooth Animated Expansion)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: isWorker ? _buildWorkerDetailsSection(isWide) : const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Submit CTA Button
          AnimatedScaleTap(
            onTap: _isLoading ? null : _handleSubmit,
            scaleFactor: 0.97,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    HomeEaseTheme.brand,
                    Color(0xFF0D9488),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: HomeEaseTheme.brandGlow,
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isWorker ? 'Register as Worker' : 'Create Household Account',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerDetailsSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        const Divider(height: 1, color: HomeEaseTheme.cardDark),
        const SizedBox(height: 18),

        Row(
          children: const [
            Icon(Icons.workspace_premium_rounded, size: 18, color: HomeEaseTheme.brand),
            SizedBox(width: 8),
            Text(
              'Professional Profile',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: HomeEaseTheme.brand,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Service Category
        Text(
          'Primary Trade / Service',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: HomeEaseTheme.text.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          dropdownColor: HomeEaseTheme.surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: HomeEaseTheme.brand),
          style: const TextStyle(fontSize: 14.5, color: HomeEaseTheme.text, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.handyman_outlined, size: 20, color: HomeEaseTheme.brand),
            filled: true,
            fillColor: HomeEaseTheme.card.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: HomeEaseTheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: HomeEaseTheme.brand, width: 2),
            ),
          ),
          items: _serviceCategories.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(cat),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCategory = val);
            }
          },
        ),

        const SizedBox(height: 14),

        // Responsive Rate & Experience: side-by-side on wide screens, stacked on small
        if (isWide)
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _rateController,
                  label: 'Expected Rate (PKR)',
                  hint: 'e.g. 2500 / visit',
                  icon: Icons.payments_outlined,
                  action: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField(
                  controller: _experienceController,
                  label: 'Experience',
                  hint: 'e.g. 4 years',
                  icon: Icons.work_history_outlined,
                  action: TextInputAction.next,
                ),
              ),
            ],
          )
        else ...[
          _buildTextField(
            controller: _rateController,
            label: 'Expected Rate (PKR)',
            hint: 'e.g. 2500 / visit',
            icon: Icons.payments_outlined,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _experienceController,
            label: 'Experience',
            hint: 'e.g. 4 years',
            icon: Icons.work_history_outlined,
            action: TextInputAction.next,
          ),
        ],

        const SizedBox(height: 14),

        // Bio
        _buildTextField(
          controller: _bioController,
          label: 'Brief Bio / Description',
          hint: 'Describe your skills, punctuality, and specialties...',
          icon: Icons.notes_rounded,
          maxLines: 2,
          action: TextInputAction.done,
        ),

        const SizedBox(height: 16),

        // CNIC Document Upload Card
        Text(
          'CNIC / ID Document Verification',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: HomeEaseTheme.text.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedScaleTap(
          onTap: _attachCnicDocument,
          scaleFactor: 0.98,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 76,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _cnicDocumentPath != null
                  ? HomeEaseTheme.primaryLight.withValues(alpha: 0.5)
                  : HomeEaseTheme.card.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _cnicDocumentPath != null
                    ? HomeEaseTheme.brand
                    : HomeEaseTheme.outline,
                width: _cnicDocumentPath != null ? 1.8 : 1.0,
              ),
            ),
            child: _cnicDocumentPath != null
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.statusVerified.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: HomeEaseTheme.statusVerified, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CNIC Photo Attached',
                              style: TextStyle(
                                color: HomeEaseTheme.brand,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _cnicDocumentPath!,
                              style: const TextStyle(fontSize: 11, color: HomeEaseTheme.muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: HomeEaseTheme.muted),
                        onPressed: () {
                          setState(() => _cnicDocumentPath = null);
                        },
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_outlined, color: HomeEaseTheme.brand, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Upload CNIC / ID Card Copy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: HomeEaseTheme.text,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Required for verification badge and job eligibility',
                              style: TextStyle(fontSize: 11, color: HomeEaseTheme.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: HomeEaseTheme.text.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: action,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14.5, color: HomeEaseTheme.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: HomeEaseTheme.muted, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: HomeEaseTheme.brand),
            filled: true,
            fillColor: HomeEaseTheme.card.withValues(alpha: 0.5),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 14 : 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: HomeEaseTheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: HomeEaseTheme.brand, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: HomeEaseTheme.text.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 14.5, color: HomeEaseTheme.text),
          decoration: InputDecoration(
            hintText: 'At least 6 characters',
            hintStyle: const TextStyle(color: HomeEaseTheme.muted, fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: HomeEaseTheme.brand),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: HomeEaseTheme.muted,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
            ),
            filled: true,
            fillColor: HomeEaseTheme.card.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: HomeEaseTheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: HomeEaseTheme.brand, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterAction() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(
            fontSize: 14,
            color: HomeEaseTheme.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onSignIn();
          },
          style: TextButton.styleFrom(
            foregroundColor: HomeEaseTheme.brand,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
          child: const Text(
            'Sign in',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
