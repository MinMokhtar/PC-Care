import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

/// A single video returned from YouTube search.
class YoutubeVideo {
  final String id;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String duration; // formatted like "5:42" or "1:02:15"

  const YoutubeVideo({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.duration,
  });

  /// Direct link to the video on YouTube.
  String get watchUrl => 'https://www.youtube.com/watch?v=$id';
}

/// Sort order for YouTube search results.
enum YoutubeSortOrder { relevance, viewCount, date, rating }

extension YoutubeSortOrderX on YoutubeSortOrder {
  /// Maps to YouTube API `order=` parameter value.
  String get apiValue {
    switch (this) {
      case YoutubeSortOrder.relevance:
        return 'relevance';
      case YoutubeSortOrder.viewCount:
        return 'viewCount';
      case YoutubeSortOrder.date:
        return 'date';
      case YoutubeSortOrder.rating:
        return 'rating';
    }
  }

  String get label {
    switch (this) {
      case YoutubeSortOrder.relevance:
        return 'Relevance';
      case YoutubeSortOrder.viewCount:
        return 'Most Viewed';
      case YoutubeSortOrder.date:
        return 'Newest';
      case YoutubeSortOrder.rating:
        return 'Highest Rated';
    }
  }
}

/// Duration filter for YouTube search results.
enum YoutubeDuration { any, short, medium, long }

extension YoutubeDurationX on YoutubeDuration {
  /// Maps to YouTube API `videoDuration=` parameter value.
  String get apiValue {
    switch (this) {
      case YoutubeDuration.any:
        return 'any';
      case YoutubeDuration.short:
        return 'short';
      case YoutubeDuration.medium:
        return 'medium';
      case YoutubeDuration.long:
        return 'long';
    }
  }

  String get label {
    switch (this) {
      case YoutubeDuration.any:
        return 'Any duration';
      case YoutubeDuration.short:
        return 'Short (<4 min)';
      case YoutubeDuration.medium:
        return 'Medium (4–20 min)';
      case YoutubeDuration.long:
        return 'Long (>20 min)';
    }
  }
}

/// Wraps YouTube Data API v3 calls used by the guides feature.
class YoutubeService {
  static const String _searchEndpoint =
      'https://www.googleapis.com/youtube/v3/search';
  static const String _videosEndpoint =
      'https://www.googleapis.com/youtube/v3/videos';

  /// Searches YouTube for tutorials related to [query].
  /// Returns up to [maxResults] videos sorted by [order] and filtered by [duration].
  Future<List<YoutubeVideo>> search(
    String query, {
    int maxResults = 10,
    YoutubeSortOrder order = YoutubeSortOrder.relevance,
    YoutubeDuration duration = YoutubeDuration.any,
  }) async {
    final searchUri = Uri.parse(_searchEndpoint).replace(queryParameters: {
      'part': 'snippet',
      'q': query,
      'type': 'video',
      'maxResults': '$maxResults',
      'order': order.apiValue,
      'videoDuration': duration.apiValue,
      'key': ApiKeys.youtubeDataApi,
    });

    final searchRes = await http.get(searchUri);
    if (searchRes.statusCode != 200) {
      throw YoutubeApiException(
        'Search failed (${searchRes.statusCode})',
        searchRes.body,
      );
    }

    final searchJson = json.decode(searchRes.body) as Map<String, dynamic>;
    final items = (searchJson['items'] as List?) ?? const [];
    if (items.isEmpty) return const [];

    // Collect IDs so we can ask for durations in one extra call.
    final ids = <String>[];
    final partial = <String, Map<String, String>>{};
    for (final item in items) {
      final id = (item['id']?['videoId'] as String?) ?? '';
      if (id.isEmpty) continue;
      final snippet = item['snippet'] as Map<String, dynamic>? ?? const {};
      final thumbs = snippet['thumbnails'] as Map<String, dynamic>? ?? const {};
      final medium = thumbs['medium'] as Map<String, dynamic>? ?? const {};
      final high = thumbs['high'] as Map<String, dynamic>? ?? const {};
      final thumbUrl = (high['url'] ?? medium['url'] ?? '') as String;

      ids.add(id);
      partial[id] = {
        'title': (snippet['title'] ?? '') as String,
        'channel': (snippet['channelTitle'] ?? '') as String,
        'thumb': thumbUrl,
      };
    }

    if (ids.isEmpty) return const [];

    // Second call: fetch durations (ISO 8601) for the IDs above.
    final videosUri = Uri.parse(_videosEndpoint).replace(queryParameters: {
      'part': 'contentDetails',
      'id': ids.join(','),
      'key': ApiKeys.youtubeDataApi,
    });
    final videosRes = await http.get(videosUri);
    if (videosRes.statusCode != 200) {
      throw YoutubeApiException(
        'Videos lookup failed (${videosRes.statusCode})',
        videosRes.body,
      );
    }

    final videosJson = json.decode(videosRes.body) as Map<String, dynamic>;
    final videoItems = (videosJson['items'] as List?) ?? const [];
    final durations = <String, String>{};
    for (final v in videoItems) {
      final id = (v['id'] as String?) ?? '';
      final iso = (v['contentDetails']?['duration'] as String?) ?? '';
      durations[id] = _formatDuration(iso);
    }

    // Merge — keep original search order so "relevance" is preserved.
    return ids.map((id) {
      final p = partial[id]!;
      return YoutubeVideo(
        id: id,
        title: p['title']!,
        channelTitle: p['channel']!,
        thumbnailUrl: p['thumb']!,
        duration: durations[id] ?? '',
      );
    }).toList();
  }

  /// Converts ISO 8601 duration ("PT1H2M3S") into "1:02:03" / "2:03".
  static String _formatDuration(String iso) {
    final m = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(iso);
    if (m == null) return '';
    final h = int.tryParse(m.group(1) ?? '') ?? 0;
    final mi = int.tryParse(m.group(2) ?? '') ?? 0;
    final s = int.tryParse(m.group(3) ?? '') ?? 0;
    String two(int n) => n.toString().padLeft(2, '0');
    if (h > 0) return '$h:${two(mi)}:${two(s)}';
    return '$mi:${two(s)}';
  }
}

class YoutubeApiException implements Exception {
  final String message;
  final String body;
  YoutubeApiException(this.message, this.body);
  @override
  String toString() => 'YoutubeApiException: $message';
}
