// lib/presentation/widgets/video_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/video.dart';
import '../../core/utils/duration_parser.dart';
import '../providers/course_providers.dart';

class VideoItem extends ConsumerWidget {
  final Video video;
  final String playlistId;

  const VideoItem({super.key, required this.video, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('${playlistId}_${video.videoId}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.green.withValues(alpha: 0.8),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Mark Watched', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.orange.withValues(alpha: 0.8),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Mark Unwatched', style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
            Icon(Icons.remove_circle_outline, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right -> mark watched
          ref
              .read(playlistProgressProvider(playlistId).notifier)
              .toggleVideo(video.videoId, true);
        } else {
          // Swipe left -> mark unwatched
          ref
              .read(playlistProgressProvider(playlistId).notifier)
              .toggleVideo(video.videoId, false);
        }
        return false; // Don't actually dismiss
      },
      child: ListTile(
        onTap: () => _openInYouTube(video.videoId),
        leading: video.thumbnailUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  video.thumbnailUrl,
                  width: 80,
                  height: 45,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 45,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.play_circle_outline, size: 28),
                  ),
                ),
              )
            : Container(
                width: 80,
                height: 45,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.play_circle_outline, size: 28),
              ),
        title: Text(
          video.title,
          style: TextStyle(
            decoration: video.isWatched
                ? TextDecoration.lineThrough
                : null,
            color: video.isWatched
                ? theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5)
                : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(DurationParser.formatDuration(video.duration)),
        trailing: Checkbox(
          value: video.isWatched,
          onChanged: (value) {
            ref
                .read(playlistProgressProvider(playlistId).notifier)
                .toggleVideo(video.videoId, value ?? false);
          },
        ),
      ),
    );
  }

  Future<void> _openInYouTube(String videoId) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch YouTube';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
