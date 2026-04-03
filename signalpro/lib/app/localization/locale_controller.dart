import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleController extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> initialize() async {
    final storedCode = await _storage.read(key: _localeKey);
    if (storedCode == 'ar' || storedCode == 'en') {
      _locale = Locale(storedCode!);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode.toLowerCase();
    if (code != 'en' && code != 'ar') {
      return;
    }

    if (_locale.languageCode == code) {
      return;
    }

    _locale = Locale(code);
    await _storage.write(key: _localeKey, value: code);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    await setLocale(isArabic ? const Locale('en') : const Locale('ar'));
  }
}
