/// App configuration for server connection
class AppConfig {
  /// Default server port (monolith serves on 3001)
  static const int defaultPort = 3001;
  
  /// WebSocket connection timeout in seconds
  static const int wsConnectTimeoutSec = 10;
  
  /// HTTP connection timeout in seconds  
  static const int httpConnectTimeoutSec = 10;
  
  /// HTTP receive timeout in seconds
  static const int httpReceiveTimeoutSec = 30;
  
  /// WebSocket ping interval in seconds
  static const int wsPingIntervalSec = 30;
  
  /// WebSocket reconnect delay in seconds
  static const int wsReconnectDelaySec = 5;
  
  /// App version
  static const String appVersion = '1.0.0';
  
  /// App name
  static const String appName = 'VidKeep';
}
