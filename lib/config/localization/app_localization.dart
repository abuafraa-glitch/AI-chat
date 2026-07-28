import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AppLocalization {
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  static const List<LocalizationsDelegate> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}

// Mock localization strings for now
class Strings {
  // Navigation
  static const String home = 'Home';
  static const String chat = 'Chat';
  static const String conversations = 'Conversations';
  static const String settings = 'Settings';
  static const String subscribe = 'Subscribe';
  
  // Home Screen
  static const String welcome = 'Welcome to Hajeen AI';
  static const String askAnything = 'Ask Anything';
  static const String writeCode = 'Write Code';
  static const String analyzeFile = 'Analyze File';
  static const String translate = 'Translate';
  static const String summarize = 'Summarize';
  static const String suggestIdeas = 'Suggest Ideas';
  
  // Chat Actions
  static const String copy = 'Copy';
  static const String regenerate = 'Regenerate';
  static const String edit = 'Edit';
  static const String like = 'Like';
  static const String unlike = 'Unlike';
  static const String share = 'Share';
  static const String pin = 'Pin';
  static const String unpin = 'Unpin';
  
  // Model Selection
  static const String selectModel = 'Select Model';
  static const String available = 'Available';
  static const String unavailable = 'Unavailable';
  
  // Thinking Status
  static const String thinking = 'Thinking';
  static const String analyzing = 'Analyzing Request';
  static const String generating = 'Generating Response';
  
  // File Upload
  static const String attachFile = 'Attach File';
  static const String uploadImage = 'Upload Image';
  static const String recordAudio = 'Record Audio';
  static const String supportedFormats = 'Supported Formats';
  
  // Subscription
  static const String freeLimit = 'Free Limit Reached';
  static const String upgradeNow = 'Upgrade Now';
  static const String free = 'Free';
  static const String pro = 'Pro';
  static const String business = 'Business';
  static const String currentPlan = 'Current Plan';
  static const String subscribe_now = 'Subscribe Now';
  
  // Settings
  static const String account = 'Account';
  static const String language = 'Language';
  static const String theme = 'Theme';
  static const String notifications = 'Notifications';
  static const String privacy = 'Privacy';
  static const String deleteAccount = 'Delete Account';
  static const String logout = 'Logout';
  
  // Conversation Management
  static const String newChat = 'New Chat';
  static const String search = 'Search';
  static const String archive = 'Archive';
  static const String delete = 'Delete';
  static const String rename = 'Rename';
  static const String pin_conversation = 'Pin Conversation';
  static const String unpin_conversation = 'Unpin Conversation';
  
  // Messages
  static const String errorOccurred = 'Error Occurred';
  static const String tryAgain = 'Try Again';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String loading = 'Loading';
  static const String noData = 'No Data';
  static const String noInternet = 'No Internet Connection';
}

class ArabicStrings {
  // Navigation
  static const String home = 'الرئيسية';
  static const String chat = 'الدردشة';
  static const String conversations = 'المحادثات';
  static const String settings = 'الإعدادات';
  static const String subscribe = 'الاشتراك';
  
  // Home Screen
  static const String welcome = 'أهلاً في Hajeen AI';
  static const String askAnything = 'اسأل أي شيء';
  static const String writeCode = 'اكتب كوداً';
  static const String analyzeFile = 'حلل ملفاً';
  static const String translate = 'ترجم';
  static const String summarize = 'لخّص';
  static const String suggestIdeas = 'اقترح أفكاراً';
  
  // Chat Actions
  static const String copy = 'نسخ';
  static const String regenerate = 'إعادة التوليد';
  static const String edit = 'تعديل';
  static const String like = 'إعجاب';
  static const String unlike = 'عدم الإعجاب';
  static const String share = 'مشاركة';
  static const String pin = 'تثبيت';
  static const String unpin = 'إلغاء التثبيت';
  
  // Model Selection
  static const String selectModel = 'اختر النموذج';
  static const String available = 'متاح';
  static const String unavailable = 'غير متاح';
  
  // Thinking Status
  static const String thinking = 'جاري التفكير';
  static const String analyzing = 'جاري تحليل الطلب';
  static const String generating = 'جاري توليد الإجابة';
  
  // File Upload
  static const String attachFile = 'إرفاق ملف';
  static const String uploadImage = 'تحميل صورة';
  static const String recordAudio = 'تسجيل صوت';
  static const String supportedFormats = 'الصيغ المدعومة';
  
  // Subscription
  static const String freeLimit = 'لقد استهلكت الحد المجاني';
  static const String upgradeNow = 'الترقية الآن';
  static const String free = 'مجاني';
  static const String pro = 'احترافي';
  static const String business = 'أعمال';
  static const String currentPlan = 'الخطة الحالية';
  static const String subscribe_now = 'اشترك الآن';
  
  // Settings
  static const String account = 'الحساب';
  static const String language = 'اللغة';
  static const String theme = 'المظهر';
  static const String notifications = 'الإشعارات';
  static const String privacy = 'الخصوصية';
  static const String deleteAccount = 'حذف الحساب';
  static const String logout = 'تسجيل الخروج';
  
  // Conversation Management
  static const String newChat = 'دردشة جديدة';
  static const String search = 'بحث';
  static const String archive = 'أرشفة';
  static const String delete = 'حذف';
  static const String rename = 'إعادة التسمية';
  static const String pin_conversation = 'تثبيت المحادثة';
  static const String unpin_conversation = 'إلغاء تثبيت المحادثة';
  
  // Messages
  static const String errorOccurred = 'حدث خطأ';
  static const String tryAgain = 'حاول مرة أخرى';
  static const String cancel = 'إلغاء';
  static const String confirm = 'تأكيد';
  static const String yes = 'نعم';
  static const String no = 'لا';
  static const String loading = 'جاري التحميل';
  static const String noData = 'لا توجد بيانات';
  static const String noInternet = 'لا توجد اتصالية إنترنت';
}
