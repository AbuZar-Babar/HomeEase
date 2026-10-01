import 'package:flutter/material.dart';

/// Lightweight in-app bilingual localization engine for HomeEase.
/// Supports seamless switching between English and Urdu (`اردو`) with RTL awareness
/// and high-affordance visual icons for low-literacy domestic workers.
class LocalizationService {
  static const String langEnglish = 'en';
  static const String langUrdu = 'ur';

  // Active language code
  static String currentLanguage = langEnglish;

  static void setLanguage(String code) {
    if (code == langEnglish || code == langUrdu) {
      currentLanguage = code;
    }
  }

  static void toggleLanguage() {
    currentLanguage = (currentLanguage == langEnglish) ? langUrdu : langEnglish;
  }

  static bool get isUrdu => currentLanguage == langUrdu;
  static TextDirection get direction => isUrdu ? TextDirection.rtl : TextDirection.ltr;

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'HomeEase',
      'searchPlaceholder': 'Search by service, worker, or locality...',
      'findHelp': 'Find trusted domestic help',
      'findHelpSubtitle': 'Connect with verified cooks, cleaners, and nannies in Abbottabad',
      'aiRecommendations': 'AI Recommended for You',
      'aiMatch': 'AI Match',
      'postAJob': 'Post a Job / Request',
      'browseJobs': 'Browse Available Jobs',
      'allWorkers': 'All Workers Nearby',
      'viewAll': 'View all',
      'verified': 'Verified',
      'pending': 'Pending',
      'bookNow': 'Book Now',
      'applyNow': 'Apply Now',
      'experience': 'Experience',
      'availability': 'Availability',
      'hourlyRate': 'Rate',
      'reviews': 'reviews',
      'cleaning': 'Cleaning',
      'cooking': 'Cooking',
      'childcare': 'Childcare',
      'elderlyCare': 'Elderly Care',
      'maid': 'Maid',
      'myBookings': 'My Bookings',
      'notifications': 'Notifications',
      'serviceAgreement': 'Service Agreement',
      'payNow': 'Log Payment',
      'dispute': 'Report Dispute',
      'workerDashboard': 'Worker Dashboard',
      'incomingRequests': 'Incoming Requests',
      'availableJobsTitle': 'Open Household Gigs',
      'noJobsFound': 'No open gigs found right now.',
      'postGigTitle': 'Post a New Household Gig',
      'jobTitle': 'Job Title',
      'selectCategory': 'Select Category',
      'selectArea': 'Select Abbottabad Locality',
      'budget': 'Budget (PKR)',
      'submitPost': 'Publish Gig',
      'applySuccess': 'Application submitted successfully!',
      'postSuccess': 'Gig posted successfully!',
      'languageToggle': 'اردو',
      'currentLangBadge': 'EN',
    },
    'ur': {
      'appTitle': 'ہوم ایز',
      'searchPlaceholder': 'خدمت، ورکر یا محلہ تلاش کریں...',
      'findHelp': 'گھریلو ملازمین کی تلاش',
      'findHelpSubtitle': 'ایبٹ آباد میں تصدیق شدہ باورچی، صفائی والے اور آیا تلاش کریں',
      'aiRecommendations': 'آپ کے لیے اے آئی کی تجویز',
      'aiMatch': 'بہترین مطابقت',
      'postAJob': 'نیا کام / جاب پوسٹ کریں',
      'browseJobs': 'دستیاب کام دیکھیں',
      'allWorkers': 'قریبی تمام ورکرز',
      'viewAll': 'سب دیکھیں',
      'verified': 'تصدیق شدہ',
      'pending': 'زیرِ جائزہ',
      'bookNow': 'ابھی بک کریں',
      'applyNow': 'درخواست دیں',
      'experience': 'تجربہ',
      'availability': 'دستیابی',
      'hourlyRate': 'معاوضہ',
      'reviews': 'رائے',
      'cleaning': 'صفائی',
      'cooking': 'کھانا پکانا',
      'childcare': 'بچوں کی دیکھ بھال',
      'elderlyCare': 'بزرگوں کی نگہداشت',
      'maid': 'گھریلو ملازمہ',
      'myBookings': 'میری بکنگز',
      'notifications': 'اطلاعات',
      'serviceAgreement': 'باہمی معاہدہ',
      'payNow': 'ادائیگی کا اندراج',
      'dispute': 'شکایت درج کریں',
      'workerDashboard': 'ورکر ڈیش بورڈ',
      'incomingRequests': 'نئی بکنگ درخواستیں',
      'availableJobsTitle': 'گھروں کے دستیاب کام',
      'noJobsFound': 'اس وقت کوئی کام دستیاب نہیں ہے۔',
      'postGigTitle': 'نیا گھریلو کام شائع کریں',
      'jobTitle': 'کام کا عنوان',
      'selectCategory': 'شعبہ منتخب کریں',
      'selectArea': 'ایبٹ آباد کا علاقہ',
      'budget': 'مجوزہ بجٹ (روپے)',
      'submitPost': 'کام شائع کریں',
      'applySuccess': 'آپ کی درخواست کامیابی سے بھیج دی گئی!',
      'postSuccess': 'کام کامیابی سے پوسٹ ہو گیا!',
      'languageToggle': 'English',
      'currentLangBadge': 'اردو',
    },
  };

  /// Translate a string key into active language
  static String tr(String key) {
    final langDict = _localizedValues[currentLanguage] ?? _localizedValues[langEnglish]!;
    return langDict[key] ?? key;
  }

  /// High-affordance visual icons registry for domestic service categories
  static IconData getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('clean')) {
      return Icons.cleaning_services_rounded;
    } else if (cat.contains('cook')) {
      return Icons.restaurant_rounded;
    } else if (cat.contains('nanny') || cat.contains('child')) {
      return Icons.child_care_rounded;
    } else if (cat.contains('care') || cat.contains('elder')) {
      return Icons.elderly_rounded;
    } else {
      return Icons.home_repair_service_rounded;
    }
  }

  /// Color coding for domestic service categories
  static Color getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('clean')) {
      return const Color(0xFF0284C7); // Sky blue
    } else if (cat.contains('cook')) {
      return const Color(0xFF0F766E); // Teal
    } else if (cat.contains('nanny') || cat.contains('child')) {
      return const Color(0xFFD97706); // Amber
    } else if (cat.contains('care') || cat.contains('elder')) {
      return const Color(0xFF7C3AED); // Violet
    } else {
      return const Color(0xFF059669); // Emerald
    }
  }
}
