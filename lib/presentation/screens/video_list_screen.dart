// lib/presentation/screens/video_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_providers.dart';
import '../widgets/video_item.dart';
import 'progress_screen.dart';

class VideoListScreen extends ConsumerWidget {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(courseProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Videos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Import Playlist',
            onPressed: () => _showImportDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'View Progress',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProgressScreen()),
            ),
          ),
        ],
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (progress) {
          if (progress == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.playlist_add, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No playlist loaded'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showImportDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Import Playlist'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: progress.videos.length,
            itemBuilder: (context, index) {
              return VideoItem(video: progress.videos[index]);
            },
          );
        },
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'YouTube Playlist ID',
            hintText: 'PLxxxxxxxxxxxxxx',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                await ref
                    .read(courseProgressProvider.notifier)
                    .fetchPlaylist(controller.text);
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
