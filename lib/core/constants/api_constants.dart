import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static const String baseUrl = 'https://www.googleapis.com/youtube/v3';
  static String apiKey = 'AIzaSyACav8jtWn8zj8rhmpvA6vuZvM70utsXXk';

  static const String _apiKeyPrefKey = 'google_api_key';

  static Future<void> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_apiKeyPrefKey);
    if (savedKey != null && savedKey.isNotEmpty) {
      apiKey = savedKey;
    }
  }

  static Future<void> saveApiKey(String key) async {
    apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, key);
  }
}