import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/datasources/local_storage.dart';
import '../data/datasources/api_client.dart';
import '../data/datasources/websocket_client.dart';
import '../data/repositories/video_repository.dart';
import '../data/repositories/channel_repository.dart';

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

/// Local storage provider
final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage(ref.watch(sharedPreferencesProvider));
});

/// Server URL provider (reactive)
final serverUrlProvider = StateNotifierProvider<ServerUrlNotifier, String?>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return ServerUrlNotifier(localStorage);
});

class ServerUrlNotifier extends StateNotifier<String?> {
  final LocalStorage _localStorage;

  ServerUrlNotifier(this._localStorage) : super(_localStorage.getServerUrl());

  Future<void> setServerUrl(String url) async {
    await _localStorage.saveServerUrl(url);
    state = url;
  }

  Future<void> clearServerUrl() async {
    await _localStorage.clearServerUrl();
    state = null;
  }
}

/// SSL verification disable provider (reactive)
final disableSslVerifyProvider = StateNotifierProvider<DisableSslVerifyNotifier, bool>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return DisableSslVerifyNotifier(localStorage);
});

class DisableSslVerifyNotifier extends StateNotifier<bool> {
  final LocalStorage _localStorage;

  DisableSslVerifyNotifier(this._localStorage) : super(_localStorage.getDisableSslVerify());

  Future<void> setDisableSslVerify(bool disable) async {
    await _localStorage.saveDisableSslVerify(disable);
    state = disable;
  }
}

/// API Client provider - depends on server URL and SSL setting
final apiClientProvider = Provider<VidKeepApiClient?>((ref) {
  final serverUrl = ref.watch(serverUrlProvider);
  final disableSslVerify = ref.watch(disableSslVerifyProvider);
  if (serverUrl == null || serverUrl.isEmpty) return null;
  return VidKeepApiClient(baseUrl: serverUrl, disableSslVerify: disableSslVerify);
});

/// WebSocket client provider
final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  final client = WebSocketClient();
  
  // Connect immediately if API client exists
  final apiClient = ref.read(apiClientProvider);
  if (apiClient != null) {
    client.connect(apiClient.getWebSocketUrl());
  }
  
  // Auto-connect when server URL changes
  ref.listen(apiClientProvider, (previous, next) {
    if (next != null) {
      client.connect(next.getWebSocketUrl());
    } else {
      client.disconnect();
    }
  });
  
  ref.onDispose(() => client.dispose());
  return client;
});

/// Video repository provider
final videoRepositoryProvider = Provider<VideoRepository?>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  if (apiClient == null) return null;
  return VideoRepository(apiClient);
});

/// Channel repository provider
final channelRepositoryProvider = Provider<ChannelRepository?>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  if (apiClient == null) return null;
  return ChannelRepository(apiClient);
});

/// Connection test provider
final connectionTestProvider = FutureProvider<bool>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  if (apiClient == null) return false;
  return apiClient.testConnection();
});
