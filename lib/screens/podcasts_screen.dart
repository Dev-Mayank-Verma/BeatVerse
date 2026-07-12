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
  final bool isRajShamani;

  _Episode({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.collectionName,
    required this.episodeUrl,
    required this.artwork,
    required this.durationSec,
    this.isRajShamani = false,
  });

  factory _Episode.fromJson(Map<String, dynamic> j,
      {bool isRaj = false}) =>
      _Episode(
        trackId: j['trackId'] as int? ?? 0,
        trackName: j['trackName'] as String? ?? 'Untitled',
        artistName: j['artistName'] as String? ?? '',
        collectionName: j['collectionName'] as String? ?? '',
        episodeUrl: j['episodeUrl'] as String? ?? '',
        artwork:
            (j['artworkUrl600'] ?? j['artworkUrl160'] ?? '') as String,
        durationSec:
            ((j['trackTimeMillis'] as num?) ?? 0) ~/ 1000,
        isRajShamani: isRaj,
      );
}

const _topics = [
  'Featured', 'Raj Shamani', 'Bollywood', 'Cricket',
  'Hindi Comedy', 'Business', 'Motivation', 'True Crime',
  'Tech', 'Spirituality', 'Health', 'News',
];

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});
  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  String _topic = 'Featured';
  final _ctrl = TextEditingController();
  List<_Episode> _items = [];
  bool _loading = true;
  final Map<String, List<_Episode>> _cache = {};

  @override
  void initState() {
    super.initState();
    _fetch('Featured');
  }

  Future<List<_Episode>> _search(String term,
      {bool isRaj = false, int limit = 50}) async {
    final uri =
        Uri.parse('https://itunes.apple.com/search').replace(
      queryParameters: {
        'media': 'podcast',
        'entity': 'podcastEpisode',
        'country': 'IN',
        'limit': '$limit',
        'term': term,
      },
    );
    final res = await http.get(uri);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['results'] as List<dynamic>? ?? [])
        .map((e) =>
            _Episode.fromJson(e as Map<String, dynamic>, isRaj: isRaj))
        .toList();
  }

  Future<void> _fetch(String topic) async {
    setState(() => _loading = true);
    if (_cache.containsKey(topic)) {
      setState(() {
        _items = _cache[topic]!;
        _loading = false;
      });
      return;
    }
    try {
      List<_Episode> results;

      if (topic == 'Featured') {
        // Raj Shamani 40% priority — fetch his episodes first
        final raj = await _search('Raj Shamani podcast', isRaj: true, limit: 20);
        final others = await _search('Hindi podcast India', limit: 30);
        // Interleave: 40% raj, 60% others
        results = [];
        int ri = 0, oi = 0;
        while (ri < raj.length || oi < others.length) {
          // 2 others then 1 raj = ~33%, bump to 40%: 3 raj per 5 = 3:2 raj:other
          if (ri < raj.length && results.length % 5 < 2) {
            results.add(raj[ri++]);
          } else if (oi < others.length) {
            results.add(others[oi++]);
          } else if (ri < raj.length) {
            results.add(raj[ri++]);
          }
        }
      } else if (topic == 'Raj Shamani') {
        results = await _search('Raj Shamani', isRaj: true, limit: 50);
      } else {
        results = await _search(topic, limit: 50);
      }

      _cache[topic] = results;
      if (mounted) setState(() => _items = results);
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
      artist: ep.artistName.isNotEmpty
          ? ep.artistName
          : ep.collectionName,
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
            Row(children: [
              Icon(Icons.mic, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text('Podcasts',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              style: TextStyle(color: AppColors.foreground, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search podcasts…',
                hintStyle:
                    TextStyle(color: AppColors.mutedForeground),
                prefixIcon: Icon(Icons.search,
                    color: AppColors.mutedForeground, size: 20),
                filled: true,
                fillColor: AppColors.card,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                _ctrl.text = v.trim();
                _fetch(v.trim());
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _topics.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final t = _topics[i];
                  final active = t == _topic;
                  final isRaj = t == 'Raj Shamani';
                  return ChoiceChip(
                    label: Text(
                      isRaj ? '⭐ $t' : t,
                      style: TextStyle(fontSize: 11.5),
                    ),
                    selected: active,
                    onSelected: (_) {
                      _ctrl.clear();
                      setState(() => _topic = t);
                      _fetch(t);
                    },
                    selectedColor: isRaj
                        ? AppColors.accent
                        : AppColors.primary,
                    backgroundColor: AppColors.secondary,
                    labelStyle: TextStyle(
                        color: active
                            ? Colors.white
                            : AppColors.foreground),
                    shape: const StadiumBorder(),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _items.isEmpty
                      ? Text('No episodes found.',
                          style: TextStyle(
                              color: AppColors.mutedForeground))
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final ep = _items[i];
                            return InkWell(
                              borderRadius:
                                  BorderRadius.circular(12),
                              onTap: () => _play(ep),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: ep.isRajShamani
                                      ? AppColors.accent
                                          .withOpacity(0.08)
                                      : AppColors.card
                                          .withOpacity(0.6),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: ep.isRajShamani
                                      ? Border.all(
                                          color: AppColors.accent
                                              .withOpacity(0.3))
                                      : null,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: Image.network(
                                        ep.artwork,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                                width: 56,
                                                height: 56,
                                                color: AppColors.muted),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (ep.isRajShamani)
                                            Container(
                                              margin:
                                                  const EdgeInsets
                                                      .only(bottom: 4),
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        4),
                                              ),
                                              child: Text('⭐ Featured',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          AppColors.accent)),
                                            ),
                                          Text(ep.trackName,
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          const SizedBox(height: 3),
                                          Text(ep.collectionName,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: AppColors
                                                      .mutedForeground,
                                                  fontSize: 11.5)),
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
