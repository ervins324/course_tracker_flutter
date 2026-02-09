import '../repositories/course_repository.dart';
import '../entities/course_progress.dart';

class GetProgress {
  final CourseRepository repository;
  GetProgress(this.repository);

  Future<CourseProgress?> call() {
    return repository.getLocalProgress();
  }
}
