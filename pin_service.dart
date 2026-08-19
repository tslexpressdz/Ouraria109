import 'package:shared_preferences/shared_preferences.dart';

/// حماية بسيطة برمز PIN مكوّن من 4 أرقام، يُخزَّن محلياً على الهاتف
/// (SharedPreferences). هذه حماية أساسية لمنع فتح التطبيق عرضياً من قِبل
/// شخص آخر يمسك الهاتف — وليست تشفيراً عالي الأمان لبيانات حساسة جداً.
class PinService {
  static const _pinKey = 'app_pin_code';

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_pinKey);
    return pin != null && pin.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  static Future<bool> checkPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_pinKey);
    return saved != null && saved == pin;
  }

  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }
}
