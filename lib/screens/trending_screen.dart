import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/tuneproxy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_row.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});
  @override State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final _api = TuneProxyService();
  late Future<List<Track>> _top;
  late Future<List<Track>> _bollywood;
  late Future<List<Track>> _punjabi;
  late Future<List<Track>> _english;

  @override
  void initState() {
    super.initState();
    final y = DateTime.now().year;
    _top      = _api.trending();
    _bollywood= _api.search('bollywood viral songs $y');
    _punjabi  = _api.search('punjabi hits $y');
    _english  = _api.search('english viral songs $y');
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
            const Icon(Icons.local_fire_department,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            const Text('Trending', style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Track>>(future: _top,
            builder: (_, s) => SectionRow(title: '🔥 Top in India',
                tracks: s.data,
                loading: s.connectionState == ConnectionState.waiting)),
        FutureBuilder<List<Track>>(future: _bollywood,
            builder: (_, s) => SectionRow(title: '🎬 Bollywood Viral',
                tracks: s.data,
                loading: s.connectionState == ConnectionState.waiting)),
        FutureBuilder<List<Track>>(future: _punjabi,
            builder: (_, s) => SectionRow(title: '🎵 Punjabi Charts',
                tracks: s.data,
                loading: s.connectionState == ConnectionState.waiting)),
        FutureBuilder<List<Track>>(future: _english,
            builder: (_, s) => SectionRow(title: '🌍 English Viral',
                tracks: s.data,
                loading: s.connectionState == ConnectionState.waiting)),
        const SizedBox(height: 100),
      ],
    ),
  );
}
