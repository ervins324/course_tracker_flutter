# 📱 Building Course Tracker for Android

## Complete Step-by-Step Guide

---

## 📋 Prerequisites Checklist

Before building, make sure you have:

- [ ] Flutter SDK installed
- [ ] Android Studio installed
- [ ] Android SDK installed (via Android Studio)
- [ ] Java Development Kit (JDK) 17 or later
- [ ] An Android device OR Android Emulator set up
- [ ] USB debugging enabled (if using physical device)

---

## Part 1: Environment Setup Verification

### Step 1: Check Flutter Installation

Open a terminal and run:

```powershell
flutter doctor
```

**Expected output** - All checks should show ✓:
```
[✓] Flutter (Channel stable)
[✓] Windows Version
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Android Studio
[✓] VS Code
[✓] Connected device
```

**If you see issues:**
- `[✗] Android toolchain` → Run: `flutter doctor --android-licenses` and accept all
- `[✗] Android Studio` → Install Android Studio from https://developer.android.com/studio

### Step 2: List Available Devices

```powershell
flutter devices
```

This shows all connected devices/emulators. You need at least one Android device.

---

## Part 2: Enable Hive for Android

Since we're building for mobile, we need to re-enable Hive storage.

### Step 3: Update main.dart for Android

The current code uses in-memory storage. For Android, we should use Hive.

**File: `lib/main.dart`** - Update to:

```dart
// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/video_model.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for mobile platforms
  if (!kIsWeb) {
    await Hive.initFlutter();
    Hive.registerAdapter(VideoModelAdapter());
  }

  // Initialize notifications (Android/iOS only)
  if (!kIsWeb) {
    try {
      final notifications = NotificationService();
      await notifications.init();
      await notifications.scheduleDailyReminder();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}
```

### Step 4: Update LocalStorageService for Android

**File: `lib/data/datasources/local_storage_service.dart`** - Update to use Hive on Android:

```dart
// lib/data/datasources/local_storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/video_model.dart';

class LocalStorageService {
  static const String _boxName = 'videos';
  Box<VideoModel>? _box;
  
  // In-memory fallback for web
  final Map<String, VideoModel> _memoryStorage = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    if (kIsWeb) {
      // Web: use in-memory storage
      _initialized = true;
      debugPrint('LocalStorageService: Using in-memory storage for web');
    } else {
      // Mobile: use Hive
      try {
        _box = await Hive.openBox<VideoModel>(_boxName);
        _initialized = true;
        debugPrint('LocalStorageService: Hive initialized');
      } catch (e) {
        debugPrint('LocalStorageService: Hive error: $e');
        _initialized = true; // Fallback to memory
      }
    }
  }

  Future<void> saveVideos(String playlistId, List<VideoModel> videos) async {
    if (!_initialized) await init();
    
    if (kIsWeb || _box == null) {
      _memoryStorage.clear();
      for (var video in videos) {
        _memoryStorage[video.videoId] = video;
      }
    } else {
      await _box!.clear();
      for (var video in videos) {
        await _box!.put(video.videoId, video);
      }
    }
  }

  List<VideoModel> getVideos() {
    if (kIsWeb || _box == null) {
      return _memoryStorage.values.toList();
    }
    return _box!.values.toList();
  }

  Future<void> updateVideoWatchStatus(String videoId, bool isWatched) async {
    if (!_initialized) await init();
    
    if (kIsWeb || _box == null) {
      final video = _memoryStorage[videoId];
      if (video != null) {
        _memoryStorage[videoId] = video.copyWith(isWatched: isWatched);
      }
    } else {
      final video = _box!.get(videoId);
      if (video != null) {
        final updated = video.copyWith(isWatched: isWatched);
        await _box!.put(videoId, updated);
      }
    }
  }
}
```

---

## Part 3: Android Configuration

### Step 5: Check Android Permissions

**File: `android/app/src/main/AndroidManifest.xml`**

Make sure these permissions are added inside the `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Step 6: Set Minimum SDK Version

**File: `android/app/build.gradle`**

Find and update `minSdkVersion`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Minimum for better compatibility
        targetSdkVersion flutter.targetSdkVersion
        // ...
    }
}
```

### Step 7: Configure Notification Icons

For notifications to work, you need an icon:

1. Create folder: `android/app/src/main/res/drawable/`
2. Add a white icon named `ic_notification.png` (24x24 dp)

