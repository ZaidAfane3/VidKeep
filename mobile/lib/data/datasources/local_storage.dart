import 'package:shared_preferences/shared_preferences.dart';

/// Local storage for app settings (server URL, etc.)
class LocalStorage {
  static const String _keyServerUrl = 'server_url';
  static const String _keyDisableSslVerify = 'disable_ssl_verify';
  
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  /// Get saved server URL
  String? getServerUrl() => _prefs.getString(_keyServerUrl);

  /// Save server URL
  Future<bool> saveServerUrl(String url) => _prefs.setString(_keyServerUrl, url);

  /// Clear server URL
  Future<bool> clearServerUrl() => _prefs.remove(_keyServerUrl);

  /// Get SSL verification disabled setting
  bool getDisableSslVerify() => _prefs.getBool(_keyDisableSslVerify) ?? false;

  /// Save SSL verification disabled setting
  Future<bool> saveDisableSslVerify(bool disable) => _prefs.setBool(_keyDisableSslVerify, disable);

  /// Check if server is configured
  bool get isServerConfigured => getServerUrl()?.isNotEmpty ?? false;
}
