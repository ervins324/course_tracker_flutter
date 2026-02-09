// lib/domain/usecases/toggle_video_watched.dart
import '../repositories/course_repository.dart';

class ToggleVideoWatched {
  final CourseRepository repository;

  ToggleVideoWatched(this.repository);

  Future<void> call(String videoId, bool isWatched) async {
    await repository.toggleVideoWatched(videoId, isWatched);
  }
}
