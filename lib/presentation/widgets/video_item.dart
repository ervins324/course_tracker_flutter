// lib/presentation/widgets/video_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/video.dart';
import '../../core/utils/duration_parser.dart';
import '../providers/course_providers.dart';

class VideoItem extends ConsumerWidget {
  final Video video;

  const VideoItem({super.key, required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      title: Text(video.title),
      subtitle: Text(DurationParser.formatDuration(video.duration)),
      value: video.isWatched,
      onChanged: (value) {
        ref.read(courseProgressProvider.notifier).toggleVideo(
          video.videoId,
          value ?? false,
        );
      },
    );
  }
}

