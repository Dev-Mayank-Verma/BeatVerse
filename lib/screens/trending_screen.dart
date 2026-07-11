import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/jamendo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_row.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});
  @override State<TrendingScreen> createState() => _TrendingScreenState();
}

const _tags = [
  ['All',        ''],
  ['Pop',        'pop'],
  ['Electronic', 'electronic'],
  ['Rock',       'rock'],
  ['Hip-Hop',    'hiphop'],
  ['Lofi',       'lofi'],
  ['Ambient',    'ambient'],
  ['Jazz',       'jazz'],
];

class _TrendingScreenState extends State<TrendingScreen> {
  final _api = JamendoService();
  String _tag = '';
  late Future<List<Track>> _top;
  late Future<List<Track>> _new;

  @override
  void initState() { super.initState(); _load(); }

  void _load() {
    final t = _tag.isEmpty ? null : _tag;
    _top = _api.trending(tag: t);
    _new = _api.newReleases();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Icon(Icons.local_fire_department, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text('Trending Now', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final t = _tags[i];
                final active = _tag == t[1];
                return ChoiceChip(
                  label: Text(t[0]),
                  selected: active,
                  onSelected: (_) => setState(() { _tag = t[1]; _load(); }),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.secondary,
                  labelStyle: TextStyle(
                      color: active ? AppColors.background : AppColors.foreground,
                      fontSize: 12),
                  shape: const StadiumBorder(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Track>>(
            future: _top,
            builder: (context, snap) => SectionRow(
              title: _tag.isEmpty ? '🔥 Top overall' : '🔥 Top in ${_tag}',
              tracks: snap.data,
              loading: snap.connectionState == ConnectionState.waiting,
            ),
          ),
          FutureBuilder<List<Track>>(
            future: _new,
            builder: (context, snap) => SectionRow(
              title: '✨ Latest releases',
              tracks: snap.data,
              loading: snap.connectionState == ConnectionState.waiting,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
