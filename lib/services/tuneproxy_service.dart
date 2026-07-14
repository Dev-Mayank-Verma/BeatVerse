import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

/// Uses the user's own YouTube Data API v3 proxy (TuneProxy) for
/// search/trending metadata — real YouTube titles, thumbnails, channel names.
/// Audio playback is resolved separately via JamendoService since
/// YouTube's ToS prohibits re-hosting the audio stream (the proxy
/// docs say so explicitly). Result: real YouTube content discovery,
/// legal CC audio playback.
class TuneProxyService {
  static const _base = 'https://yt-proxy-api.lovable.app/api';
  final Map<String, _Cache> _cache = {};

  Future<List<Track>> search(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];
    return _fetch(
      '/search',
      {'q': query.trim(), 'maxResults': '$limit', 'type': 'video',
       'order': 'relevance', 'regionCode': 'IN'},
      'search:$query:$limit',
    );
  }

  Future<List<Track>> trending({int limit = 30}) async {
    final today = DateTime.now();
    return _fetch(
      '/trending',
      {'regionCode': 'IN', 'videoCategoryId': '10', 'maxResults': '$limit'},
      'trending:IN:${today.year}-${today.month}-${today.day}',
    );
  }

  Future<List<Track>> related(String videoId, {int limit = 20}) async {
    return _fetch(
      '/related',
      {'videoId': videoId, 'maxResults': '$limit'},
      'related:$videoId',
    );
  }

  Future<List<Track>> _fetch(
      String path, Map<String, String> params, String key) async {
    final hit = _cache[key];
    if (hit != null &&
        DateTime.now().difference(hit.time) < const Duration(minutes: 10)) {
      return hit.data;
    }
    final uri =
        Uri.parse('$_base$path').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('TuneProxy $path failed');

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>? ?? [];

    final tracks = items
        .map((item) => _toTrack(item as Map<String, dynamic>))
        .where((t) => t.id.isNotEmpty)
        .toList();

    _cache[key] = _Cache(tracks, DateTime.now());
    return tracks;
  }

  Track _toTrack(Map<String, dynamic> item) {
    // Search results have id.videoId; video/trending have id as string
    final idField = item['id'];
    final videoId = idField is Map
        ? (idField['videoId'] as String? ?? '')
        : (idField as String? ?? '');

    final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
    final thumbs  = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final thumb   = (thumbs['high'] ?? thumbs['medium'] ?? thumbs['default'])
        as Map<String, dynamic>?;

    // Duration from contentDetails if available
    int durationSec = 0;
    final cd = item['contentDetails'] as Map<String, dynamic>?;
    if (cd != null) {
      durationSec = _parseDuration(cd['duration'] as String? ?? '');
    }

    return Track(
      id: 'yt-$videoId',
      title: snippet['title'] as String? ?? 'Unknown',
      artist: snippet['channelTitle'] as String? ?? 'Unknown',
      duration: durationSec,
      thumbnail: thumb?['url'] as String? ?? '',
      streamOverride: null, // resolved by JamendoService at play time
    );
  }

  int _parseDuration(String iso) {
    // PT3M42S → 222 seconds
    final m = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(iso);
    if (m == null) return 0;
    final h = int.tryParse(m.group(1) ?? '0') ?? 0;
    final min = int.tryParse(m.group(2) ?? '0') ?? 0;
    final sec = int.tryParse(m.group(3) ?? '0') ?? 0;
    return h * 3600 + min * 60 + sec;
  }
}

class _Cache {
  final List<Track> data;
  final DateTime time;
  _Cache(this.data, this.time);
}
