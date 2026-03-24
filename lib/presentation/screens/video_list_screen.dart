// lib/presentation/screens/video_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_providers.dart';
import '../widgets/video_item.dart';
import 'progress_screen.dart';

class VideoListScreen extends ConsumerWidget {
  final String playlistId;
  final String playlistTitle;

  const VideoListScreen({
    super.key,
    required this.playlistId,
    this.playlistTitle = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(playlistProgressProvider(playlistId));

    return Scaffold(
      appBar: AppBar(
        title: Text(playlistTitle.isNotEmpty ? playlistTitle : 'Course Videos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'View Progress',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProgressScreen(playlistId: playlistId)),
            ),
          ),
        ],
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(playlistProgressProvider(playlistId).notifier)
                      .refreshPlaylist(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (progress) {
          if (progress == null) {
            return const Center(child: Text('No videos found'));
          }
          return Column(
            children: [
              // Progress bar at top
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.progressPercentage / 100,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${progress.watchedVideos}/${progress.totalVideos}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              // Video list with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(playlistProgressProvider(playlistId).notifier)
                      .refreshPlaylist(),
                  child: ListView.builder(
                    itemCount: progress.videos.length,
                    itemBuilder: (context, index) {
                      return VideoItem(
                        video: progress.videos[index],
                        playlistId: playlistId,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
