import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

class _LyricLine {
  final double time;
  final String text;
  _LyricLine(this.time, this.text);
}

/// Ports src/components/player/Lyrics.tsx — synced/plain lyrics from
/// lrclib.net, a free open lyrics database built for exactly this kind of
/// third-party lookup (unlike the audio-extraction endpoints elsewhere in
/// this project, there's no access-control circumvention here).
class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  List<_LyricLine>? _synced;
  String? _plain;
  bool _loading = false;
  String? _loadedForId;

  List<_LyricLine> _parseLrc(String lrc) {
    final lines = <_LyricLine>[];
    final re = RegExp(r'^\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\](.*)$');
    for (final raw in lrc.split('\n')) {
      final m = re.firstMatch(raw.trim());
      if (m == null) continue;
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final ms = m.group(3) != null ? int.parse(m.group(3)!.padRight(3, '0')) : 0;
      lines.add(_LyricLine(min * 60 + sec + ms / 1000, m.group(4)!.trim()));
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  Future<Map<String, dynamic>?> _tryGet(String track, String artist, {int? dur}) async {
    final params = {'track_name': track, 'artist_name': artist};
    if (dur != null) params['duration'] = '$dur';
    final uri = Uri.parse('https://lrclib.net/api/get').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> _trySearch(String q) async {
    final uri = Uri.parse('https://lrclib.net/api/search')
        .replace(queryParameters: {'q': q});
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final arr = jsonDecode(res.body) as List<dynamic>;
    if (arr.isEmpty) return null;
    for (final item in arr) {
      final m = item as Map<String, dynamic>;
      if (m['syncedLyrics'] != null) return m;
    }
    return arr.first as Map<String, dynamic>;
  }

  Future<void> _load(String title, String artist, int duration) async {
    setState(() {
      _loading = true;
      _synced = null;
      _plain = null;
    });

    final cleanTitle = title
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(
            RegExp(r'\b(official|video|music|audio|lyrics?|hd|4k|full song|song|mv)\b',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'\s*[-|—–]\s*.*$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cleanArtist = artist.split(RegExp(r'[,&·•|]')).first.trim();

    try {
      final results = await Future.wait([
        _tryGet(cleanTitle, cleanArtist, dur: duration).catchError((_) => null),
        _tryGet(cleanTitle, cleanArtist).catchError((_) => null),
        _trySearch('$cleanTitle $cleanArtist').catchError((_) => null),
        _trySearch(cleanTitle).catchError((_) => null),
      ]);
      Map<String, dynamic>? withSynced;
      Map<String, dynamic>? withPlain;
      for (final r in results) {
        if (r == null) continue;
        if (withSynced == null && r['syncedLyrics'] != null) withSynced = r;
        if (withPlain == null && r['plainLyrics'] != null) withPlain = r;
      }
      final data = withSynced ?? withPlain;
      if (!mounted) return;
      if (data?['syncedLyrics'] != null) {
        setState(() => _synced = _parseLrc(data!['syncedLyrics'] as String));
      } else if (data?['plainLyrics'] != null) {
        setState(() => _plain = data!['plainLyrics'] as String);
      }
    } catch (_) {
      // Falls through to "no lyrics found" state below.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.current;
    if (track == null) return const SizedBox.shrink();

    if (_loadedForId != track.id) {
      _loadedForId = track.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _load(track.title, track.artist, track.duration);
      });
    }

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_synced != null) {
      final currentSec = player.position.inMilliseconds / 1000;
      var activeIdx = -1;
      for (var i = 0; i < _synced!.length; i++) {
        if (_synced![i].time <= currentSec + 0.6) {
          activeIdx = i;
        } else {
          break;
        }
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        itemCount: _synced!.length,
        itemBuilder: (context, i) {
          final active = i == activeIdx;
          final past = i < activeIdx;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              _synced![i].text.isEmpty ? '♪' : _synced![i].text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: active ? 19 : 16,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active
                    ? AppColors.primary
                    : past
                        ? AppColors.mutedForeground.withOpacity(0.4)
                        : AppColors.mutedForeground,
              ),
            ),
          );
        },
      );
    }

    if (_plain != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          _plain!,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.foreground.withOpacity(0.8), fontSize: 15),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No lyrics found for this track. Try another song!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
        ),
      ),
    );
  }
}
