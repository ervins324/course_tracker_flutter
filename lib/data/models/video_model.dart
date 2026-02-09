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

  VideoModel({
    required this.videoId,
    required this.title,
    required this.durationInSeconds,
    this.isWatched = false,
    this.position = 0,
  }) : super(
          videoId: videoId,
          title: title,
          duration: Duration(seconds: durationInSeconds),
          isWatched: isWatched,
        );

  factory VideoModel.fromJson(Map<String, dynamic> json, String durationISO,
      {int position = 0}) {
    return VideoModel(
      videoId: json['id'],
      title: json['snippet']['title'],
      durationInSeconds: DurationParser.parseISO8601(durationISO).inSeconds,
      position: position,
    );
  }

  factory VideoModel.fromEntity(Video video, {int position = 0}) {
    return VideoModel(
      videoId: video.videoId,
      title: video.title,
      durationInSeconds: video.duration.inSeconds,
      isWatched: video.isWatched,
      position: position,
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
    );
  }
}
