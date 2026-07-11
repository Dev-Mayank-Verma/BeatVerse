import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

class _Episode {
  final int trackId;
  final String trackName;
  final String artistName;
  final String collectionName;
  final String episodeUrl;
  final String artwork;
  final int durationSec;

  _Episode({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.collectionName,
    required this.episodeUrl,
    required this.artwork,
    required this.durationSec,
  });

  factory _Episode.fromJson(Map<String, dynamic> j) => _Episode(
        trackId: j['trackId'] as int? ?? 0,
        trackName: j['trackName'] as String? ?? 'Untitled episode',
        artistName: j['artistName'] as String? ?? '',
        collectionName: j['collectionName'] as String? ?? '',
        episodeUrl: j['episodeUrl'] as String? ?? '',
        artwork: (j['artworkUrl600'] ?? j['artworkUrl160'] ?? '') as String,
        durationSec: ((j['trackTimeMillis'] as num?) ?? 0) ~/ 1000,
      );
}

const _topics = [
  'Bollywood', 'Cricket', 'Hindi Comedy', 'Indian Business', 'Motivation Hindi',
  'True Crime India', 'Tech India', 'Spirituality', 'Health India', 'News India',
  'Education', 'Startup India',
];

/// Ports src/pages/Podcasts.tsx — this one's fully legitimate as-is: it
/// already uses Apple's public, no-auth-required podcast search API for
/// both browsing AND playback (podcast episode files are meant for open
/// public distribution by their creators), so unlike the music screens
/// there's no source substitution needed here.
class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  String _topic = 'Bollywood';
  final _searchController = TextEditingController();
  List<_Episode> _items = [];
  bool _loading = true;
  final Map<String, List<_Episode>> _cache = {};

  @override
  void initState() {
    super.initState();
    _fetch(_topic);
  }

  Future<void> _fetch(String term) async {
    setState(() => _loading = true);
    if (_cache.containsKey(term)) {
      setState(() {
        _items = _cache[term]!;
        _loading = false;
      });
      return;
    }
    try {
      final uri = Uri.parse('https://itunes.apple.com/search').replace(queryParameters: {
        'media': 'podcast',
        'entity': 'podcastEpisode',
        'country': 'IN',
        'limit': '50',
        'term': term,
      });
      final res = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['results'] as List<dynamic>? ?? [])
          .map((e) => _Episode.fromJson(e as Map<String, dynamic>))
          .toList();
      _cache[term] = list;
      if (mounted) setState(() => _items = list);
    } catch (_) {
      if (mounted) setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _play(_Episode ep) {
    final track = Track(
      id: 'pod-${ep.trackId}',
      title: ep.trackName,
      artist: ep.artistName.isNotEmpty ? ep.artistName : ep.collectionName,
      duration: ep.durationSec,
      thumbnail: ep.artwork,
      streamOverride: ep.episodeUrl,
    );
    context.read<PlayerProvider>().playTrack(track);
    context.read<LibraryProvider>().addRecent(track);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text('Podcasts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.foreground, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search podcasts…',
                hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onSubmitted: (v) => _fetch(v.trim().isEmpty ? _topic : v.trim()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _topics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final t = _topics[i];
                  final active = t == _topic && _searchController.text.isEmpty;
                  return ChoiceChip(
                    label: Text(t, style: const TextStyle(fontSize: 11.5)),
                    selected: active,
                    onSelected: (_) {
                      _searchController.clear();
                      setState(() => _topic = t);
                      _fetch(t);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.secondary,
                    labelStyle: TextStyle(color: active ? AppColors.background : AppColors.foreground),
                    shape: const StadiumBorder(),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _items.isEmpty
                      ? Text('No episodes found.', style: TextStyle(color: AppColors.mutedForeground))
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final ep = _items[i];
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _play(ep),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.card.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        ep.artwork,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(width: 56, height: 56, color: AppColors.muted),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(ep.trackName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 3),
                                          Text(ep.collectionName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: AppColors.mutedForeground, fontSize: 11.5)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
