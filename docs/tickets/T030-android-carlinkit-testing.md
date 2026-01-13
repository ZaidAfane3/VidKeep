# T030: Android Testing for CarLinkit TBox

## 1. Overview

**Ticket Type**: Testing & Configuration  
**Priority**: Medium  
**Platform**: Android 13 (API 33)  
**Dependencies**: T027 (Flutter Mobile App), T029 (Offline Playback)  

### Summary

Configure and test the VidKeep Flutter mobile app on Android 13 targeting the **CarLinkit TBox**—a standalone Android device (AI Box) with Google Play Store access that outputs to car infotainment displays. This includes Android-specific manifest configurations, emulator setup with automotive profiles, and physical device deployment.

---

## 2. Background

### What is CarLinkit TBox?

The CarLinkit TBox is:
- A **standalone Android 13 device** (AI Box)
- **NOT Android Auto** - it runs full Android apps directly
- Outputs to the car's infotainment display
- Has Google Play Store access
- Connects via USB or WiFi

### Current State

- ✅ VidKeep Flutter app complete (T027)
- ✅ Tested on iOS simulator and devices
- ✅ 44 tests passing
- ❌ **Not yet tested on Android**
- 🔄 T029 (Offline Playback) in progress

---

## 3. Android Configuration Changes

### 3.1 AndroidManifest.xml Updates

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application
        android:label="VidKeep"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:screenOrientation="sensorLandscape"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- ... rest unchanged ... -->
        </activity>
    </application>
</manifest>
```

**Changes:**
| Attribute | Value | Purpose |
|-----------|-------|---------|
| `screenOrientation` | `sensorLandscape` | Lock to landscape for in-car display |
| `INTERNET` permission | Explicit declaration | Network access for API/streaming |

### 3.2 Gradle Configuration

Current `build.gradle.kts` uses Flutter defaults which support Android 13:
- `minSdk`: 21+ (compatible)
- `targetSdk`: 34 (compatible with API 33)
- `compileSdk`: Flutter default (compatible)

**No changes required** for API 33 support.

---

## 4. UI/UX Guidelines for In-Car Display

### 4.1 Touch Target Sizing

Per Android Automotive guidelines, all interactive elements should have:
- **Minimum**: 48dp × 48dp
- **Recommended for drivers**: 56dp × 56dp

| Component | File | Action Required |
|-----------|------|-----------------|
| Video card | `video_card.dart` | ✅ Full-card tap area |
| Nav icons | `home_screen.dart` | Verify 48dp+ |
| Action buttons | `video_detail_screen.dart` | Verify 48dp+ |
| Settings toggles | `settings_screen.dart` | Verify 48dp+ |
| Player controls | `video_player_screen.dart` | Verify 56dp+ |

### 4.2 Display Optimization

| Requirement | Current Status |
|-------------|----------------|
| High contrast | ✅ Neon green (#00FF41) on black (#050505) |
| Large text | Review font sizes |
| Landscape optimized | Adding via manifest |
| Target resolution | 1080p/720p (standard) |
| Minimal scrolling | ✅ Grid layout |
| No small buttons | Audit required |

### 4.3 Readability

For in-car use, consider:
- Increasing base font size by 10-20%
- Ensuring text doesn't wrap at landscape resolutions
- Testing at arm's length viewing distance

---

## 5. Local Development Environment

### 5.1 Install Android 13 System Image

```bash
sdkmanager "system-images;android-33;google_apis;arm64-v8a"
```

### 5.2 Create Emulator with Automotive-Like Profile

**Option A: Tablet Profile (General Match)**
```bash
avdmanager create avd \
  -n CarLinkit_Test \
  -k "system-images;android-33;google_apis;arm64-v8a" \
  -d "pixel_tablet"
```

**Option B: Automotive Landscape Profile**
```bash
avdmanager create avd \
  -n CarLinkit_Auto \
  -k "system-images;android-33;google_apis;arm64-v8a" \
  -d "automotive_1024p_landscape"
```

### 5.3 Launch and Run

```bash
emulator -avd CarLinkit_Test
flutter run
```

---

## 6. Physical Device Deployment

### 6.1 Enable Developer Mode on TBox

1. Go to **Settings → About**
2. Tap **Build number** 7 times
3. Enable **USB debugging** in Developer Options

### 6.2 Connect via ADB

**USB Connection:**
```bash
adb devices
flutter devices
flutter run
```

**WiFi Connection:**
```bash
adb connect <tbox-ip>:5555
flutter devices
flutter run
```

### 6.3 Verify Connection

```bash
flutter devices
# Should show: CarLinkit (mobile) • <ip>:5555 • android-arm64 • Android 13
```

---

## 7. Testing Checklist

### 7.1 Emulator Testing

- [ ] App launches in landscape mode
- [ ] Video grid displays correctly
- [ ] Touch targets are accessible
- [ ] Server configuration works
- [ ] Video streaming plays smoothly
- [ ] WebSocket progress updates work
- [ ] Favorites toggle works
- [ ] Channel filter works
- [ ] Video player controls functional
- [ ] Settings screen accessible

### 7.2 Physical Device Testing

- [ ] App deploys successfully via ADB
- [ ] Display renders on head unit
- [ ] Touch responsiveness acceptable
- [ ] Video streaming over WiFi works
- [ ] Network latency acceptable
- [ ] Audio output works
- [ ] All features from emulator testing verified

### 7.3 Edge Cases

- [ ] App behavior when TBox loses network
- [ ] Video buffering on slower connections
- [ ] App behavior during car start/stop
- [ ] Memory usage acceptable for device

---

## 8. Potential Issues & Mitigations

| Issue | Mitigation |
|-------|------------|
| TBox has limited RAM | Monitor memory usage, optimize grid |
| Network latency in car | Test with variable network conditions |
| Display aspect ratio mismatch | Use responsive layouts (already implemented) |
| Touch calibration issues | Increase touch target sizes |
| Video codec compatibility | H.264/AAC MP4 (already used) should work |

---

## 9. Acceptance Criteria

- [ ] AndroidManifest.xml updated with landscape orientation
- [ ] App builds and runs on Android 13 emulator
- [ ] All core features work on emulator
- [ ] App deploys to physical CarLinkit TBox
- [ ] Video playback works on actual device
- [ ] Touch interactions responsive
- [ ] No critical bugs on Android platform

---

## 10. Effort Estimation

| Phase | Duration |
|-------|----------|
| Android configuration | 1 hour |
| Emulator setup & testing | 2 hours |
| Touch target audit | 1 hour |
| Physical device testing | 2 hours |
| Bug fixes (if any) | 2-4 hours |
| **Total** | **~1 day** |

---

## 11. Execution Log

| Date | Phase | Action | Details |
|------|-------|--------|---------|
| 2026-01-13 | Planning | Ticket created | Based on manager's setup guide |
| 2026-01-13 | Setup | System image download | Running: `sdkmanager "system-images;android-33;google_apis;arm64-v8a"` |

---

## 12. References

- [Android Automotive Design Guidelines](https://developer.android.com/design/ui/automotive/guidelines)
- [Flutter Android Documentation](https://docs.flutter.dev/deployment/android)
- [CarLinkit TBox Documentation](https://www.carlinkit.com/)
- [T027 Flutter Mobile App](T027-flutter-mobile-app.md)
- [T029 Offline Playback](T029-offline-playback.md)
