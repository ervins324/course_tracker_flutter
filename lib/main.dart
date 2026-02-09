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
