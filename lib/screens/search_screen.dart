import 'dart:async';
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/tuneproxy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/track_row.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}

class _Chip { final String label; final String query; final int grad;
  const _Chip(this.label, this.query, this.grad); }

final _chips = [
  const _Chip('Arijit Singh',  'arijit singh songs',     0),
  const _Chip('Bollywood',     'bollywood hits 2025',     1),
  const _Chip('Punjabi',       'punjabi top songs',       2),
  const _Chip('K-Pop',         'kpop bts blackpink',      3),
  const _Chip('English',       'english pop hits',        4),
  const _Chip('Lofi',          'lofi hindi chill',        5),
  const _Chip('Romantic',      'romantic hindi songs',    0),
  const _Chip('Workout',       'gym workout music',       1),
];

class _SearchScreenState extends State<SearchScreen> {
  final _api  = TuneProxyService();
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Track> _results = [];
  bool   _loading = false;
  String? _error;

  @override
  void dispose() { _debounce?.cancel(); _ctrl.dispose(); super.dispose(); }

  void _onChanged(String v) {
    setState(() {});
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() { _results = []; _loading = false; _error = null; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final r = await _api.search(v.trim());
        if (!mounted) return;
        setState(() { _results = r; _loading = false; });
      } catch (_) {
        if (!mounted) return;
        setState(() { _error = 'Search failed. Check internet.'; _loading = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _ctrl.text.trim().isNotEmpty;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _ctrl,
            onChanged: _onChanged,
            style: TextStyle(color: AppColors.foreground),
            decoration: InputDecoration(
              hintText: 'Songs, artists, albums…',
              hintStyle: TextStyle(color: AppColors.mutedForeground),
              prefixIcon: Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
              filled: true, fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: hasQuery ? _buildResults() : _buildBrowse()),
        ]),
      ),
    );
  }

  Widget _buildBrowse() => GridView.builder(
    itemCount: _chips.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5),
    itemBuilder: (ctx, i) {
      final c = _chips[i];
      return Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () { _ctrl.text = c.query; _onChanged(c.query); },
          child: Container(
            padding: const EdgeInsets.all(14), alignment: Alignment.topLeft,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: AppColors.vibeGradients[c.grad],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Text(c.label, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
          ),
        ),
      );
    },
  );

  Widget _buildResults() {
    if (_loading) return ListView.separated(
      itemCount: 8, separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(height: 52,
          decoration: BoxDecoration(color: Colors.white10,
              borderRadius: BorderRadius.circular(10))));
    if (_error != null) return Text(_error!,
        style: TextStyle(color: AppColors.destructive));
    if (_results.isEmpty) return Text('No results.',
        style: TextStyle(color: AppColors.mutedForeground));
    return ListView.builder(
      itemCount: _results.length + 1,
      itemBuilder: (ctx, i) {
        if (i == _results.length) return const SizedBox(height: 100);
        return TrackRow(track: _results[i], index: i, queue: _results, showIndex: true);
      },
    );
  }
}
