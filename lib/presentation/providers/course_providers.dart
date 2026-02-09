// lib/presentation/providers/course_providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/youtube_api_service.dart';
import '../../data/datasources/local_storage_service.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/entities/course_progress.dart';
import '../../core/constants/api_constants.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) {
  final storage = LocalStorageService();
  // Initialize asynchronously (will use in-memory storage on web)
  storage.init();
  return storage;
});

final youtubeApiProvider = Provider<YouTubeApiService>((ref) {
  return YouTubeApiService(
    apiKey: ApiConstants.apiKey,
    client: http.Client(),
  );
});

final courseRepositoryProvider = Provider<CourseRepositoryImpl>((ref) {
  return CourseRepositoryImpl(
    apiService: ref.watch(youtubeApiProvider),
    storageService: ref.watch(localStorageProvider),
  );
});

final courseProgressProvider =
    StateNotifierProvider<CourseProgressNotifier, AsyncValue<CourseProgress?>>(
        (ref) {
  return CourseProgressNotifier(ref.watch(courseRepositoryProvider));
});

class CourseProgressNotifier
    extends StateNotifier<AsyncValue<CourseProgress?>> {
  final CourseRepositoryImpl repository;

  CourseProgressNotifier(this.repository) : super(const AsyncValue.data(null)) {
    // Auto-load saved progress on startup
    _loadOnStartup();
  }

  Future<void> _loadOnStartup() async {
    try {
      final progress = await repository.getLocalProgress();
      if (progress != null) {
        state = AsyncValue.data(progress);
      }
    } catch (e) {
      // Silently fail on startup - user can manually import
      debugPrint('Failed to load saved progress: $e');
    }
  }

  Future<void> loadProgress() async {
    state = const AsyncValue.loading();
    try {
      final progress = await repository.getLocalProgress();
      state = AsyncValue.data(progress);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> fetchPlaylist(String playlistId) async {
    state = const AsyncValue.loading();
    try {
      final progress = await repository.fetchPlaylist(playlistId);
      state = AsyncValue.data(progress);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleVideo(String videoId, bool isWatched) async {
    await repository.toggleVideoWatched(videoId, isWatched);
    await loadProgress();
  }
}
