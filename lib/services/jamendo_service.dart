import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/artist_result.dart';
import '../models/track.dart';

/// BeatVerse's primary music source — Jamendo's public API.
///
/// Jamendo hosts 600 000+ Creative Commons–licensed tracks by independent
/// artists. Every track returned here has a *direct, full-length MP3 stream
/// URL* in the `audio` field (192 kbps mp3), which is stored in
/// Track.streamOverride so the audio handler plays it without any extra
/// network hop.
///
/// License: all tracks are CC-licensed — attribution to artists is included
/// in every Track.artist field. Commercial use requires Jamendo's paid
/// licensing; this is a personal/educational app, covered by the
/// non-commercial CC terms.
///
/// Client ID: register free at https://devportal.jamendo.com — takes 30 s,
/// gives you your own quota. Replace [_clientId] with your own key.
class JamendoService {
  // ─── Replace with your own free key from devportal.jamendo.com ───────────
  static const _clientId = '49bc6654';
  // ─────────────────────────────────────────────────────────────────────────

  static const _base = 'https://api.jamendo.com/v3.0';
  static const _audioFmt = 'mp32'; // 192 kbps — best quality the free API offers

  // In-memory cache keyed by request URL; TTL per entry.
  final Map<String, _CacheEntry<List<Track>>> _cache = {};
  final Map<String, _CacheEntry<ArtistResult>> _artistCache = {};
  static const _ttl = Duration(minutes: 10);

  // ── Public methods ────────────────────────────────────────────────────────

  /// Full-text search across title, artist, album, tags.
  Future<List<Track>> search(String query, {int limit = 30}) {
    final q = query.trim();
    if (q.isEmpty) return Future.value([]);
    return _tracks(
      params: {
        'search': q,
        'limit': '$limit',
        'order': 'relevance',
        'audioformat': _audioFmt,
        'include': 'musicinfo',
      },
      cacheKey: 'search:$q:$limit',
    );
  }

  /// Top tracks overall or by tag (e.g. 'pop', 'lofi', 'electronic').
  /// Cache is keyed to today's date so it auto-refreshes daily.
  Future<List<Track>> trending({String? tag, int limit = 30}) {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    return _tracks(
      params: {
        if (tag != null) 'tags': tag,
        'limit': '$limit',
        'order': 'popularity_total_desc',
        'audioformat': _audioFmt,
        'include': 'musicinfo',
        'boost': 'popularity_total',
      },
      cacheKey: 'trending:${tag ?? "all"}:$dateKey',
    );
  }

  /// Tracks tagged with a specific genre/mood.
  Future<List<Track>> byTag(String tag, {int limit = 30}) {
    return _tracks(
      params: {
        'tags': tag,
        'limit': '$limit',
        'order': 'popularity_total_desc',
        'audioformat': _audioFmt,
      },
      cacheKey: 'tag:$tag:$limit',
    );
  }

  /// Top tracks this week (buzztrack).
  Future<List<Track>> newReleases({int limit = 30}) {
    return _tracks(
      params: {
        'limit': '$limit',
        'order': 'releasedate_desc',
        'audioformat': _audioFmt,
        'datebetween': _thisMonthRange(),
      },
      cacheKey: 'new:$limit:${DateTime.now().month}',
    );
  }

  /// All top tracks by an artist name.
  Future<ArtistResult> getArtist(String name) async {
    final key = 'artist:$name';
    final hit = _artistCache[key];
    if (hit != null && DateTime.now().difference(hit.time) < _ttl) return hit.data;

    // Step 1 — find artist id + image
    final artistUri = Uri.parse('$_base/artists/').replace(queryParameters: {
      'client_id': _clientId,
      'format': 'json',
      'name': name,
      'limit': '1',
    });
    final artistRes = await http.get(artistUri);
    String? thumbnail;
    if (artistRes.statusCode == 200) {
      final d = jsonDecode(artistRes.body) as Map<String, dynamic>;
      final results = d['results'] as List<dynamic>?;
      if (results != null && results.isNotEmpty) {
        thumbnail = (results.first as Map<String, dynamic>)['image'] as String?;
      }
    }

    // Step 2 — top tracks
    final tracks = await _tracks(
      params: {
        'artist_name': name,
        'limit': '30',
        'order': 'popularity_total_desc',
        'audioformat': _audioFmt,
      },
      cacheKey: 'artisttracks:$name',
    );

    // Fallback: if exact-name match returns 0, try search
    final topTracks = tracks.isNotEmpty ? tracks : await search(name, limit: 20);
    final result = ArtistResult(name: name, thumbnail: thumbnail, topTracks: topTracks);
    _artistCache[key] = _CacheEntry(result, DateTime.now());
    return result;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<Track>> _tracks({
    required Map<String, String> params,
    required String cacheKey,
  }) async {
    final hit = _cache[cacheKey];
    if (hit != null && DateTime.now().difference(hit.time) < _ttl) return hit.data;

    final uri = Uri.parse('$_base/tracks/').replace(queryParameters: {
      'client_id': _clientId,
      'format': 'json',
      ...params,
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Jamendo API failed: ${res.statusCode}');

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if ((body['headers'] as Map)['status'] != 'success') {
      throw Exception('Jamendo: ${(body['headers'] as Map)['error_message']}');
    }

    final tracks = (body['results'] as List<dynamic>)
        .map((j) => _toTrack(j as Map<String, dynamic>))
        .where((t) => t.streamOverride != null && t.streamOverride!.isNotEmpty)
        .toList();

    _cache[cacheKey] = _CacheEntry(tracks, DateTime.now());
    return tracks;
  }

  Track _toTrack(Map<String, dynamic> j) => Track(
        id: 'jam-${j['id']}',
        title: j['name'] as String? ?? 'Untitled',
        artist: j['artist_name'] as String? ?? 'Unknown artist',
        duration: (j['duration'] as num?)?.toInt() ?? 0,
        thumbnail: (j['image'] as String?)?.isNotEmpty == true
            ? j['image'] as String
            : (j['album_image'] as String? ?? ''),
        streamOverride: j['audio'] as String?, // ← FULL-LENGTH MP3
      );

  String _thisMonthRange() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - 1, 1);
    return '${from.year}-${from.month.toString().padLeft(2, '0')}-01'
        '_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day}';
  }
}

class _CacheEntry<T> {
  final T data;
  final DateTime time;
  _CacheEntry(this.data, this.time);
}
