// lib/presentation/providers/course_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/youtube_api_service.dart';
import '../../data/datasources/local_storage_service.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/entities/course_progress.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) {
  final storage = LocalStorageService();
  storage.init();
  return storage;
});

final youtubeApiProvider = Provider<YouTubeApiService>((ref) {
  return YouTubeApiService(
    client: http.Client(),
  );
});

final courseRepositoryProvider = Provider<CourseRepositoryImpl>((ref) {
  return CourseRepositoryImpl(
    apiService: ref.watch(youtubeApiProvider),
    storageService: ref.watch(localStorageProvider),
  );
});

// --- Theme ---

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _key = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'dark') {
      state = ThemeMode.dark;
    } else if (value == 'light') {
      state = ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state == ThemeMode.dark ? 'dark' : 'light');
  }
}

// --- Playlist list ---

final playlistListProvider =
    StateNotifierProvider<PlaylistListNotifier, AsyncValue<List<PlaylistMeta>>>(
        (ref) {
  return PlaylistListNotifier(ref.watch(courseRepositoryProvider));
});

class PlaylistListNotifier
    extends StateNotifier<AsyncValue<List<PlaylistMeta>>> {
  final CourseRepositoryImpl repository;

  PlaylistListNotifier(this.repository)
      : super(const AsyncValue.data([])) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    try {
      final playlists = await repository.getPlaylists();
      state = AsyncValue.data(playlists);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> importPlaylist(String playlistId) async {
    try {
      await repository.fetchPlaylist(playlistId);
      await loadPlaylists();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    await repository.deletePlaylist(playlistId);
    await loadPlaylists();
  }
}

// --- Single playlist progress ---

final playlistProgressProvider = StateNotifierProvider.family<
    PlaylistProgressNotifier, AsyncValue<CourseProgress?>, String>(
  (ref, playlistId) {
    return PlaylistProgressNotifier(
      ref.watch(courseRepositoryProvider),
      playlistId,
    );
  },
);

class PlaylistProgressNotifier
    extends StateNotifier<AsyncValue<CourseProgress?>> {
  final CourseRepositoryImpl repository;
  final String playlistId;

  PlaylistProgressNotifier(this.repository, this.playlistId)
      : super(const AsyncValue.loading()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await repository.getPlaylistProgress(playlistId);
      state = AsyncValue.data(progress);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshPlaylist() async {
    state = const AsyncValue.loading();
    try {
      final progress = await repository.fetchPlaylist(playlistId);
      state = AsyncValue.data(progress);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleVideo(String videoId, bool isWatched) async {
    await repository.toggleVideoWatched(videoId, isWatched,
        playlistId: playlistId);
    await _loadProgress();
  }
}

// Legacy provider kept for backward compatibility
final courseProgressProvider =
    StateNotifierProvider<CourseProgressNotifier, AsyncValue<CourseProgress?>>(
        (ref) {
  return CourseProgressNotifier(ref.watch(courseRepositoryProvider));
});

class CourseProgressNotifier
    extends StateNotifier<AsyncValue<CourseProgress?>> {
  final CourseRepositoryImpl repository;

  CourseProgressNotifier(this.repository) : super(const AsyncValue.data(null)) {
    _loadOnStartup();
  }

  Future<void> _loadOnStartup() async {
    try {
      final progress = await repository.getLocalProgress();
      if (progress != null) {
        state = AsyncValue.data(progress);
      }
    } catch (e) {
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
