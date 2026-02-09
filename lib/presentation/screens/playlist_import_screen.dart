// lib/presentation/screens/playlist_import_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_providers.dart';

class PlaylistImportScreen extends ConsumerStatefulWidget {
  const PlaylistImportScreen({super.key});

  @override
  ConsumerState<PlaylistImportScreen> createState() =>
      _PlaylistImportScreenState();
}

class _PlaylistImportScreenState extends ConsumerState<PlaylistImportScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Playlist')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'YouTube Playlist ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _importPlaylist,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importPlaylist() async {
    if (_controller.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(courseProgressProvider.notifier)
          .fetchPlaylist(_controller.text);
      if (mounted) Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
