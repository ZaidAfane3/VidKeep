import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/config/app_config.dart';

/// Download progress data from WebSocket
class DownloadProgress {
  final String videoId;
  final int percent;
  final int? downloadedBytes;
  final int? totalBytes;

  DownloadProgress({
    required this.videoId,
    required this.percent,
    this.downloadedBytes,
    this.totalBytes,
  });

  factory DownloadProgress.fromJson(Map<String, dynamic> json) {
    return DownloadProgress(
      videoId: json['video_id'],
      percent: json['percent'] ?? 0,
      downloadedBytes: json['downloaded_bytes'],
      totalBytes: json['total_bytes'],
    );
  }
}

/// WebSocket client for real-time download progress updates
class WebSocketClient {
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _wsUrl;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  
  // Smart retry logic
  int _retryCount = 0;
  bool _hasGivenUp = false;
  static const int _maxRetries = 3;
  
  final _progressController = StreamController<DownloadProgress>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  /// Stream of download progress updates
  Stream<DownloadProgress> get progressStream => _progressController.stream;
  
  /// Stream of connection status changes
  Stream<bool> get connectionStream => _connectionController.stream;
  
  /// Current connection status
  bool get isConnected => _isConnected;
  
  /// Whether the client has given up trying to connect
  bool get hasGivenUp => _hasGivenUp;

  /// Connect to WebSocket server
  /// If already given up from previous failures, this is a no-op
  /// Use resetRetries() to force a new connection attempt
  void connect(String wsUrl) {
    // Don't reconnect if we've already given up
    if (_hasGivenUp) return;
    
    _wsUrl = wsUrl;
    _shouldReconnect = true;
    _doConnect();
  }

  void _doConnect() {
    if (_wsUrl == null || _hasGivenUp) return;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl!));
      // Don't set _isConnected = true here - connection is async
      // We'll confirm connection when we receive first message or ping response
      _connectionController.add(true);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Start keepalive ping every 30 seconds
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(
        Duration(seconds: AppConfig.wsPingIntervalSec),
        (_) => _sendPing(),
      );
    } catch (e) {
      // Only log first failure
      if (_retryCount == 0) {
        debugPrint('[WS] Connection error: $e');
      }
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    // Connection confirmed on first message
    if (!_isConnected) {
      _isConnected = true;
      _retryCount = 0; // Only reset on ACTUAL successful connection
      debugPrint('[WS] Connection confirmed');
    }
    
    if (message == 'pong') return;

    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'progress') {
        _progressController.add(DownloadProgress.fromJson(data));
      } else if (data['type'] == 'status') {
        // Status update - video state changed
        _progressController.add(DownloadProgress(
          videoId: data['video_id'],
          percent: data['percent'] ?? 0,
        ));
      }
    } catch (e) {
      debugPrint('[WS] Error parsing message: $e');
    }
  }

  void _onError(Object error) {
    // Only log first error to reduce noise
    if (_retryCount == 0) {
      debugPrint('[WS] Error: $error');
    }
    _handleDisconnect();
  }

  void _onDone() {
    // Only log first disconnect
    if (_retryCount == 0) {
      debugPrint('[WS] Connection closed');
    }
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _isConnected = false;
    _connectionController.add(false);
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _hasGivenUp) return;
    
    _retryCount++;
    
    if (_retryCount > _maxRetries) {
      debugPrint('[WS] Max retries ($_maxRetries) reached, giving up until refresh');
      _hasGivenUp = true;
      return;
    }
    
    debugPrint('[WS] Retry $_retryCount of $_maxRetries...');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: AppConfig.wsReconnectDelaySec),
      _doConnect,
    );
  }
  
  /// Reset retry counter and attempt to reconnect
  /// Called on pull-to-refresh or manual retry
  void resetRetries() {
    _retryCount = 0;
    _hasGivenUp = false;
    _reconnectTimer?.cancel();
    _doConnect();
  }

  void _sendPing() {
    try {
      _channel?.sink.add('ping');
    } catch (e) {
      debugPrint('[WS] Ping error: $e');
    }
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _shouldReconnect = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _progressController.close();
    _connectionController.close();
  }
}
