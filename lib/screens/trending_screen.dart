import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/tuneproxy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_row.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});
  @override State<TrendingScreen> createState() => _TrendingScreenState();
}

const _regions = [
  ['IN', '🇮🇳 India'],
  ['US', '🇺🇸 Global'],
  ['GB', '🇬🇧 UK'],
  ['KR', '🇰🇷 K-Pop'],
];

class _TrendingScreenState extends State<TrendingScreen> {
  final _api = TuneProxyService();
  String _region = 'IN';
  late Future<List<Track>> _top;
  late Future<List<Track>> _bollywood;
  late Future<List<Track>> _punjabi;

  @override void initState() { super.initState(); _load(); }

  void _load() {
    final y = DateTime.now().year;
    _top      = _api.trending();
    _bollywood= _api.search('Bollywood top songs $y');
    _punjabi  = _api.search('Punjabi top songs $y');
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Icon(Icons.local_fire_department, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('Trending', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Track>>(
          future: _top,
          builder: (_, s) => SectionRow(
            title: '🔥 Top in India right now',
            tracks: s.data, loading: s.connectionState == ConnectionState.waiting),
        ),
        FutureBuilder<List<Track>>(
          future: _bollywood,
          builder: (_, s) => SectionRow(
            title: '🎬 Bollywood charts',
            tracks: s.data, loading: s.connectionState == ConnectionState.waiting),
        ),
        FutureBuilder<List<Track>>(
          future: _punjabi,
          builder: (_, s) => SectionRow(
            title: '🎵 Punjabi hits',
            tracks: s.data, loading: s.connectionState == ConnectionState.waiting),
        ),
        const SizedBox(height: 100),
      ],
    ),
  );
}
