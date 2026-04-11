import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static AppLocalizations of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(instance != null, 'AppLocalizations is missing in the widget tree.');
    return instance!;
  }

  bool get isArabic => locale.languageCode.toLowerCase() == 'ar';

  static const Map<String, String> _ar = <String, String>{
    'Change language': 'تغيير اللغة',
    'English': 'الإنجليزية',
    'Arabic': 'العربية',
    'Retry': 'إعادة المحاولة',
    '0.00': '0.00',
    '••••••••': '••••••••',
    'Home': 'الرئيسية',
    'Signals': 'الإشارات',
    'Market': 'السوق',
    'Referrals': 'الإحالات',
    'Profile': 'الملف الشخصي',
    'Dashboard': 'لوحة التحكم',
    'Active Signals': 'الإشارات النشطة',
    'Live Market': 'السوق المباشر',
    'Invite & VIP': 'الدعوات و VIP',
    'Account': 'الحساب',
    'Support link is not configured yet.': 'رابط الدعم غير مُعد بعد.',
    'Support link is invalid. Contact administrator.':
        'رابط الدعم غير صالح. تواصل مع الإدارة.',
    'Unable to open support link on this device.':
        'تعذر فتح رابط الدعم على هذا الجهاز.',
    'Could not load support link. Please try again.':
        'تعذر تحميل رابط الدعم. حاول مرة أخرى.',
    'Android app download is not configured yet.':
        'رابط تنزيل تطبيق أندرويد غير مُعد بعد.',
    'Android app download link is invalid. Contact administrator.':
        'رابط تنزيل تطبيق أندرويد غير صالح. تواصل مع الإدارة.',
    'Unable to open Android app download on this device.':
        'تعذر فتح تنزيل تطبيق أندرويد على هذا الجهاز.',
    'Could not load Android app download link. Please try again.':
        'تعذر تحميل رابط تنزيل تطبيق أندرويد. حاول مرة أخرى.',
    'GoldX': 'GoldX',
    'Welcome Back': 'مرحبًا بعودتك',
    'Enter your credentials to access your account.':
        'أدخل بياناتك للوصول إلى حسابك.',
    'EMAIL ADDRESS': 'البريد الإلكتروني',
    'name@company.com': 'name@company.com',
    'PASSWORD': 'كلمة المرور',
    'Forgot Password?': 'نسيت كلمة المرور؟',
    'Remember me': 'تذكرني',
    'Please enter email and password.':
        'يرجى إدخال البريد الإلكتروني وكلمة المرور.',
    'Login': 'تسجيل الدخول',
    "Don't have an account? Register": 'ليس لديك حساب؟ سجّل الآن',
    'Create Account': 'إنشاء حساب',
    'Join GoldX to access exclusive crypto trading signals.':
        'انضم إلى GoldX للوصول إلى إشارات تداول العملات الرقمية الحصرية.',
    'FULL NAME': 'الاسم الكامل',
    'Your full name': 'اسمك الكامل',
    'SECURE PASSWORD': 'كلمة مرور آمنة',
    'CONFIRM PASSWORD': 'تأكيد كلمة المرور',
    'INVITE CODE (REQUIRED)': 'رمز الدعوة (مطلوب)',
    'SIG-XXXX-XXXX': 'SIG-XXXX-XXXX',
    'I agree to the Terms of Service and Privacy Policy.':
        'أوافق على شروط الخدمة وسياسة الخصوصية.',
    'Already have an account? Login': 'لديك حساب بالفعل؟ سجّل الدخول',
    'Account Verification': 'التحقق من الحساب',
    'Upload your documents to activate dashboard access.':
        'ارفع مستنداتك لتفعيل الوصول إلى لوحة التحكم.',
    'Upload instructions': 'تعليمات الرفع',
    'Allowed formats: JPG, JPEG, PNG, WEBP.':
        'الصيغ المسموحة: JPG و JPEG و PNG و WEBP.',
    'Use images less than 2MB for best results (maximum 4MB per file).':
        'استخدم صورًا أقل من 2MB للحصول على أفضل نتيجة (الحد الأقصى 4MB لكل ملف).',
    'Status: {status}': 'الحالة: {status}',
    'Submitted for review': 'تم الإرسال للمراجعة',
    'ID DOCUMENT (PASSPORT / LICENSE)': 'مستند الهوية (جواز السفر / الرخصة)',
    'Upload clear front-side document image':
        'ارفع صورة واضحة للواجهة الأمامية للمستند',
    'SELFIE / USER PICTURE': 'صورة سيلفي / صورة المستخدم',
    'Upload a clear selfie or live face picture':
        'ارفع صورة سيلفي واضحة أو صورة مباشرة للوجه',
    'Submit Verification Documents': 'إرسال مستندات التحقق',
    'Refresh Status': 'تحديث الحالة',
    'Please upload both required documents.':
        'يرجى رفع كلا المستندين المطلوبين.',
    'Documents submitted successfully. Await admin review.':
        'تم إرسال المستندات بنجاح. بانتظار مراجعة الإدارة.',
    'Your verification request is under review.':
        'طلب التحقق الخاص بك قيد المراجعة.',
    'Rejection reason: {reason}': 'سبب الرفض: {reason}',
    'Please complete all required fields.': 'يرجى إكمال جميع الحقول المطلوبة.',
    'Name must be at least 2 characters.': 'يجب أن يكون الاسم حرفين على الأقل.',
    'Unable to connect to server. Please try again.':
        'تعذر الاتصال بالخادم. حاول مرة أخرى.',
    'Invalid email or password': 'البريد الإلكتروني أو كلمة المرور غير صالحة.',
    'Account is deactivated. Contact support.':
        'الحساب غير نشط. تواصل مع الدعم.',
    'Please enter a valid email address.': 'يرجى إدخال بريد إلكتروني صالح.',
    'Password must be at least 8 characters.':
        'يجب أن تكون كلمة المرور 8 أحرف على الأقل.',
    'Passwords do not match.': 'كلمتا المرور غير متطابقتين.',
    'Invite code is required.': 'رمز الدعوة مطلوب.',
    'Invite code is not available yet.': 'رمز الدعوة غير متاح بعد.',
    'Invite code copied to clipboard': 'تم نسخ رمز الدعوة إلى الحافظة',
    'Copy invite code': 'نسخ رمز الدعوة',
    'Please accept terms to continue.': 'يرجى قبول الشروط للمتابعة.',
    'Support': 'الدعم',
    'Deposit': 'إيداع',
    'Withdraw': 'سحب',
    'Market Snapshot': 'لمحة السوق',
    'LIVE': 'مباشر',
    'Recent Activity': 'النشاط الأخير',
    'Referrals: {count}': 'الإحالات: {count}',
    'Today, {time}': 'اليوم، {time}',
    'Deposit Request Submitted': 'تم إرسال طلب الإيداع',
    'Deposit Approved': 'تمت الموافقة على الإيداع',
    'Deposit Rejected': 'تم رفض الإيداع',
    'Withdrawal Request Submitted': 'تم إرسال طلب السحب',
    'Withdrawal Approved': 'تمت الموافقة على السحب',
    'Withdrawal Rejected': 'تم رفض السحب',
    'Signal Activated: {asset}': 'تم تفعيل الإشارة: {asset}',
    'Referral Rewarded: {user}': 'تمت مكافأة الإحالة: {user}',
    'Referral Qualified: {user}': 'تم تأهيل الإحالة: {user}',
    'Referral Joined: {user}': 'انضمّت إحالة جديدة: {user}',
    'Reference: {value}': 'المرجع: {value}',
    'Awaiting admin review': 'بانتظار مراجعة الإدارة',
    'Awaiting admin approval': 'بانتظار موافقة الإدارة',
    'Funds were credited to your wallet': 'تمت إضافة الأموال إلى محفظتك',
    'Funds were debited from your wallet': 'تم خصم الأموال من محفظتك',
    'Request was rejected by admin': 'تم رفض الطلب من الإدارة',
    'Target +{percent}% before expiry': 'الهدف +{percent}% قبل الانتهاء',
    'Referral bonus has been credited': 'تمت إضافة مكافأة الإحالة',
    'Deposit requirement completed': 'تم استيفاء شرط الإيداع',
    'Awaiting qualifying deposit': 'بانتظار إيداع التأهيل',
    'DEPOSIT': 'إيداع',
    'WITHDRAW': 'سحب',
    'REWARD': 'مكافأة',
    'QUALIFIED': 'مؤهل',
    'Unable to load dashboard data.': 'تعذر تحميل بيانات لوحة التحكم.',
    'Dashboard data is unavailable.': 'بيانات لوحة التحكم غير متاحة.',
    'Unable to load home dashboard': 'تعذر تحميل لوحة الصفحة الرئيسية',
    'No recent activity yet. Your latest deposits, withdrawals, signals, and referrals will appear here.':
        'لا يوجد نشاط حديث بعد. ستظهر هنا آخر عمليات الإيداع والسحب والإشارات والإحالات.',
    'TOTAL BALANCE': 'إجمالي الرصيد',
    "TODAY'S PROFIT": 'ربح اليوم',
    'VIP {level} Level': 'مستوى VIP {level}',
    'Market Alert: BTC above \$72k | New ETH signals live | Refer and earn rewards':
        'تنبيه السوق: BTC أعلى من \$72k | إشارات ETH جديدة مباشرة | ادعُ واربح مكافآت',
    'Live market feed disconnected. Reconnecting...':
        'تم فصل تغذية السوق المباشرة. جارٍ إعادة الاتصال...',
    'Trading Signals': 'إشارات التداول',
    'Showing Active Signals': 'عرض الإشارات النشطة',
    'Showing Past Signals History': 'عرض سجل الإشارات السابقة',
    'Past Signals': 'الإشارات السابقة',
    'Activation code is required': 'رمز التفعيل مطلوب',
    'Signal activated successfully.': 'تم تفعيل الإشارة بنجاح.',
    'Unable to activate signal. Please try again.':
        'تعذر تفعيل الإشارة. حاول مرة أخرى.',
    'Activate {asset}': 'تفعيل {asset}',
    'Enter your activation code to continue with {asset}.':
        'أدخل رمز التفعيل للمتابعة مع {asset}.',
    'Enter activation code': 'أدخل رمز التفعيل',
    'Continue': 'متابعة',
    'Cancel': 'إلغاء',
    'Validating...': 'جارٍ التحقق...',
    'No Active Signals': 'لا توجد إشارات نشطة',
    'No live signals are available right now. Pull to refresh.':
        'لا توجد إشارات مباشرة متاحة الآن. اسحب للتحديث.',
    'Failed to load active signals.': 'فشل تحميل الإشارات النشطة.',
    'Failed to load past signals.': 'فشل تحميل الإشارات السابقة.',
    'Showing cached signals. {message}': 'عرض إشارات مخزنة مؤقتًا. {message}',
    'Showing cached history. {message}': 'عرض سجل مخزن مؤقتًا. {message}',
    'Unable to load active signals': 'تعذر تحميل الإشارات النشطة',
    'Unable to load past signals': 'تعذر تحميل الإشارات السابقة',
    'No Signal History Yet': 'لا يوجد سجل إشارات بعد',
    'Activated signals will appear here once you participate.':
        'ستظهر الإشارات المفعلة هنا بمجرد مشاركتك.',
    'Refreshing active signals...': 'جارٍ تحديث الإشارات النشطة...',
    'Refreshing signal history...': 'جارٍ تحديث سجل الإشارات...',
    'Created {date}': 'تم الإنشاء {date}',
    'LIVE NOW': 'مباشر الآن',
    'Direction': 'الاتجاه',
    'Expected Profit': 'الربح المتوقع',
    'Duration': 'المدة',
    'Activate Signal': 'تفعيل الإشارة',
    'Already Activated': 'مفعّلة بالفعل',
    'Activation Unavailable': 'التفعيل غير متاح',
    'VIP Only': 'VIP فقط',
    'This signal is available for VIP users only':
        'هذه الإشارة متاحة لمستخدمي VIP فقط',
    'Entry Balance': 'رصيد الدخول',
    'Participation': 'المشاركة',
    'Profit Rate': 'معدل الربح',
    'Profit Earned': 'الربح المحقق',
    'Started': 'بدأ',
    'Completed': 'اكتمل',
    'Ended': 'انتهى',
    'Invite & Earn': 'ادعُ واربح',
    'Affiliate Portal': 'بوابة الإحالة',
    'Referral Progress': 'تقدم الإحالات',
    'Current VIP': 'مستوى VIP الحالي',
    'Team Profit Rate': 'معدل ربح الفريق',
    'VIP Levels': 'مستويات VIP',
    'Qualified Referrals': 'الإحالات المؤهلة',
    'Need {count} more qualified referrals for VIP {level}.':
        'تحتاج {count} إحالات مؤهلة إضافية للوصول إلى VIP {level}.',
    'Maximum VIP reached': 'تم الوصول إلى أعلى مستوى VIP',
    'Each referral qualifies after approved deposits reach {amount} USD.':
        'تتأهل كل إحالة بعد أن تصل الإيداعات المعتمدة إلى {amount} دولار.',
    'QUALIFIED {count}': 'مؤهل {count}',
    'Invite users and increase qualified deposits to unlock higher rewards.':
        'ادعُ مستخدمين وزِد الإيداعات المؤهلة لفتح مكافآت أعلى.',
    'Total Referrals': 'إجمالي الإحالات',
    'Earned': 'المكتسب',
    'Invite Code': 'رمز الدعوة',
    'Not available': 'غير متاح',
    'Invite Link': 'رابط الدعوة',
    'User #{id}': 'مستخدم #{id}',
    'No Referrals Yet': 'لا توجد إحالات بعد',
    'Share your invite code to start seeing referral activity.':
        'شارك رمز الدعوة الخاص بك لبدء ظهور نشاط الإحالات.',
    'Unable to load referrals': 'تعذر تحميل الإحالات',
    'No Data Found': 'لا توجد بيانات',
    'Referral information is unavailable right now.':
        'معلومات الإحالة غير متاحة الآن.',
    'Deposit History': 'سجل الإيداعات',
    'Track requests, approvals, and deposit details':
        'تابع الطلبات والموافقات وتفاصيل الإيداع',
    'Withdrawal History': 'سجل السحوبات',
    'Monitor payouts, status updates, and notes':
        'راقب المدفوعات وتحديثات الحالة والملاحظات',
    'Rewards & Team Profit History': 'سجل المكافآت وأرباح الفريق',
    'View reward credits, types, and timestamps':
        'عرض أرصدة المكافآت والأنواع والطوابع الزمنية',
    'Withdrawal Password': 'كلمة مرور السحب',
    'Login Password': 'كلمة مرور تسجيل الدخول',
    'Configured': 'مُعَدَّة',
    'Not configured': 'غير مُعَدَّة',
    'Change your account login password securely':
        'غيّر كلمة مرور تسجيل الدخول لحسابك بأمان',
    'Customer Support': 'دعم العملاء',
    'Open external support link': 'فتح رابط دعم خارجي',
    'About Us': 'من نحن',
    'Company profile, PDFs, and certificate': 'نبذة الشركة وملفات PDF والشهادة',
    'GoldX Company Profile': 'ملف تعريف شركة GoldX',
    'Explore our official introduction, brand statement, and training certificate.':
        'استعرض مقدمتنا الرسمية وبيان العلامة التجارية وشهادة التدريب.',
    'Certificate': 'الشهادة',
    'Professional training completion certificate': 'شهادة إكمال تدريب احترافي',
    'Certificate image could not be loaded.': 'تعذر تحميل صورة الشهادة.',
    'GoldX Official Introduction': 'المقدمة الرسمية لـ GoldX',
    'Official overview document': 'مستند نظرة عامة رسمية',
    'GoldX Colored Statement': 'البيان الملون لـ GoldX',
    'Brand statement document': 'مستند بيان العلامة التجارية',
    'Open PDF': 'فتح PDF',
    'PDF could not be loaded.': 'تعذر تحميل ملف PDF.',
    'Download Android App': 'تنزيل تطبيق أندرويد',
    'Download latest GoldX APK': 'تنزيل أحدث ملف APK لتطبيق GoldX',
    'Logout': 'تسجيل الخروج',
    'End active sessions': 'إنهاء الجلسات النشطة',
    'No Profile Data Found': 'لم يتم العثور على بيانات الملف الشخصي',
    'Please refresh or login again to load your profile.':
        'يرجى التحديث أو تسجيل الدخول مرة أخرى لتحميل ملفك الشخصي.',
    'GoldX User': 'مستخدم GoldX',
    'VIP {level}': 'VIP {level}',
    'Active': 'نشط',
    'Inactive': 'غير نشط',
    'Joined {date}': 'انضم في {date}',
    'ACCOUNT': 'الحساب',
    'SUPPORT': 'الدعم',
    'Unable to load profile.': 'تعذر تحميل الملف الشخصي.',
    'Unable to load profile': 'تعذر تحميل الملف الشخصي',
    'Deposit Funds': 'إيداع الأموال',
    'CURRENT BALANCE': 'الرصيد الحالي',
    'Pending Deposits': 'إيداعات قيد الانتظار',
    'Pending Withdrawals': 'سحوبات قيد الانتظار',
    'Deposit Amount': 'مبلغ الإيداع',
    'Quick Amounts': 'مبالغ سريعة',
    'Transaction Reference (Optional)': 'مرجع المعاملة (اختياري)',
    'Enter transaction ID if available': 'أدخل رقم المعاملة إذا كان متاحًا',
    'PAYMENT PROOF': 'إثبات الدفع',
    'Upload a screenshot of your payment transaction.':
        'ارفع لقطة شاشة لعملية الدفع الخاصة بك.',
    'Selected file: {name}': 'الملف المحدد: {name}',
    'Selecting...': 'جارٍ الاختيار...',
    'Upload Screenshot': 'رفع لقطة شاشة',
    'Change Screenshot': 'تغيير لقطة الشاشة',
    'Deposit {walletTitle}': 'إيداع {walletTitle}',
    'WALLET ADDRESS': 'عنوان المحفظة',
    'Wallet address not configured yet.': 'عنوان المحفظة غير مُعَد بعد.',
    'Wallet address is not configured yet.': 'عنوان المحفظة غير مُعَد بعد.',
    'Wallet address copied to clipboard': 'تم نسخ عنوان المحفظة إلى الحافظة',
    'Deposits are queued for admin approval. Add transaction reference to speed up verification.':
        'تُدرج الإيداعات في قائمة انتظار موافقة الإدارة. أضف مرجع المعاملة لتسريع التحقق.',
    'Submit Deposit Request': 'إرسال طلب الإيداع',
    'Submitting...': 'جارٍ الإرسال...',
    'Please enter a valid deposit amount': 'يرجى إدخال مبلغ إيداع صالح',
    'Please upload payment proof screenshot': 'يرجى رفع لقطة إثبات الدفع',
    'Deposit request #{id} submitted successfully for review.':
        'تم إرسال طلب الإيداع رقم #{id} بنجاح للمراجعة.',
    'Screenshot selection cancelled': 'تم إلغاء اختيار لقطة الشاشة',
    'Payment proof selected': 'تم اختيار إثبات الدفع',
    'DEPOSIT ANALYTICS': 'تحليلات الإيداع',
    'Deposit & Referral Reward Rules': 'قواعد مكافآت الإيداع والإحالة',
    'Standard deposit reward: 6% (example: \$500 -> \$30, \$1000 -> \$60, \$2000 -> \$120).':
        'مكافأة الإيداع القياسية: 6% (مثال: \$500 -> \$30، \$1000 -> \$60، \$2000 -> \$120).',
    'If the deposit is from an invited user: inviter gets 6%, invited user gets 3%.':
        'إذا كان الإيداع من مستخدم مدعو: يحصل المُحيل على 6% ويحصل المستخدم المدعو على 3%.',
    'Total requested volume for this filter': 'إجمالي حجم الطلبات لهذا الفلتر',
    'All': 'الكل',
    'Approved': 'مقبول',
    'Rejected': 'مرفوض',
    'Pending': 'قيد الانتظار',
    'Unknown': 'غير معروف',
    'No Deposit Records': 'لا توجد سجلات إيداع',
    'Your deposit requests and approvals will appear here.':
        'ستظهر طلبات الإيداع والموافقات هنا.',
    'Deposit Request': 'طلب إيداع',
    'Ref: {value}': 'المرجع: {value}',
    'Ref: Not provided': 'المرجع: غير متوفر',
    'ID: {id}': 'المعرّف: {id}',
    'Unable to load deposit history.': 'تعذر تحميل سجل الإيداعات.',
    'Unable to load deposits': 'تعذر تحميل الإيداعات',
    'Deposit Details': 'تفاصيل الإيداع',
    'Unable to load deposit details.': 'تعذر تحميل تفاصيل الإيداع.',
    'No details found.': 'لم يتم العثور على تفاصيل.',
    'Showing the latest cached details. Pull to refresh again.':
        'يتم عرض آخر تفاصيل مخزنة مؤقتًا. اسحب للتحديث مجددًا.',
    'Deposit Transaction': 'معاملة إيداع',
    'Submitted {date}': 'تم الإرسال {date}',
    'DETAILS': 'التفاصيل',
    'Deposit ID': 'معرّف الإيداع',
    'Requested At': 'وقت الطلب',
    'Last Updated': 'آخر تحديث',
    'Pending review': 'قيد المراجعة',
    'Type': 'النوع',
    'Type: {value}': 'النوع: {value}',
    'Date & Time: {value}': 'التاريخ والوقت: {value}',
    'Transaction ID': 'رقم المعاملة',
    'Not provided': 'غير متوفر',
    'Self Reward': 'مكافأة المستخدم',
    'Referrer Reward': 'مكافأة المُحيل',
    'Rewards: +{value}': 'المكافآت: +{value}',
    'Admin Note': 'ملاحظة الإدارة',
    'No admin note yet': 'لا توجد ملاحظة من الإدارة بعد',
    'Unable to load proof image': 'تعذر تحميل صورة الإثبات',
    'Unable to load details': 'تعذر تحميل التفاصيل',
    'This deposit has been approved and should be reflected in your wallet balance.':
        'تمت الموافقة على هذا الإيداع ويجب أن ينعكس في رصيد محفظتك.',
    'This deposit was rejected by admin. Check the admin note for context and resubmit if needed.':
        'تم رفض هذا الإيداع من الإدارة. راجع ملاحظة الإدارة ثم أعد الإرسال عند الحاجة.',
    'Your deposit request is under review. Approval usually depends on payment proof validation.':
        'طلب الإيداع قيد المراجعة. تعتمد الموافقة عادة على التحقق من إثبات الدفع.',
    'Status is currently unavailable for this record.':
        'الحالة غير متاحة حاليًا لهذا السجل.',
    'Withdraw Funds': 'سحب الأموال',
    'AVAILABLE LIQUIDITY': 'السيولة المتاحة',
    'WITHDRAWABLE BALANCE': 'الرصيد القابل للسحب',
    'Total Balance: {amount}': 'إجمالي الرصيد: {amount}',
    'WITHDRAWABLE NOW': 'القابل للسحب الآن',
    'Capital': 'رأس المال',
    'Signal Profits': 'أرباح الإشارات',
    'Team Rewards': 'مكافآت الفريق',
    'Requested amount exceeds your withdrawable balance.':
        'المبلغ المطلوب يتجاوز الرصيد القابل للسحب.',
    'Requested Amount': 'المبلغ المطلوب',
    'Withdrawal Fee ({percent}%)': 'رسوم السحب ({percent}%)',
    'Fee: -{value}': 'الرسوم: -{value}',
    'Fee Rate': 'معدل الرسوم',
    'Fee Amount': 'مبلغ الرسوم',
    'Net Payout': 'الصافي المصروف',
    'Net Payout: {value}': 'الصافي المصروف: {value}',
    '10% withdrawal fee will be deducted from any withdrawal':
        'سيتم خصم رسوم سحب بنسبة 10% من أي عملية سحب',
    'Withdrawal request submitted. Net payout {amount} after 10% fee.':
        'تم إرسال طلب السحب. الصافي المصروف {amount} بعد خصم رسوم 10%.',
    'First capital deposit lock: {amount} remains locked for {days} day(s), until {date}.':
        'قفل أول إيداع رأس مال: يبقى {amount} مقفلاً لمدة {days} يوم/أيام حتى {date}.',
    'Initial capital lock active: {amount} locked for {days} day(s) until {date}.':
        'قفل رأس المال الأول نشط: تم قفل {amount} لمدة {days} يوم/أيام حتى {date}.',
    'Capital from your first approved deposit is locked for 12 days. Signal profits and team rewards remain withdrawable.':
        'يُقفل رأس المال من أول إيداع مُعتمد لمدة 12 يومًا. تبقى أرباح الإشارات ومكافآت الفريق قابلة للسحب.',
    'WITHDRAWAL AMOUNT': 'مبلغ السحب',
    'DESTINATION ADDRESS / IBAN': 'عنوان الوجهة / IBAN',
    'Enter wallet or bank details': 'أدخل تفاصيل المحفظة أو البنك',
    'WITHDRAWAL PASSWORD': 'كلمة مرور السحب',
    'Enter your withdrawal password': 'أدخل كلمة مرور السحب الخاصة بك',
    'Withdrawal requests are reviewed by admin. Make sure your destination details are correct.':
        'تتم مراجعة طلبات السحب من الإدارة. تأكد من صحة تفاصيل الوجهة.',
    'Processing...': 'جارٍ المعالجة...',
    'Loading wallet...': 'جارٍ تحميل المحفظة...',
    'Request Withdrawal': 'طلب سحب',
    'Please enter a valid withdrawal amount.': 'يرجى إدخال مبلغ سحب صالح.',
    'Withdrawal password is required.': 'كلمة مرور السحب مطلوبة.',
    'Withdrawal request submitted successfully.': 'تم إرسال طلب السحب بنجاح.',
    'Withdrawal Details': 'تفاصيل السحب',
    'Unable to load withdrawal details.': 'تعذر تحميل تفاصيل السحب.',
    'Withdrawal Transaction': 'معاملة سحب',
    'Withdrawal ID': 'معرّف السحب',
    'Destination': 'الوجهة',
    'This withdrawal has been approved and processed by admin.':
        'تمت الموافقة على هذا السحب ومعالجته من الإدارة.',
    'This withdrawal was rejected. Review the admin note and verify destination details before retrying.':
        'تم رفض هذا السحب. راجع ملاحظة الإدارة وتحقق من تفاصيل الوجهة قبل إعادة المحاولة.',
    'Your withdrawal is pending admin review. Processing times can vary based on queue volume.':
        'طلب السحب قيد مراجعة الإدارة. قد يختلف وقت المعالجة حسب حجم قائمة الانتظار.',
    'Unable to load withdrawal history.': 'تعذر تحميل سجل السحوبات.',
    'REWARDS ANALYTICS': 'تحليلات المكافآت',
    'Total rewards and team profit credits':
        'إجمالي أرصدة المكافآت وأرباح الفريق',
    'No Rewards Records': 'لا توجد سجلات مكافآت',
    'Reward and team profit transactions will appear here.':
        'ستظهر هنا معاملات المكافآت وأرباح الفريق.',
    'Unable to load rewards history.': 'تعذر تحميل سجل المكافآت.',
    'Unable to load rewards history': 'تعذر تحميل سجل المكافآت',
    'Team Profit Credit': 'قيد ربح الفريق',
    'Deposit Reward Credit': 'قيد مكافأة الإيداع',
    'Referral Reward Credit': 'قيد مكافأة الإحالة',
    'Reward Credit': 'قيد مكافأة',
    'No Withdrawal Records': 'لا توجد سجلات سحب',
    'Your submitted and processed withdrawals will appear here.':
        'ستظهر هنا عمليات السحب المرسلة والمعالجة.',
    'WITHDRAWAL ANALYTICS': 'تحليلات السحب',
    'Total withdrawal volume for this filter': 'إجمالي حجم السحب لهذا الفلتر',
    'Withdrawal Request': 'طلب سحب',
    'Destination: {value}': 'الوجهة: {value}',
    'Destination: Not provided': 'الوجهة: غير متوفرة',
    'Unable to load withdrawals': 'تعذر تحميل السحوبات',
    'Set Withdrawal Password': 'تعيين كلمة مرور السحب',
    'Update Withdrawal Password': 'تحديث كلمة مرور السحب',
    'Change Login Password': 'تغيير كلمة مرور تسجيل الدخول',
    'Update Login Password': 'تحديث كلمة مرور تسجيل الدخول',
    'Updating Login Password...': 'جارٍ تحديث كلمة مرور تسجيل الدخول...',
    'CURRENT LOGIN PASSWORD': 'كلمة مرور تسجيل الدخول الحالية',
    'NEW LOGIN PASSWORD': 'كلمة مرور تسجيل الدخول الجديدة',
    'CONFIRM NEW LOGIN PASSWORD': 'تأكيد كلمة مرور تسجيل الدخول الجديدة',
    'Enter your current login password': 'أدخل كلمة مرور تسجيل الدخول الحالية',
    'Enter a new login password': 'أدخل كلمة مرور تسجيل دخول جديدة',
    'Re-enter new login password': 'أعد إدخال كلمة مرور تسجيل الدخول الجديدة',
    'Please enter your current login password.':
        'يرجى إدخال كلمة مرور تسجيل الدخول الحالية.',
    'Please enter a new login password.':
        'يرجى إدخال كلمة مرور تسجيل دخول جديدة.',
    'Login password must be at least 8 characters.':
        'يجب أن تكون كلمة مرور تسجيل الدخول 8 أحرف على الأقل.',
    'New login password must be different from current password.':
        'يجب أن تختلف كلمة مرور تسجيل الدخول الجديدة عن الحالية.',
    'New login password and confirmation do not match.':
        'كلمة مرور تسجيل الدخول الجديدة والتأكيد غير متطابقين.',
    'Login password updated successfully.':
        'تم تحديث كلمة مرور تسجيل الدخول بنجاح.',
    'Your login password protects account access. Verify your current password before setting a new one.':
        'كلمة مرور تسجيل الدخول تحمي الوصول إلى الحساب. تحقّق من كلمة المرور الحالية قبل تعيين كلمة جديدة.',
    'Use at least 8 characters with letters and numbers.':
        'استخدم 8 أحرف على الأقل مع حروف وأرقام.',
    'Do not share your password with anyone.': 'لا تشارك كلمة مرورك مع أي شخص.',
    'You may be asked to login again on other devices after changing it.':
        'قد يُطلب منك تسجيل الدخول مرة أخرى على الأجهزة الأخرى بعد تغييرها.',
    'SECURITY STATUS': 'حالة الأمان',
    'Your account is protected. Enter current password to update it.':
        'حسابك محمي. أدخل كلمة المرور الحالية لتحديثها.',
    'No withdrawal password set yet. Create one to secure withdrawals.':
        'لم يتم تعيين كلمة مرور للسحب بعد. أنشئ واحدة لتأمين السحوبات.',
    'CURRENT WITHDRAWAL PASSWORD': 'كلمة مرور السحب الحالية',
    'Enter current password': 'أدخل كلمة المرور الحالية',
    'NEW WITHDRAWAL PASSWORD': 'كلمة مرور السحب الجديدة',
    'Enter at least 6 characters': 'أدخل 6 أحرف على الأقل',
    'CONFIRM NEW PASSWORD': 'تأكيد كلمة المرور الجديدة',
    'Re-enter new password': 'أعد إدخال كلمة المرور الجديدة',
    'Use at least 6 characters.': 'استخدم 6 أحرف على الأقل.',
    'Do not reuse your login password.':
        'لا تستخدم كلمة مرور تسجيل الدخول نفسها.',
    'You will need this password for every withdrawal request.':
        'ستحتاج هذه الكلمة لكل طلب سحب.',
    'Updating Password...': 'جارٍ تحديث كلمة المرور...',
    'Setting Password...': 'جارٍ تعيين كلمة المرور...',
    'Please enter your current withdrawal password.':
        'يرجى إدخال كلمة مرور السحب الحالية.',
    'Please enter a new withdrawal password.':
        'يرجى إدخال كلمة مرور سحب جديدة.',
    'Withdrawal password must be at least 6 characters.':
        'يجب أن تكون كلمة مرور السحب 6 أحرف على الأقل.',
    'New password and confirmation do not match.':
        'كلمة المرور الجديدة والتأكيد غير متطابقين.',
    'Withdrawal password updated successfully.':
        'تم تحديث كلمة مرور السحب بنجاح.',
    'Withdrawal password set successfully.': 'تم تعيين كلمة مرور السحب بنجاح.',
    'Notifications': 'الإشعارات',
    'Unable to load notifications right now.': 'تعذر تحميل الإشعارات الآن.',
    'No Notifications Yet': 'لا توجد إشعارات بعد',
    'Admin updates and alerts will appear here.':
        'ستظهر تحديثات الإدارة والتنبيهات هنا.',
    'Admin Notification Center': 'مركز إشعارات الإدارة',
    'All unseen messages are automatically marked as read.':
        'يتم تعليم جميع الرسائل غير المقروءة كمقروءة تلقائيًا.',
    'SIGNAL': 'إشارة',
    'REFERRAL': 'إحالة',
    'SYSTEM': 'نظام',
    'Unable to load notifications': 'تعذر تحميل الإشعارات',
    'Follow Signal': 'متابعة الإشارة',
    'Enter a signal code from your analyst or GoldX channel. Valid examples look like SIG-X922.':
        'أدخل رمز إشارة من المحلل الخاص بك أو قناة GoldX. أمثلة صالحة مثل SIG-X922.',
    'SIG-XXXX': 'SIG-XXXX',
    'Checking signal integrity and market lock...':
        'جارٍ التحقق من سلامة الإشارة وقفل السوق...',
    'Signal activated successfully. Position is now tracking real-time updates.':
        'تم تفعيل الإشارة بنجاح. أصبح المركز الآن يتابع التحديثات المباشرة.',
    'Invalid code. Please verify with your analyst and try again.':
        'رمز غير صالح. يرجى التحقق مع المحلل والمحاولة مرة أخرى.',
    'SECURELY CONNECTING TO SIGNALPRO...': 'جارٍ الاتصال الآمن بـ SIGNALPRO...',
    'ENCRYPTED': 'مشفّر',
    'LIVE SYNC': 'مزامنة مباشرة',
    'Candlestick Chart': 'مخطط الشموع',
    'Live Prices': 'الأسعار المباشرة',
    'Today': 'اليوم',
    'No chart data available for the selected coin.':
        'لا تتوفر بيانات مخطط للعملة المحددة.',
    'Unable to load historical candles. Please try again.':
        'تعذر تحميل بيانات الشموع التاريخية. حاول مرة أخرى.',
    'Live candle stream disconnected. Reconnecting...':
        'تم فصل بث الشموع المباشر. جارٍ إعادة الاتصال...',
    'Live price stream disconnected. Reconnecting...':
        'تم فصل بث الأسعار المباشر. جارٍ إعادة الاتصال...',
    'No candle data received for {symbol} ({interval}).':
        'لم يتم استلام بيانات شموع لـ {symbol} ({interval}).',
    'Latest {interval} candle closed': 'أُغلقت آخر شمعة {interval}',
    'Current {interval} candle is forming with live updates':
        'شمعة {interval} الحالية قيد التكوين مع تحديثات مباشرة',
    "Waiting for today's change...": 'بانتظار تغيير اليوم...',
    '\u00A9 {year} GoldX. All rights reserved.':
        '© {year} GoldX. جميع الحقوق محفوظة.',
  };

  String tr(String key, {Map<String, String> params = const {}}) {
    var value = isArabic ? (_ar[key] ?? key) : key;
    params.forEach((placeholder, replacement) {
      value = value.replaceAll('{$placeholder}', replacement);
    });
    return value;
  }

  String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return tr('Approved');
      case 'rejected':
        return tr('Rejected');
      case 'pending':
        return tr('Pending');
      default:
        return tr('Unknown');
    }
  }

  String notificationTypeLabel(String type) {
    switch (type) {
      case 'signal':
        return tr('SIGNAL');
      case 'referral':
        return tr('REFERRAL');
      case 'support':
        return tr('SUPPORT');
      default:
        return tr('SYSTEM');
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (item) => item.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future<AppLocalizations>.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
