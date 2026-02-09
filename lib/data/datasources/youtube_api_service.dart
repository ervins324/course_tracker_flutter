// lib/data/datasources/youtube_api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/video_model.dart';

class YouTubeApiService {
  final String apiKey;
  final http.Client client;

  YouTubeApiService({required this.apiKey, required this.client});

  Future<List<VideoModel>> fetchPlaylistVideos(String playlistId) async {
    try {
      final videos = <VideoModel>[];
      String? nextPageToken;
      int positionOffset = 0;

      do {
        final url =
            Uri.parse('https://www.googleapis.com/youtube/v3/playlistItems'
                '?part=snippet,contentDetails'
                '&playlistId=$playlistId'
                '&maxResults=50'
                '&key=$apiKey'
                '${nextPageToken != null ? '&pageToken=$nextPageToken' : ''}');

        final response = await client.get(url);

        if (response.statusCode != 200) {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['error']?['message'] ?? 'Unknown error';
          throw Exception(
              'Failed to load playlist: $errorMessage (Status: ${response.statusCode})');
        }

        final data = json.decode(response.body);
        final items = data['items'] as List;

        if (items.isEmpty) {
          throw Exception('Playlist is empty or not found');
        }

        // Build a map of videoId -> position from playlist items (preserves order)
        final videoIdToPosition = <String, int>{};
        for (int i = 0; i < items.length; i++) {
          final videoId = items[i]['contentDetails']['videoId'] as String;
          videoIdToPosition[videoId] = positionOffset + i;
        }

        final videoIds = items
            .map((item) => item['contentDetails']['videoId'] as String)
            .join(',');

        final videosData =
            await _fetchVideoDetails(videoIds, videoIdToPosition);
        videos.addAll(videosData);

        positionOffset += items.length;
        nextPageToken = data['nextPageToken'];
      } while (nextPageToken != null);

      // Sort by position to ensure correct order
      videos.sort((a, b) => a.position.compareTo(b.position));
      return videos;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<VideoModel>> _fetchVideoDetails(
      String videoIds, Map<String, int> videoIdToPosition) async {
    final url = Uri.parse('https://www.googleapis.com/youtube/v3/videos'
        '?part=snippet,contentDetails'
        '&id=$videoIds'
        '&key=$apiKey');

    final response = await client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load video details');
    }

    final data = json.decode(response.body);
    final items = data['items'] as List;

    return items.map((item) {
      final duration = item['contentDetails']['duration'] as String;
      final videoId = item['id'] as String;
      final position = videoIdToPosition[videoId] ?? 0;
      return VideoModel.fromJson(item, duration, position: position);
    }).toList();
  }
}
