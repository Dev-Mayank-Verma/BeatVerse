import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/track.dart';

/// Resolves a playable audio URL for any track.
/// Priority:
///   1. track.streamOverride (already set for Jamendo/podcast/offline tracks)
///   2. Jamendo search by title+artist (for YouTube metadata tracks)
class AudioResolver {
  static const _jamendoBase = 'https://api.jamendo.com/v3.0';
  static const _clientId = '49bc6654';
  static final Map<String, String?> _cache = {};

  static Future<String?> resolve(Track track) async {
    // Already has a URL (Jamendo, podcast, or offline)
    if (track.streamOverride != null && track.streamOverride!.isNotEmpty) {
      return track.streamOverride;
    }

    // YouTube metadata track — search Jamendo for matching audio
    final cacheKey = '${track.title}:${track.artist}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    final query = _buildQuery(track.title, track.artist);
    final uri = Uri.parse('$_jamendoBase/tracks/').replace(
      queryParameters: {
        'client_id': _clientId,
        'format': 'json',
        'limit': '1',
        'search': query,
        'audioformat': 'mp32',
        'order': 'relevance',
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final results = body['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final url = (results.first as Map)['audio'] as String?;
          if (url != null && url.isNotEmpty) {
            _cache[cacheKey] = url;
            return url;
          }
        }
      }
    } catch (_) {}

    _cache[cacheKey] = null;
    return null;
  }

  static String _buildQuery(String title, String artist) {
    // Strip common YouTube title junk: "(Official Video)", "| T-Series" etc
    final clean = title
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
        .replaceAll(RegExp(r'\|.*$'), '')
        .replaceAll(RegExp(
            r'\b(official|video|audio|lyrics|full|song|hd|4k|music)\b',
            caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '$clean $artist'.trim();
  }
}
