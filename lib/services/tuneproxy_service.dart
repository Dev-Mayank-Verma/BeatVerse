import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class TuneProxyService {
  static const _base = 'https://yt-proxy-api.lovable.app/api';
  final Map<String, _Cache> _cache = {};
  static const _ttl = Duration(minutes: 15);

  Future<List<Track>> search(String q, {int limit = 30}) {
    if (q.trim().isEmpty) return Future.value([]);
    return _fetch('/search', {
      'q': q.trim(), 'maxResults': '$limit',
      'type': 'video', 'order': 'relevance', 'regionCode': 'IN',
    }, 'search:$q');
  }

  Future<List<Track>> trending({int limit = 30}) {
    final d = DateTime.now();
    return _fetch('/trending', {
      'regionCode': 'IN', 'videoCategoryId': '10', 'maxResults': '$limit',
    }, 'trending:${d.year}-${d.month}-${d.day}');
  }

  Future<List<Track>> related(String videoId, {int limit = 20}) =>
      _fetch('/related', {'videoId': videoId, 'maxResults': '$limit'},
          'related:$videoId');

  Future<List<Track>> _fetch(
      String path, Map<String, String> params, String key) async {
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.time) < _ttl) {
      return hit.data;
    }
    final uri = Uri.parse('$_base$path').replace(queryParameters: params);
    final res  = await http.get(uri);
    if (res.statusCode != 200) throw Exception('TuneProxy error');

    final body  = jsonDecode(res.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>? ?? [];
    final tracks = items
        .map((e) => _parse(e as Map<String, dynamic>))
        .where((t) => t.id != 'yt-' && t.title.isNotEmpty)
        .toList();

    _cache[key] = _Cache(tracks, DateTime.now());
    return tracks;
  }

  Track _parse(Map<String, dynamic> item) {
    final idField = item['id'];
    final videoId = idField is Map
        ? (idField['videoId'] as String? ?? '')
        : (idField as String? ?? '');
    final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
    final thumbs  = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final thumb   =
        (thumbs['maxres'] ?? thumbs['high'] ?? thumbs['medium'] ?? thumbs['default'])
            as Map<String, dynamic>?;
    int dur = 0;
    final cd = item['contentDetails'] as Map<String, dynamic>?;
    if (cd != null) dur = _iso(cd['duration'] as String? ?? '');
    return Track(
      id: 'yt-$videoId',
      title: (snippet['title'] as String? ?? '').replaceAll('&amp;', '&')
          .replaceAll('&#39;', "'").replaceAll('&quot;', '"'),
      artist: snippet['channelTitle'] as String? ?? '',
      duration: dur,
      thumbnail: thumb?['url'] as String? ?? '',
    );
  }

  int _iso(String s) {
    final m = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(s);
    if (m == null) return 0;
    return (int.tryParse(m.group(1) ?? '0') ?? 0) * 3600 +
           (int.tryParse(m.group(2) ?? '0') ?? 0) * 60 +
           (int.tryParse(m.group(3) ?? '0') ?? 0);
  }
}

class _Cache { final List<Track> data; final DateTime time;
  _Cache(this.data, this.time); }
