// lib/presentation/screens/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_providers.dart';
import '../widgets/progress_card.dart';

class ProgressScreen extends ConsumerWidget {
  final String playlistId;

  const ProgressScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(playlistProgressProvider(playlistId));

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (progress) {
          if (progress == null) {
            return const Center(child: Text('No progress data available'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ProgressCard(progress: progress),
          );
        },
      ),
    );
  }
}
