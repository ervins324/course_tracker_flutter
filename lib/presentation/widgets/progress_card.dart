// lib/presentation/widgets/progress_card.dart
import 'package:flutter/material.dart';
import '../../domain/entities/course_progress.dart';
import '../../core/utils/duration_parser.dart';

class ProgressCard extends StatelessWidget {
  final CourseProgress progress;

  const ProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${progress.progressPercentage.toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress.progressPercentage / 100),
            const SizedBox(height: 16),
            _buildStat(
                'Videos', '${progress.watchedVideos}/${progress.totalVideos}'),
            _buildStat('Total Duration',
                DurationParser.formatDuration(progress.totalDuration)),
            _buildStat('Watched',
                DurationParser.formatDuration(progress.watchedDuration)),
            _buildStat('Remaining',
                DurationParser.formatDuration(progress.remainingDuration)),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
