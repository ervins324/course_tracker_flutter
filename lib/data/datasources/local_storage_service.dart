// lib/data/datasources/local_storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/video_model.dart';

class PlaylistMeta {
  final String playlistId;
  final String title;

  PlaylistMeta({required this.playlistId, required this.title});
}

class LocalStorageService {
  static const String _videosBoxName = 'videos';
  static const String _playlistsBoxName = 'playlists';
  Box<VideoModel>? _videosBox;
  Box<String>? _playlistsBox; // stores playlistId -> title

  // In-memory fallback for web
  final Map<String, VideoModel> _memoryVideos = {};
  final Map<String, String> _memoryPlaylists = {}; // playlistId -> title
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      debugPrint('LocalStorageService: Using in-memory storage for web');
    } else {
      try {
        _videosBox = await Hive.openBox<VideoModel>(_videosBoxName);
        _playlistsBox = await Hive.openBox<String>(_playlistsBoxName);
        _initialized = true;
        debugPrint('LocalStorageService: Hive initialized');
      } catch (e) {
        debugPrint('LocalStorageService: Hive error: $e');
        _initialized = true; // Fallback to memory
      }
    }
  }

  // --- Playlist metadata ---

  Future<void> savePlaylistMeta(String playlistId, String title) async {
    if (!_initialized) await init();

    if (kIsWeb || _playlistsBox == null) {
      _memoryPlaylists[playlistId] = title;
    } else {
      await _playlistsBox!.put(playlistId, title);
    }
  }

  Future<List<PlaylistMeta>> getPlaylists() async {
    if (!_initialized) await init();

    final Map<String, String> entries;
    if (kIsWeb || _playlistsBox == null) {
      entries = Map.from(_memoryPlaylists);
    } else {
      entries = {};
      for (var key in _playlistsBox!.keys) {
        entries[key as String] = _playlistsBox!.get(key) ?? '';
      }
    }

    return entries.entries
        .map((e) => PlaylistMeta(playlistId: e.key, title: e.value))
        .toList();
  }

  Future<void> deletePlaylist(String playlistId) async {
    if (!_initialized) await init();

    // Remove playlist meta
    if (kIsWeb || _playlistsBox == null) {
      _memoryPlaylists.remove(playlistId);
    } else {
      await _playlistsBox!.delete(playlistId);
    }

    // Remove all videos for this playlist
    if (kIsWeb || _videosBox == null) {
      _memoryVideos.removeWhere(
          (key, _) => key.startsWith('${playlistId}_'));
    } else {
      final keysToDelete = _videosBox!.keys
          .where((key) => (key as String).startsWith('${playlistId}_'))
          .toList();
      for (var key in keysToDelete) {
        await _videosBox!.delete(key);
      }
    }
  }

  // --- Videos (scoped by playlist) ---

  Future<void> saveVideos(String playlistId, List<VideoModel> videos) async {
    if (!_initialized) await init();

    // Remove old videos for this playlist first
    if (kIsWeb || _videosBox == null) {
      _memoryVideos.removeWhere(
          (key, _) => key.startsWith('${playlistId}_'));
      for (var video in videos) {
        _memoryVideos['${playlistId}_${video.videoId}'] = video;
      }
    } else {
      final keysToDelete = _videosBox!.keys
          .where((key) => (key as String).startsWith('${playlistId}_'))
          .toList();
      for (var key in keysToDelete) {
        await _videosBox!.delete(key);
      }
      for (var video in videos) {
        await _videosBox!.put('${playlistId}_${video.videoId}', video);
      }
    }
  }

  Future<List<VideoModel>> getVideosByPlaylist(String playlistId) async {
    if (!_initialized) await init();

    List<VideoModel> videos;
    if (kIsWeb || _videosBox == null) {
      videos = _memoryVideos.entries
          .where((e) => e.key.startsWith('${playlistId}_'))
          .map((e) => e.value)
          .toList();
    } else {
      videos = _videosBox!.keys
          .where((key) => (key as String).startsWith('${playlistId}_'))
          .map((key) => _videosBox!.get(key)!)
          .toList();
    }
    videos.sort((a, b) => a.position.compareTo(b.position));
    return videos;
  }

  Future<List<VideoModel>> getVideos() async {
    if (!_initialized) await init();

    List<VideoModel> videos;
    if (kIsWeb || _videosBox == null) {
      videos = _memoryVideos.values.toList();
    } else {
      videos = _videosBox!.values.toList();
    }
    videos.sort((a, b) => a.position.compareTo(b.position));
    return videos;
  }

  Future<void> updateVideoWatchStatus(
      String playlistId, String videoId, bool isWatched) async {
    if (!_initialized) await init();

    final key = '${playlistId}_$videoId';
    if (kIsWeb || _videosBox == null) {
      final video = _memoryVideos[key];
      if (video != null) {
        _memoryVideos[key] = video.copyWith(isWatched: isWatched);
      }
    } else {
      final video = _videosBox!.get(key);
      if (video != null) {
        final updated = video.copyWith(isWatched: isWatched);
        await _videosBox!.put(key, updated);
      }
    }
  }

  Future<void> setAllVideosWatched(String playlistId, bool isWatched) async {
    if (!_initialized) await init();

    if (kIsWeb || _videosBox == null) {
      for (var entry in _memoryVideos.entries.toList()) {
        if (entry.key.startsWith('${playlistId}_')) {
          _memoryVideos[entry.key] = entry.value.copyWith(isWatched: isWatched);
        }
      }
    } else {
      for (var key in _videosBox!.keys) {
        if ((key as String).startsWith('${playlistId}_')) {
          final video = _videosBox!.get(key);
          if (video != null) {
            await _videosBox!.put(key, video.copyWith(isWatched: isWatched));
          }
        }
      }
    }
  }
}
