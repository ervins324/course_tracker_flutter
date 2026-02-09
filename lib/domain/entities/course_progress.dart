import 'video.dart';

class CourseProgress {
  final String playlistId;
  final List<Video> videos;

  CourseProgress({required this.playlistId, required this.videos});

  int get totalVideos => videos.length;
  int get watchedVideos => videos.where((v) => v.isWatched).length;
  double get progressPercentage =>
      totalVideos > 0 ? (watchedVideos / totalVideos) * 100 : 0;

  Duration get totalDuration =>
      videos.fold(Duration.zero, (sum, video) => sum + video.duration);

  Duration get watchedDuration => videos
      .where((v) => v.isWatched)
      .fold(Duration.zero, (sum, video) => sum + video.duration);

  Duration get remainingDuration => totalDuration - watchedDuration;
}
