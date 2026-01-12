import 'package:shared_preferences/shared_preferences.dart';

/// Local storage for app settings (server URL, etc.)
class LocalStorage {
  static const String _keyServerUrl = 'server_url';
  
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  /// Get saved server URL
  String? getServerUrl() => _prefs.getString(_keyServerUrl);

  /// Save server URL
  Future<bool> saveServerUrl(String url) => _prefs.setString(_keyServerUrl, url);

  /// Clear server URL
  Future<bool> clearServerUrl() => _prefs.remove(_keyServerUrl);

  /// Check if server is configured
  bool get isServerConfigured => getServerUrl()?.isNotEmpty ?? false;
}
