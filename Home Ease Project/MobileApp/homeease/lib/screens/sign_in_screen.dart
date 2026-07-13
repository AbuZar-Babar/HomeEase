import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/dummy_auth_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

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
  final Function(String role) onCreateAccount; // pass selected role to sign up

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String _selectedRole = 'Household'; // 'Household' or 'Worker'
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue your HomeEase journey.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeEaseCard(
            color: HomeEaseTheme.cardDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue as',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: HomeEaseTheme.brand),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your role first, then sign in with your account details.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: HomeEaseTheme.text),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _RoleButton(
                        icon: Icons.home_rounded,
                        label: 'Household',
                        isSelected: _selectedRole == 'Household',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedRole = 'Household';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RoleButton(
                        icon: Icons.cleaning_services_rounded,
                        label: 'Worker',
                        isSelected: _selectedRole == 'Worker',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedRole = 'Worker';
                          });
                        },
                      ),
                    ),
                  ],
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
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'Email or phone'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Password'),
                ),
                const SizedBox(height: 18),
                HomeEaseButton(
                  label: 'Sign In',
                  onPressed: () {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text;
                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your email and password.')),
                      );
                      return;
                    }
                    
                    final user = DummyAuthService().signIn(email, password, _selectedRole);
                    if (user != null) {
                      if (_selectedRole == 'Household') {
                        widget.onSignIn();
                      } else {
                        widget.onWorkerSignIn();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Invalid credentials for $_selectedRole. Try a demo account or sign up.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HomeEaseCard(
            color: HomeEaseTheme.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: HomeEaseTheme.brand, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Demo Accounts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: HomeEaseTheme.brand,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap a demo role below to auto-fill credentials and update your role.',
                  style: TextStyle(fontSize: 12, color: HomeEaseTheme.muted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.home_rounded, size: 16),
                        label: const Text('Household', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeEaseTheme.cardDark,
                          foregroundColor: HomeEaseTheme.brand,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _selectedRole = 'Household';
                            _emailController.text = 'household@homeease.com';
                            _passwordController.text = 'password123';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Household demo credentials loaded.')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                        label: const Text('Worker', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeEaseTheme.cardDark,
                          foregroundColor: HomeEaseTheme.brand,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _selectedRole = 'Worker';
                            _emailController.text = 'worker@homeease.com';
                            _passwordController.text = 'password123';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Worker demo credentials loaded.')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('New here?', style: Theme.of(context).textTheme.bodyMedium),
              HomeEaseTextAction(
                label: 'Create account',
                onTap: () => widget.onCreateAccount(_selectedRole),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = isSelected ? HomeEaseTheme.brand : HomeEaseTheme.surface;
    final foreground = isSelected ? HomeEaseTheme.white : HomeEaseTheme.brand;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
