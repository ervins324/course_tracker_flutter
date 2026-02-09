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

  Future<List<VideoModel>> getVideos() async {
    if (!_initialized) await init();

    List<VideoModel> videos;
    if (kIsWeb || _box == null) {
      videos = _memoryStorage.values.toList();
    } else {
      videos = _box!.values.toList();
    }
    // Sort by position to preserve playlist order
    videos.sort((a, b) => a.position.compareTo(b.position));
    return videos;
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
