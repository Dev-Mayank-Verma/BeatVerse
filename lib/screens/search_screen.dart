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

const _browseChips = [
  ['Bollywood', 'bollywood hindi songs', 0],
  ['Punjabi', 'punjabi top hits', 1],
  ['English', 'english top songs', 2],
  ['K-Pop', 'kpop songs', 3],
  ['Arijit Singh', 'arijit singh songs', 4],
  ['Lofi', 'lofi hip hop chill', 5],
  ['Romantic', 'romantic hindi songs', 0],
  ['Workout', 'workout gym music', 1],
  ['90s Hindi', '90s hindi songs', 2],
  ['Rap', 'hindi rap songs', 3],
];

class _SearchScreenState extends State<SearchScreen> {
  final _api  = TuneProxyService();
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Track> _results = [];
  bool _loading = false;

  @override void dispose() { _debounce?.cancel(); _ctrl.dispose(); super.dispose(); }

  void _search(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _loading = false; }); return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final r = await _api.search(q.trim());
        if (mounted) setState(() { _results = r; _loading = false; });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
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
        child: Column(children: [
          TextField(
            controller: _ctrl,
            onChanged: (v) { setState(() {}); _search(v); },
            style: const TextStyle(color: AppColors.foreground),
            decoration: InputDecoration(
              hintText: 'What do you want to listen to?',
              hintStyle: const TextStyle(color: AppColors.muted),
              prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 20),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                      onPressed: () { _ctrl.clear(); _search(''); setState(() {}); })
                  : null,
              filled: true, fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: hasQuery ? _results_() : _browse()),
        ]),
      ),
    );
  }

  Widget _browse() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Browse categories',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 14),
    Expanded(
      child: GridView.builder(
        itemCount: _browseChips.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 10,
          crossAxisSpacing: 10, childAspectRatio: 1.8),
        itemBuilder: (ctx, i) {
          final c = _browseChips[i];
          return GestureDetector(
            onTap: () { _ctrl.text = c[1] as String; _search(c[1] as String); setState(() {}); },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.cardGradients[c[2] as int].first,
              ),
              child: Text(c[0] as String,
                  style: const TextStyle(fontWeight: FontWeight.w800,
                      fontSize: 15, color: Colors.white)),
            ),
          );
        },
      ),
    ),
  ]);

  Widget _results_() {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));
    if (_results.isEmpty) return Center(child: Text(
        'No results for "${_ctrl.text}"',
        style: const TextStyle(color: AppColors.muted)));
    return ListView.builder(
      itemCount: _results.length + 1,
      itemBuilder: (ctx, i) {
        if (i == _results.length) return const SizedBox(height: 100);
        return TrackRow(track: _results[i], index: i,
            queue: _results, showIndex: true);
      },
    );
  }
}
