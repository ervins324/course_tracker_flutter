import 'package:hive/hive.dart';
import '../../domain/entities/video.dart';
import '../../core/utils/duration_parser.dart';

part 'video_model.g.dart';

@HiveType(typeId: 0)
class VideoModel extends Video {
  @HiveField(0)
  @override
  final String videoId;

  @HiveField(1)
  @override
  final String title;

  @HiveField(2)
  final int durationInSeconds;

  @HiveField(3)
  @override
  final bool isWatched;

  @HiveField(4)
  final int position;

  @HiveField(5)
  @override
  final String thumbnailUrl;

  VideoModel({
    required this.videoId,
    required this.title,
    required this.durationInSeconds,
    this.isWatched = false,
    this.position = 0,
    this.thumbnailUrl = '',
  }) : super(
          videoId: videoId,
          title: title,
          duration: Duration(seconds: durationInSeconds),
          isWatched: isWatched,
          thumbnailUrl: thumbnailUrl,
        );

  factory VideoModel.fromJson(Map<String, dynamic> json, String durationISO,
      {int position = 0}) {
    final thumbnails = json['snippet']?['thumbnails'];
    final thumbnailUrl = thumbnails?['medium']?['url'] ??
        thumbnails?['default']?['url'] ??
        '';

    return VideoModel(
      videoId: json['id'],
      title: json['snippet']['title'],
      durationInSeconds: DurationParser.parseISO8601(durationISO).inSeconds,
      position: position,
      thumbnailUrl: thumbnailUrl,
    );
  }

  factory VideoModel.fromEntity(Video video, {int position = 0}) {
    return VideoModel(
      videoId: video.videoId,
      title: video.title,
      durationInSeconds: video.duration.inSeconds,
      isWatched: video.isWatched,
      position: position,
      thumbnailUrl: video.thumbnailUrl,
    );
  }

  @override
  VideoModel copyWith({bool? isWatched, int? position}) {
    return VideoModel(
      videoId: videoId,
      title: title,
      durationInSeconds: durationInSeconds,
      isWatched: isWatched ?? this.isWatched,
      position: position ?? this.position,
      thumbnailUrl: thumbnailUrl,
    );
  }
}
