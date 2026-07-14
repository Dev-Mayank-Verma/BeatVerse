import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';

class _Ep {
  final int    id;
  final String title;
  final String artist;
  final String collection;
  final String url;
  final String art;
  final int    dur;
  final bool   isRaj;

  _Ep({required this.id, required this.title, required this.artist,
       required this.collection, required this.url, required this.art,
       required this.dur, this.isRaj = false});

  factory _Ep.fromJson(Map<String, dynamic> j, {bool isRaj = false}) => _Ep(
    id:         j['trackId']       as int?    ?? 0,
    title:      j['trackName']     as String? ?? 'Untitled',
    artist:     j['artistName']    as String? ?? '',
    collection: j['collectionName'] as String? ?? '',
    url:        j['episodeUrl']    as String? ?? '',
    art:        (j['artworkUrl600'] ?? j['artworkUrl160'] ?? '') as String,
    dur:        ((j['trackTimeMillis'] as num?) ?? 0) ~/ 1000,
    isRaj: isRaj,
  );

  Track toTrack() => Track(
    id: 'pod-$id', title: title,
    artist: artist.isNotEmpty ? artist : collection,
    duration: dur, thumbnail: art, streamOverride: url,
  );
}

const _topics = ['Featured','Raj Shamani','Bollywood','Cricket',
  'Hindi Comedy','Business','Motivation','True Crime','Tech','Health'];

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});
  @override State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  final _player = AudioPlayer();
  final _ctrl   = TextEditingController();
  String _topic = 'Featured';
  List<_Ep> _items = [];
  bool _loading = true;
  Track? _playing;
  bool  _isPlaying = false;
  final Map<String, List<_Ep>> _cache = {};

  @override
  void initState() {
    super.initState();
    _fetch('Featured');
    _player.playerStateStream.listen((s) {
      if (mounted) setState(() => _isPlaying = s.playing);
    });
  }

  @override
  void dispose() { _player.dispose(); _ctrl.dispose(); super.dispose(); }

  Future<List<_Ep>> _search(String term, {bool isRaj=false, int limit=50}) async {
    final uri = Uri.parse('https://itunes.apple.com/search').replace(
      queryParameters: {'media':'podcast','entity':'podcastEpisode',
        'country':'IN','limit':'$limit','term':term});
    final res = await http.get(uri);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['results'] as List<dynamic>? ?? [])
        .map((e) => _Ep.fromJson(e as Map<String, dynamic>, isRaj: isRaj))
        .where((e) => e.url.isNotEmpty)
        .toList();
  }

  Future<void> _fetch(String topic) async {
    setState(() => _loading = true);
    if (_cache.containsKey(topic)) {
      setState(() { _items = _cache[topic]!; _loading = false; }); return;
    }
    try {
      List<_Ep> results;
      if (topic == 'Featured') {
        final raj    = await _search('Raj Shamani podcast', isRaj: true, limit: 15);
        final others = await _search('Hindi podcast popular', limit: 35);
        results = [];
        int ri = 0, oi = 0;
        while (ri < raj.length || oi < others.length) {
          if (ri < raj.length && results.length % 3 == 0) results.add(raj[ri++]);
          else if (oi < others.length) results.add(others[oi++]);
          else if (ri < raj.length)   results.add(raj[ri++]);
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

  Future<void> _play(_Ep ep) async {
    final track = ep.toTrack();
    context.read<LibraryProvider>().addRecent(track);
    setState(() => _playing = track);
    try {
      await _player.setUrl(ep.url);
      await _player.play();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Podcasts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search podcasts…',
                hintStyle: const TextStyle(color: AppColors.mutedForeground),
                prefixIcon: const Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
                filled: true, fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (v) { if (v.trim().isNotEmpty) { _topic = v.trim(); _fetch(v.trim()); } },
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _topics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t  = _topics[i];
                  final on = t == _topic;
                  return ChoiceChip(
                    label: Text(t == 'Raj Shamani' ? '⭐ $t' : t,
                        style: const TextStyle(fontSize: 11.5)),
                    selected: on,
                    onSelected: (_) { _ctrl.clear(); setState(() => _topic = t); _fetch(t); },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(color: on ? Colors.black : AppColors.foreground),
                    shape: const StadiumBorder(),
                  );
                },
              ),
            ),
          ]),
        ),
        if (_playing != null) _miniPlayer(),
        const SizedBox(height: 10),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _items.isEmpty
                  ? const Center(child: Text('No episodes found.',
                      style: TextStyle(color: AppColors.mutedForeground)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _tile(_items[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _miniPlayer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(imageUrl: _playing!.thumbnail,
              width: 40, height: 40, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(_playing!.title, maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: AppColors.primary, size: 36),
          onPressed: () => _isPlaying ? _player.pause() : _player.play(),
        ),
      ]),
    );
  }

  Widget _tile(_Ep ep) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _play(ep),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ep.isRaj ? AppColors.accent.withOpacity(0.08) : AppColors.card.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: ep.isRaj ? Border.all(color: AppColors.accent.withOpacity(0.3)) : null,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(imageUrl: ep.art, width: 56, height: 56,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(width: 56, height: 56, color: AppColors.card)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (ep.isRaj) Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('⭐ Featured',
                  style: TextStyle(fontSize: 10, color: AppColors.accent)),
            ),
            Text(ep.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(ep.collection, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11.5)),
          ])),
        ]),
      ),
    );
  }
}
