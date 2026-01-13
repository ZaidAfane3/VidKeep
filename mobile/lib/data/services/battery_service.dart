import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'download_service.dart';

/// Service for monitoring battery state and managing downloads accordingly
class BatteryService {
  final Battery _battery = Battery();
  final DownloadService _downloadService;
  
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  bool _pausedDueToLowBattery = false;
  bool _pauseOnLowBattery = true;
  
  /// Low battery threshold (20%)
  static const int lowBatteryThreshold = 20;

  BatteryService(this._downloadService);

  /// Start monitoring battery state
  void startMonitoring({bool pauseOnLowBattery = true}) {
    _pauseOnLowBattery = pauseOnLowBattery;
    
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) async {
      if (!_pauseOnLowBattery) return;
      
      if (state == BatteryState.discharging || state == BatteryState.unknown) {
        // Check battery level when not charging
        final level = await _battery.batteryLevel;
        if (level <= lowBatteryThreshold) {
          await _handleLowBattery();
        }
      } else if (state == BatteryState.charging || state == BatteryState.full) {
        // Resume downloads when charging resumes
        if (_pausedDueToLowBattery) {
          await _handleChargingResumed();
        }
      }
    });
    
    // Also check initial battery state
    _checkInitialBatteryState();
  }

  /// Stop monitoring battery state
  void stopMonitoring() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
  }

  /// Update pause on low battery setting
  void setPauseOnLowBattery(bool value) {
    _pauseOnLowBattery = value;
    if (!value && _pausedDueToLowBattery) {
      // If user disables this setting while paused, resume downloads
      _downloadService.resumeAllDownloads();
      _pausedDueToLowBattery = false;
    }
  }

  /// Check initial battery state on startup
  Future<void> _checkInitialBatteryState() async {
    if (!_pauseOnLowBattery) return;
    
    final state = await _battery.batteryState;
    final level = await _battery.batteryLevel;
    
    if (state != BatteryState.charging && 
        state != BatteryState.full && 
        level <= lowBatteryThreshold) {
      await _handleLowBattery();
    }
  }

  /// Handle low battery condition
  Future<void> _handleLowBattery() async {
    if (!_pausedDueToLowBattery) {
      _pausedDueToLowBattery = true;
      await _downloadService.pauseAllDownloads();
    }
  }

  /// Handle when charging resumes
  Future<void> _handleChargingResumed() async {
    if (_pausedDueToLowBattery) {
      _pausedDueToLowBattery = false;
      await _downloadService.resumeAllDownloads();
    }
  }

  /// Check if downloads are currently paused due to low battery
  bool get isPausedDueToLowBattery => _pausedDueToLowBattery;

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
