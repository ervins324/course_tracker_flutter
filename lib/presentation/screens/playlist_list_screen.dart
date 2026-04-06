// lib/presentation/screens/playlist_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../data/datasources/local_storage_service.dart';
import 'video_list_screen.dart';

class PlaylistListScreen extends ConsumerWidget {
  const PlaylistListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Change API Key',
            onPressed: () => _showApiKeyDialog(context),
          ),
          IconButton(
            icon: Icon(
              ref.watch(themeProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: playlistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(playlistListProvider.notifier).loadPlaylists(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (playlists) {
          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 80,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No courses yet',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  const Text(
                    'To work correctly, the app needs a YouTube Data API Key.\n\n1. Set your API Key\n2. Import a YouTube playlist',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showImportDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Import Playlist'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showApiKeyDialog(context),
                    icon: const Icon(Icons.key),
                    label: const Text('Set API Key'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              return _PlaylistCard(
                playlist: playlists[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoListScreen(
                      playlistId: playlists[index].playlistId,
                      playlistTitle: playlists[index].title,
                    ),
                  ),
                ),
                onDelete: () => _confirmDelete(
                    context, ref, playlists[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showImportDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import Playlists'),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            maxLines: null,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: 'YouTube Playlist IDs or URLs',
              hintText: 'One per line:\nPLxxxxx\nhttps://youtube.com/playlist?list=PLyyyyy',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              // Split input by newlines, trim each, remove empty lines
              final lines = controller.text
                  .split('\n')
                  .map((l) => l.trim())
                  .where((l) => l.isNotEmpty)
                  .toList();

              // Extract playlist IDs from each line
              final playlistIds = lines.map((line) {
                if (line.contains('youtube.com') || line.contains('youtu.be')) {
                  final uri = Uri.tryParse(line);
                  if (uri != null && uri.queryParameters.containsKey('list')) {
                    return uri.queryParameters['list']!;
                  }
                }
                return line;
              }).toList();

              Navigator.pop(dialogContext);

              final failures = <String>[];
              for (final id in playlistIds) {
                try {
                  await ref
                      .read(playlistListProvider.notifier)
                      .importPlaylist(id);
                } catch (e) {
                  failures.add('$id: $e');
                }
              }

              if (context.mounted) {
                final successCount = playlistIds.length - failures.length;
                if (failures.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(successCount == 1
                          ? 'Playlist imported successfully'
                          : '$successCount playlists imported successfully'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$successCount imported, ${failures.length} failed:\n${failures.join('\n')}',
                      ),
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'Retry',
                        onPressed: () => _showImportDialog(context, ref),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, PlaylistMeta playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text(
            'Are you sure you want to delete "${playlist.title}"? This will remove all progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(playlistListProvider.notifier)
                  .deletePlaylist(playlist.playlistId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConstants.apiKey);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Google API Key',
            hintText: 'Enter your Google API Key',
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
                await ApiConstants.saveApiKey(controller.text.trim());
                if (!context.mounted) return;
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key updated and saved')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  final PlaylistMeta playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync =
        ref.watch(playlistProgressProvider(playlist.playlistId));
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(playlist.playlistId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.play_circle_outline,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        playlist.title.isNotEmpty
                            ? playlist.title
                            : playlist.playlistId,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 12),
                progressAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Could not load progress'),
                  data: (progress) {
                    if (progress == null) {
                      return const Text('No data');
                    }
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.progressPercentage / 100,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${progress.watchedVideos}/${progress.totalVideos} videos',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '${progress.progressPercentage.toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
