// lib/data/repositories/course_repository_impl.dart
import '../../domain/entities/course_progress.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/youtube_api_service.dart';
import '../datasources/local_storage_service.dart';

class CourseRepositoryImpl implements CourseRepository {
  final YouTubeApiService apiService;
  final LocalStorageService storageService;

  CourseRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<CourseProgress> fetchPlaylist(String playlistId) async {
    final result = await apiService.fetchPlaylistVideos(playlistId);
    await storageService.savePlaylistMeta(playlistId, result.playlistTitle);

    // Preserve watch status from local storage
    final existingVideos = await storageService.getVideosByPlaylist(playlistId);
    final watchedVideoIds = {
      for (var v in existingVideos) if (v.isWatched) v.videoId
    };

    final videosWithStatus = result.videos.map((video) {
      if (watchedVideoIds.contains(video.videoId)) {
        return video.copyWith(isWatched: true);
      }
      return video;
    }).toList();

    await storageService.saveVideos(playlistId, videosWithStatus);
    return CourseProgress(
      playlistId: playlistId,
      playlistTitle: result.playlistTitle,
      videos: videosWithStatus,
    );
  }

  @override
  Future<CourseProgress?> getLocalProgress() async {
    // Legacy: returns first playlist found
    final playlists = await storageService.getPlaylists();
    if (playlists.isEmpty) return null;
    return getPlaylistProgress(playlists.first.playlistId);
  }

  Future<CourseProgress?> getPlaylistProgress(String playlistId) async {
    final videos = await storageService.getVideosByPlaylist(playlistId);
    if (videos.isEmpty) return null;
    final playlists = await storageService.getPlaylists();
    final meta = playlists
        .where((p) => p.playlistId == playlistId)
        .firstOrNull;
    return CourseProgress(
      playlistId: playlistId,
      playlistTitle: meta?.title ?? playlistId,
      videos: videos,
    );
  }

  Future<List<PlaylistMeta>> getPlaylists() async {
    return storageService.getPlaylists();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await storageService.deletePlaylist(playlistId);
  }

  @override
  Future<void> toggleVideoWatched(String videoId, bool isWatched,
      {String playlistId = ''}) async {
    await storageService.updateVideoWatchStatus(playlistId, videoId, isWatched);
  }

  Future<void> setAllVideosWatched(String playlistId, bool isWatched) async {
    await storageService.setAllVideosWatched(playlistId, isWatched);
  }
}
