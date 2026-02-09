import '../entities/course_progress.dart';

abstract class CourseRepository {
  Future<CourseProgress> fetchPlaylist(String playlistId);
  Future<CourseProgress?> getLocalProgress();
  Future<void> toggleVideoWatched(String videoId, bool isWatched);
}
