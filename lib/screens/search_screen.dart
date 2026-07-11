import 'dart:async';
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/jamendo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/track_row.dart';

/// Ports src/pages/Search.tsx.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _Suggestion {
  final String label;
  final String query;
  final int grad;
  const _Suggestion(this.label, this.query, this.grad);
}

const _suggestions = [
  _Suggestion('Hindi', 'Top Hindi songs', 0),
  _Suggestion('Punjabi', 'Punjabi top hits', 1),
  _Suggestion('English', 'English top charts', 2),
  _Suggestion('K-Pop', 'BTS Blackpink', 3),
  _Suggestion('Lofi', 'Lofi chill', 4),
  _Suggestion('Arijit', 'Arijit Singh', 5),
  _Suggestion('Workout', 'Workout gym hits', 0),
  _Suggestion('Romance', 'Romantic Hindi', 1),
];

class _SearchScreenState extends State<SearchScreen> {
  final _api = JamendoService();
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Track> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final r = await _api.search(q);
        if (!mounted) return;
        setState(() {
          _results = r;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _error = 'Search service unavailable. Try again.';
          _loading = false;
        });
      }
    });
  }

  void _setQuery(String q) {
    _controller.text = q;
    _onChanged(q);
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.trim().isNotEmpty;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              onChanged: _onChanged,
              autofocus: false,
              style: TextStyle(color: AppColors.foreground),
              decoration: InputDecoration(
                hintText: 'Songs, artists, albums…',
                hintStyle: TextStyle(color: AppColors.mutedForeground),
                prefixIcon: Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: !hasQuery ? _buildBrowseAll() : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseAll() {
    return ListView(
      children: [
        const Text('Browse all', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, i) {
            final s = _suggestions[i];
            final grad = AppColors.vibeGradients[s.grad];
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _setQuery(s.query),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  alignment: Alignment.topLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: grad,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    s.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return ListView.separated(
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 52,
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    if (_error != null) {
      return Text(_error!, style: TextStyle(color: AppColors.destructive, fontSize: 13));
    }
    if (_results.isEmpty) {
      return Text(
        'No results for "${_controller.text.trim()}".',
        style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
      );
    }
    return ListView.builder(
      itemCount: _results.length + 1,
      itemBuilder: (context, i) {
        if (i == _results.length) return const SizedBox(height: 100);
        return TrackRow(track: _results[i], index: i, queue: _results, showIndex: true);
      },
    );
  }
}
