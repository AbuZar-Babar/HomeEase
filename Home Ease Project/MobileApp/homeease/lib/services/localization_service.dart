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

      // R1: Marketplace Bidding & Proposal Pipeline
      'proposalsReceived': 'Proposals Received',
      'bidAmount': 'Bid: PKR',
      'acceptProposal': 'Accept',
      'noProposalsYet': 'No proposals received for this gig yet.',
      'chatWithApplicant': 'Chat with Applicant',

      // R2: In-App Chat Session Persistence
      'chatTitle': 'Direct Chat',
      'typeMessage': 'Type a message...',
      'voiceNote': 'Voice Note',
      'send': 'Send',
      'callWorker': 'Call Worker',
      'close': 'Close',
      'audioMessagingNote': 'Audio messaging is enabled for Abbottabad domestic workers.',
      'chatGreeting': 'Assalam-o-Alaikum! Thank you for choosing HomeEase. I am verified and ready to assist you.',
      'autoReplyAck': 'Understood! I have noted your message and will adhere to your schedule.',

      // R3: Service Agreement & Payment Integrity Enforcement
      'arrivalOtp': 'Arrival OTP',
      'arrivalOtpTitle': 'Arrival Verification OTP',
      'enterArrivalOtp': 'Enter 4-Digit Arrival OTP',
      'verifyArrival': 'Verify Arrival & Start',
      'settlePayment': 'Verify & Settle Payment',
      'viewAgreement': 'View Agreement',
      'otpMismatch': 'Invalid OTP. Please check with household.',
      'otpVerified': 'Arrival verified! Service is now in progress.',
      'shareOnArrival': 'Share on arrival',
      'arrivalInstructions': 'Share this 4-digit OTP with the worker upon arrival at your residence to verify identity and commence service.',

      // R4: Dynamic Worker Dashboard Earnings & Metrics
      'grossEarnings': 'Gross Earnings',
      'completedTasks': 'Completed Tasks',
      'averageYield': 'Average Yield',
      'performanceSummary': 'Performance & Earnings',
      'performanceAndGrossEarnings': 'Performance & Gross Earnings',

      // Milestone 1: Payment Gateway & Digital Receipt
      'paymentGatewayTitle': 'HomeEase Secure Payment Gateway',
      'paymentGatewaySubtitle': 'Choose your preferred Pakistani or global payment channel',
      'payViaGateway': 'Pay via Payment Gateway',
      'instantPaymentTitle': 'Instant Payment Gateway (Recommended)',
      'instantPaymentSubtitle': 'Settle instantly via Easypaisa, JazzCash, Stripe Card, or Cash on Delivery with HomeEase Escrow guarantee.',
      'easypaisaTitle': 'Easypaisa Mobile Wallet',
      'jazzcashTitle': 'JazzCash Mobile Wallet',
      'cardTitle': 'Debit / Credit Card (Stripe)',
      'codTitle': 'Cash on Delivery (COD)',
      'mobileNumber': 'Mobile Number (03XXXXXXXXX)',
      'easypaisaPin': '5-Digit PIN',
      'jazzcashMpin': '4-Digit MPIN',
      'cardNumber': '16-Digit Card Number',
      'expiryDate': 'MM/YY',
      'cvc': 'CVC',
      'ussdPushHeader': 'Easypaisa USSD Push Authorization',
      'ussdPushMessage': 'Enter PIN on your mobile to authorize payment of PKR {amount} to HomeEase Escrow',
      'jazzcashProcessing': 'Processing JazzCash Transaction...',
      'jazzcashProcessingSubtitle': 'Connecting to JazzCash Gateway & Verifying MPIN...',
      'secure3dHeader': '3D Secure 2.0 Verification',
      'secure3dSubtitle': 'Simulated Visa / Mastercard Bank Authentication',
      'secure3dMessage': 'HomeEase Escrow uses Stripe 3D Secure 2.0 to protect your transaction.',
      'codHeader': 'Mutual Cash Settlement',
      'codEscrowGuarantee': 'HomeEase Escrow guarantees customer satisfaction and dispute resolution for all cash bookings.',
      'codAcknowledgmentText': 'I acknowledge and agree to settle PKR {amount} in cash upon completion.',
      'confirmCod': 'Confirm Cash on Delivery',
      'digitalReceiptTitle': 'HomeEase Digital Receipt',
      'digitalReceiptSubtitle': 'Official Escrow Payment Confirmation',
      'receiptWatermark': 'PAID • VERIFIED ESCROW',
      'copyTxId': 'Copy TxID',
      'txIdCopied': 'Transaction ID copied to clipboard!',
      'viewReceipt': 'View Digital Receipt',
      'paymentConfirmedPill': 'Payment Status: Confirmed',
      'done': 'Done',
      'shareReceipt': 'Share Receipt',

      // Milestone 3: Responsive Admin Governance & Moderation Dashboard
      'adminDashboard': 'Admin Governance',
      'platformAnalytics': 'Platform Analytics',
      'workerVerificationDesk': 'Worker Verification Desk',
      'disputeResolutionDesk': 'Dispute Resolution Desk',
      'systemAuditLogs': 'System Audit Logs',
      'grossPkrVolume': 'Gross PKR Volume',
      'totalBookings': 'Total Bookings',
      'activeDisputes': 'Active Disputes',
      'verifiedWorkers': 'Verified Workers',
      'categoryDistribution': 'Category Distribution',
      'approveVerification': 'Approve Verification',
      'rejectVerification': 'Reject',
      'refundHousehold': 'Refund Household',
      'releaseToWorker': 'Release to Worker',
      'dismissDispute': 'Dismiss Dispute',
      'demoAdminLogin': 'Demo Admin Login',
      'adminRole': 'Admin',
      'abbottabadRegionalNode': 'Abbottabad Regional Node',
      'refresh': 'Refresh',
      'logout': 'Sign Out',
      'pendingTab': 'Pending',
      'verifiedTab': 'Verified',
      'allTab': 'All',
      'openTab': 'Open',
      'resolvedTab': 'Resolved',
      'dismissedTab': 'Dismissed',
      'noDisputesFound': 'No disputes found in this filter',
      'viewEvidence': 'View Evidence',
      'complainantLabel': 'Complainant',
      'respondentLabel': 'Respondent',
      'bookingLabel': 'Booking',
      'adjudicationRemarks': 'Adjudication remarks',
      'auditFilterAuth': 'Auth',
      'auditFilterVerification': 'Verification',
      'auditFilterDispute': 'Dispute',
      'auditFilterPayment': 'Payment',
      'noAuditLogsFound': 'No audit logs recorded for this category',
      'actorLabel': 'Actor',
      'requiresArbitration': 'Requires arbitration action',
      'administrator': 'Administrator',
      'homeEaseAdmin': 'HomeEase Admin',
      'noWorkersInQueue': 'No workers in this verification queue',
      'cnicNumber': 'CNIC Number',
      'evidencePhoto': 'Evidence Photo',
      'resolutionNotes': 'Resolution Notes',
      'viewIdDoc': 'View ID Document',
      'idScannedCopy': 'NADRA CNIC Scanned Copy Attached',
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

      // R1: Marketplace Bidding & Proposal Pipeline
      'proposalsReceived': 'موصولہ تجاویز',
      'bidAmount': 'مجوزہ ریٹ: روپے',
      'acceptProposal': 'قبول کریں',
      'noProposalsYet': 'اس جاب پر ابھی کوئی تجویز موصول نہیں ہوئی۔',
      'chatWithApplicant': 'امیدوار سے چیٹ کریں',

      // R2: In-App Chat Session Persistence
      'chatTitle': 'براہ راست بات چیت',
      'typeMessage': 'پیغام لکھیں...',
      'voiceNote': 'وائس میسج',
      'send': 'بھیجیں',
      'callWorker': 'کال کریں',
      'close': 'بند کریں',
      'audioMessagingNote': 'ایبٹ آباد کے گھریلو ورکرز کے لیے آڈیو پیغام رسانی فعال ہے۔',
      'chatGreeting': 'السلام علیکم! ہوم ایز منتخب کرنے کا شکریہ۔ میں تصدیق شدہ ہوں اور آپ کی مدد کے لیے تیار ہوں۔',
      'autoReplyAck': 'سمجھ گیا! میں نے آپ کا پیغام نوٹ کر لیا ہے اور شیڈول کے مطابق پہنچوں گا۔',

      // R3: Service Agreement & Payment Integrity Enforcement
      'arrivalOtp': 'آمد کا کوڈ (OTP)',
      'arrivalOtpTitle': 'آمد کی تصدیق کا OTP',
      'enterArrivalOtp': '4 ہندسوں کا کوڈ درج کریں',
      'verifyArrival': 'آمد کی تصدیق کریں',
      'settlePayment': 'معاہدہ اور ادائیگی',
      'viewAgreement': 'معاہدہ دیکھیں',
      'otpMismatch': 'غلط کوڈ۔ براہ کرم گھریلو صارف سے چیک کریں۔',
      'otpVerified': 'آمد کی تصدیق ہو گئی! سروس اب جاری ہے۔',
      'shareOnArrival': 'آمد پر ورکر کو بتائیں',
      'arrivalInstructions': 'جب ورکر آپ کے گھر پہنچے تو سروس شروع کرنے کے لیے یہ 4 ہندسوں کا کوڈ ورکر کے ساتھ شیئر کریں۔',

      // R4: Dynamic Worker Dashboard Earnings & Metrics
      'grossEarnings': 'کل آمدنی',
      'completedTasks': 'مکمل کام',
      'averageYield': 'اوسط فی کام',
      'performanceSummary': 'کارکردگی اور آمدنی',
      'performanceAndGrossEarnings': 'کارکردگی اور آمدنی کا خلاصہ',

      // Milestone 1: Payment Gateway & Digital Receipt
      'paymentGatewayTitle': 'ہوم ایز محفوظ پیمنٹ گیٹ وے',
      'paymentGatewaySubtitle': 'اپنا پسندیدہ پاکستانی یا بین الاقوامی ادائیگی کا طریقہ منتخب کریں',
      'payViaGateway': 'گیٹ وے سے ادائیگی کریں',
      'instantPaymentTitle': 'فوری پیمنٹ گیٹ وے (تجویز کردہ)',
      'instantPaymentSubtitle': 'ایزی پیسہ، جاز کیش، سٹرائپ کارڈ، یا کیش آن ڈیلیوری کے ذریعے فوری ادائیگی کریں ہوم ایز ایسکرو تحفظ کے ساتھ۔',
      'easypaisaTitle': 'ایزی پیسہ موبائل والٹ',
      'jazzcashTitle': 'جاز کیش موبائل والٹ',
      'cardTitle': 'ڈیبٹ / کریڈٹ کارڈ (سٹرائپ)',
      'codTitle': 'کیش آن ڈیلیوری',
      'mobileNumber': 'موبائل نمبر (03XXXXXXXXX)',
      'easypaisaPin': '5 ہندسوں کا پن کوڈ',
      'jazzcashMpin': '4 ہندسوں کا ایم پن',
      'cardNumber': '16 ہندسوں کا کارڈ نمبر',
      'expiryDate': 'مہینہ/سال',
      'cvc': 'سی وی سی',
      'ussdPushHeader': 'ایزی پیسہ یو ایس ایس ڈی پش تصدیق',
      'ussdPushMessage': 'ہوم ایز ایسکرو کو رقم ادا کرنے کے لیے اپنے موبائل پر پن درج کریں',
      'jazzcashProcessing': 'جاز کیش ٹرانزیکشن پروسیس ہو رہی ہے...',
      'jazzcashProcessingSubtitle': 'جاز کیش گیٹ وے سے رابطہ اور ایم پن کی تصدیق جاری ہے...',
      'secure3dHeader': 'تھری ڈی سیکیور 2.0 تصدیق',
      'secure3dSubtitle': 'ویزا / ماسٹر کارڈ بینک تصدیق',
      'secure3dMessage': 'ہوم ایز ایسکرو آپ کی ادائیگی کی حفاظت کے لیے سٹرائپ کا استعمال کرتا ہے۔',
      'codHeader': 'باہمی نقد ادائیگی',
      'codEscrowGuarantee': 'ہوم ایز ایسکرو کیش بکنگز پر کسٹمر کے اطمینان اور تنازعات کے حل کی ضمانت دیتا ہے۔',
      'codAcknowledgmentText': 'میں کام مکمل ہونے پر نقد رقم ادا کرنے کا اقرار کرتا ہوں۔',
      'confirmCod': 'کیش آن ڈیلیوری کی توثیق کریں',
      'digitalReceiptTitle': 'ہوم ایز ڈیجیٹل رسید',
      'digitalReceiptSubtitle': 'سرکاری ایسکرو ادائیگی کی رسید',
      'receiptWatermark': 'ادا شدہ • تصدیق شدہ ایسکرو',
      'copyTxId': 'آئی ڈی کاپی کریں',
      'txIdCopied': 'ٹرانزیکشن آئی ڈی کاپی ہو گئی!',
      'viewReceipt': 'ڈیجیٹل رسید دیکھیں',
      'paymentConfirmedPill': 'ادائیگی کی حیثیت: تصدیق شدہ',
      'done': 'مکمل',
      'shareReceipt': 'رسید شیئر کریں',

      // Milestone 3: Responsive Admin Governance & Moderation Dashboard
      'adminDashboard': 'ایڈمن کنٹرول پینل',
      'platformAnalytics': 'پلیٹ فارم کے اعداد و شمار',
      'workerVerificationDesk': 'ورکرز کی تصدیق کا ڈیسک',
      'disputeResolutionDesk': 'تنازعات کے حل کا ڈیسک',
      'systemAuditLogs': 'سسٹم آڈٹ لاگز',
      'grossPkrVolume': 'کل کاروباری حجم (روپے)',
      'totalBookings': 'کل بکنگز',
      'activeDisputes': 'زیرِ سماعت تنازعات',
      'verifiedWorkers': 'تصدیق شدہ ورکرز',
      'categoryDistribution': 'شعبہ جات کی تقسیم',
      'approveVerification': 'تصدیق منظور کریں',
      'rejectVerification': 'مسترد کریں',
      'refundHousehold': 'صارف کو رقم واپس کریں',
      'releaseToWorker': 'ورکر کو ادائیگی جاری کریں',
      'dismissDispute': 'شکایت خارج کریں',
      'demoAdminLogin': 'ڈیمو ایڈمن لاگ اِن',
      'adminRole': 'ایڈمن',
      'abbottabadRegionalNode': 'ایبٹ آباد ریجنل نوڈ',
      'refresh': 'تازہ کریں',
      'logout': 'لاگ آؤٹ',
      'pendingTab': 'زیرِ جائزہ',
      'verifiedTab': 'تصدیق شدہ',
      'allTab': 'تمام',
      'openTab': 'کھلی شکایات',
      'resolvedTab': 'حل شدہ',
      'dismissedTab': 'خارج شدہ',
      'noDisputesFound': 'اس فلٹر میں کوئی تنازعہ موجود نہیں',
      'viewEvidence': 'ثبوت دیکھیں',
      'complainantLabel': 'شکایت کنندہ',
      'respondentLabel': 'مدعا علیہ',
      'bookingLabel': 'بکنگ',
      'adjudicationRemarks': 'فیصلے کے ریمارکس',
      'auditFilterAuth': 'لاگ ان',
      'auditFilterVerification': 'تصدیق',
      'auditFilterDispute': 'تنازعات',
      'auditFilterPayment': 'ادائیگیاں',
      'noAuditLogsFound': 'اس زمرے میں کوئی آڈٹ لاگ درج نہیں ہے',
      'actorLabel': 'عمل کنندہ',
      'requiresArbitration': 'ثالثی کی کارروائی درکار ہے',
      'administrator': 'منتظم',
      'homeEaseAdmin': 'ہوم ایز ایڈمن',
      'noWorkersInQueue': 'کوئی درخواست زیرِ جائزہ نہیں ہے',
      'cnicNumber': 'شناختی کارڈ نمبر',
      'evidencePhoto': 'ثبوت کی تصویر',
      'resolutionNotes': 'تصفیہ کے ریمارکس',
      'viewIdDoc': 'شناختی دستاویز دیکھیں',
      'idScannedCopy': 'نادرا شناختی کارڈ کی کاپی منسلک ہے',
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