Or use the default launcher icon by keeping `@mipmap/ic_launcher` in the code.

---

## Part 4: Testing Before Build

### Step 8: Run Flutter Analyze

Check for code errors:

```powershell
cd "c:\Users\ervin\Documents\Flutter project\course_tracker"
flutter analyze
```

**Expected:** Only info-level warnings, no errors.

### Step 9: Run Tests

```powershell
flutter test
```

**Expected:** All tests pass.

### Step 10: Start Android Emulator

**Option A: Via Android Studio**
1. Open Android Studio
2. Go to Tools → Device Manager
3. Click ▶ on an existing emulator, OR create a new one

**Option B: Via Command Line**
```powershell
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_name>
```

### Step 11: Run App in Debug Mode

```powershell
# Run on connected device/emulator
flutter run

# Or specify a device
flutter run -d <device_id>
```

**Test these features:**
- [ ] App launches without crashing
- [ ] "Import Playlist" button works
- [ ] Enter playlist ID: `PLDEGK5m5KIoxShpWfqfY2FSIGSJct2yPk`
- [ ] Videos load and display
- [ ] Checkboxes toggle watched status
- [ ] Progress screen shows statistics
- [ ] Data persists after closing and reopening app (Hive)

### Step 12: Hot Reload Testing

While the app is running:
- Press `r` for hot reload (applies code changes instantly)
- Press `R` for hot restart (restarts app)
- Press `q` to quit

---

## Part 5: Building the APK

### Step 13: Clean Build Artifacts

```powershell
flutter clean
flutter pub get
```

### Step 14: Generate Hive Adapters

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 15: Build Debug APK

For testing on devices:

```powershell
flutter build apk --debug
```

**Output location:** `build\app\outputs\flutter-apk\app-debug.apk`

### Step 16: Build Release APK

For distribution (smaller, optimized):

```powershell
flutter build apk --release
```

**Output location:** `build\app\outputs\flutter-apk\app-release.apk`

### Step 17: Build App Bundle (for Play Store)

Google Play prefers App Bundles:

```powershell
flutter build appbundle --release
```

**Output location:** `build\app\outputs\bundle\release\app-release.aab`

---

## Part 6: Install and Test APK

### Step 18: Install on Connected Device

```powershell
# Install debug APK
flutter install

# Or manually with adb
adb install build\app\outputs\flutter-apk\app-debug.apk
```

### Step 19: Install on Physical Device (without USB)

1. Copy the APK file to your phone (via email, cloud, USB transfer)
2. On your phone, go to Settings → Security → Enable "Unknown sources"
3. Open the APK file and install

---

## 🔧 Troubleshooting Common Issues

### Issue: "SDK location not found"
```powershell
# Set ANDROID_HOME environment variable
$env:ANDROID_HOME = "C:\Users\<username>\AppData\Local\Android\Sdk"
```

### Issue: "Gradle build failed"
```powershell
cd android
.\gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### Issue: "License not accepted"
```powershell
flutter doctor --android-licenses
# Press 'y' for each license
```

### Issue: "Device not found"
1. Enable USB Debugging on your phone
2. Trust the computer when prompted
3. Run `adb devices` to verify connection

### Issue: "Hive adapter not found"
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📝 Quick Commands Reference

| Command | Description |
|---------|-------------|
| `flutter doctor` | Check environment setup |
| `flutter devices` | List connected devices |
| `flutter run` | Run in debug mode |
| `flutter run --release` | Run in release mode |
| `flutter build apk --debug` | Build debug APK |
| `flutter build apk --release` | Build release APK |
| `flutter build appbundle` | Build App Bundle |
| `flutter install` | Install on device |
| `flutter clean` | Clean build artifacts |
| `flutter analyze` | Check for errors |
| `flutter test` | Run tests |

---

## ✅ Final Checklist Before Release

- [ ] App icon configured (`android/app/src/main/res/mipmap-*`)
- [ ] App name set in `AndroidManifest.xml`
- [ ] Version updated in `pubspec.yaml`
- [ ] API key is valid and not expired
- [ ] All features tested on real device
- [ ] Proguard rules configured (if using code obfuscation)
- [ ] Signing key created for release builds

---

## 🎉 Success!

Your app is now built and ready for the Play Store or direct distribution!

For Play Store submission, you'll need:
1. Release App Bundle (.aab)
2. Developer account ($25 one-time fee)
3. App icons, screenshots, descriptions
4. Privacy policy URL
