import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/supabase_auth_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/animated_scale_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onSignIn,
    required this.onWorkerSignIn,
    this.onBack,
    required this.onCreateAccount,
  });

  final VoidCallback onSignIn;
  final VoidCallback onWorkerSignIn;
  final VoidCallback? onBack;
  final Function(String role) onCreateAccount;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String _selectedRole = 'Household'; // 'Household' or 'Worker'
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Please enter both email and password.')),
            ],
          ),
          backgroundColor: HomeEaseTheme.statusConflict,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await SupabaseAuthService().signIn(email, password, _selectedRole);
      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          HapticFeedback.mediumImpact();
          if (_selectedRole == 'Household') {
            widget.onSignIn();
          } else {
            widget.onWorkerSignIn();
          }
        } else {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Invalid email or password for $_selectedRole. Please try again or create an account.',
                    ),
                  ),
                ],
              ),
              backgroundColor: HomeEaseTheme.statusConflict,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: HomeEaseTheme.statusConflict,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: HomeEaseTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 360;
            final horizontalPadding = constraints.maxWidth > 500 ? 32.0 : (isSmallScreen ? 16.0 : 20.0);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isKeyboardOpen ? 12.0 : 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top back button if available
                      if (widget.onBack != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, size: 22),
                              color: HomeEaseTheme.brand,
                              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                              onPressed: widget.onBack,
                              tooltip: 'Back',
                            ),
                          ),
                        ),

                      // Header / Logo Hero Section
                      _buildHeaderHero(isSmallScreen),
                      const SizedBox(height: 22),

                      // Role Switcher Tabs (includes 'Continue as' label for clarity and test compatibility)
                      _buildRoleSelector()
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 18),

                      // Main Form Card
                      _buildFormCard()
                          .animate()
                          .fadeIn(duration: 450.ms, delay: 200.ms)
                          .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 20),

                      // Bottom "New here? Create account"
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

  Widget _buildHeaderHero(bool isSmall) {
    return Column(
      children: [
        // Brand Icon Badge
        Container(
          width: isSmall ? 60 : 70,
          height: isSmall ? 60 : 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HomeEaseTheme.brand,
                Color(0xFF0D9488),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: HomeEaseTheme.brandGlow,
          ),
          child: const Center(
            child: Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        )
            .animate()
            .scale(duration: 500.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        Text(
          'Welcome back',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmall ? 24 : 28,
            fontWeight: FontWeight.w800,
            color: HomeEaseTheme.text,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 80.ms)
            .slideY(begin: -0.1, end: 0),

        const SizedBox(height: 6),

        Text(
          'Sign in to access verified domestic services',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmall ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: HomeEaseTheme.muted,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 140.ms),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Continue as',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HomeEaseTheme.brand,
            ),
          ),
        ),
        Container(
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
                  subtitle: 'Hire help',
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
                  subtitle: 'Find jobs',
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
        ),
      ],
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

  Widget _buildFormCard() {
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
          // Email field
          Text(
            'Email Address',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HomeEaseTheme.text.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14.5, color: HomeEaseTheme.text),
            decoration: InputDecoration(
              hintText: 'name@example.com',
              hintStyle: const TextStyle(color: HomeEaseTheme.muted, fontSize: 14),
              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20, color: HomeEaseTheme.brand),
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

          const SizedBox(height: 18),

          // Password field
          Text(
            'Password',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HomeEaseTheme.text.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSignIn(),
            style: const TextStyle(fontSize: 14.5, color: HomeEaseTheme.text),
            decoration: InputDecoration(
              hintText: '••••••••',
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

          const SizedBox(height: 12),

          // Quick Demo Credentials Fill Chips
          Row(
            children: [
              Text(
                'Quick Demo:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: HomeEaseTheme.muted,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedRole = 'Household';
                    _emailController.text = 'household@homeease.com';
                    _passwordController.text = 'password123';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HomeEaseTheme.brand.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'Household',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: HomeEaseTheme.brand,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedRole = 'Worker';
                    _emailController.text = 'worker@homeease.com';
                    _passwordController.text = 'password123';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.statusPending.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HomeEaseTheme.statusPending.withValues(alpha: 0.25)),
                  ),
                  child: const Text(
                    'Worker',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: HomeEaseTheme.statusPending,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Primary Sign In Button
          AnimatedScaleTap(
            onTap: _isLoading ? null : _handleSignIn,
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
                            'Sign In as $_selectedRole',
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

  Widget _buildFooterAction() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(
            fontSize: 14,
            color: HomeEaseTheme.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onCreateAccount(_selectedRole);
          },
          style: TextButton.styleFrom(
            foregroundColor: HomeEaseTheme.brand,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
          child: const Text(
            'Create account',
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
