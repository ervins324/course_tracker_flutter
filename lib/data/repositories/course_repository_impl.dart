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
    final videos = await apiService.fetchPlaylistVideos(playlistId);
    await storageService.saveVideos(playlistId, videos);
    return CourseProgress(playlistId: playlistId, videos: videos);
  }

  @override
  Future<CourseProgress?> getLocalProgress() async {
    final videos = await storageService.getVideos();
    if (videos.isEmpty) return null;
    return CourseProgress(playlistId: 'cached', videos: videos);
  }

  @override
  Future<void> toggleVideoWatched(String videoId, bool isWatched) async {
    await storageService.updateVideoWatchStatus(videoId, isWatched);
  }
}
