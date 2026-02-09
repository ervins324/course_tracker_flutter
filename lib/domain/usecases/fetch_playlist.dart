// lib/domain/usecases/fetch_playlist.dart
import '../entities/course_progress.dart';
import '../repositories/course_repository.dart';

class FetchPlaylist {
  final CourseRepository repository;

  FetchPlaylist(this.repository);

  Future<CourseProgress> call(String playlistId) async {
    return await repository.fetchPlaylist(playlistId);
  }
}
