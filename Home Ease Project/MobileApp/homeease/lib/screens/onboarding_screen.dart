import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/animated_scale_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardData> _slides = [
    OnboardData(
      title: 'Hyper-Local Search',
      titleUrdu: 'ایبٹ آباد میں تصدیق شدہ ورکرز',
      description: 'Discover trusted, CNIC-verified domestic cooks, maids, and caretakers in your immediate neighborhood.',
      descriptionUrdu: 'اپنے قریبی علاقوں میں بااعتماد، نادرا تصدیق شدہ باورچی، ملازمین اور آیا آسانی سے تلاش کریں۔',
      icon: Icons.location_on_rounded,
      tag: 'Abbottabad Network',
    ),
    OnboardData(
      title: 'AI Smart Match & Trust',
      titleUrdu: 'اے آئی مطابقت اور مکمل تصدیق',
      description: 'Content-based AI recommendations match verified skills and distance with 100% transparent pricing.',
      descriptionUrdu: 'ہماری جدید اے آئی ٹیکنالوجی فاصلے اور مہارت کی بنیاد پر بہترین ورکرز تجویز کرتی ہے۔',
      icon: Icons.verified_user_rounded,
      tag: 'NADRA Verified',
    ),
    OnboardData(
      title: 'Conflict-Free Booking',
      titleUrdu: 'بغیر کسی الجھن کے آسان بکنگ',
      description: 'Zero schedule overlaps, digital service agreements, and secure 4-digit arrival OTP verification.',
      descriptionUrdu: 'وقت کے تصادم سے پاک شیڈول، باہمی معاہدہ اور آمد پر 4 ہندسوں کا سیکیورٹی پن۔',
      icon: Icons.calendar_month_rounded,
      tag: 'Zero Conflict',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;

    return Directionality(
      textDirection: LocalizationService.direction,
      child: Scaffold(
        backgroundColor: HomeEaseTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar with Language toggle and Skip button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Language Switcher
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          LocalizationService.toggleLanguage();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: HomeEaseTheme.outline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language_rounded, size: 14, color: HomeEaseTheme.brand),
                            const SizedBox(width: 6),
                            Text(
                              isUrdu ? 'English' : 'اردو',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: HomeEaseTheme.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onFinished,
                      child: Text(
                        isUrdu ? 'چھوڑیں' : 'Skip',
                        style: const TextStyle(
                          color: HomeEaseTheme.brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page Slider
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(28, 10, 28, 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: HomeEaseTheme.brand.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              slide.tag,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: HomeEaseTheme.brand,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: HomeEaseTheme.brand.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: HomeEaseTheme.brand.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              slide.icon,
                              size: 60,
                              color: HomeEaseTheme.brand,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            isUrdu ? slide.titleUrdu : slide.title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: HomeEaseTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isUrdu ? slide.descriptionUrdu : slide.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: HomeEaseTheme.textSecondary,
                                  height: 1.5,
                                  fontSize: 14,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Indicator and Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: _currentPage == index ? 24 : 6,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? HomeEaseTheme.brand : HomeEaseTheme.outline,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AnimatedScaleTap(
                      onTap: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          widget.onFinished();
                        }
                      },
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.brand,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: HomeEaseTheme.brand.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _currentPage == _slides.length - 1
                              ? (isUrdu ? 'شروع کریں' : 'Get Started')
                              : (isUrdu ? 'اگلا' : 'Continue'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
      ),
    );
  }
}

class OnboardData {
  final String title;
  final String titleUrdu;
  final String description;
  final String descriptionUrdu;
  final IconData icon;
  final String tag;

  OnboardData({
    required this.title,
    required this.titleUrdu,
    required this.description,
    required this.descriptionUrdu,
    required this.icon,
    required this.tag,
  });
}

