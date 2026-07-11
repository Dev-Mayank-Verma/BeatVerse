import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../services/jamendo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _Genre { final String label; final String tag; final int grad;
  const _Genre(this.label, this.tag, this.grad); }

final _genres = [
  const _Genre('Pop',        'pop',        0),
  const _Genre('Electronic', 'electronic', 1),
  const _Genre('Lofi Chill', 'lofi',       2),
  const _Genre('Hip-Hop',    'hiphop',     3),
  const _Genre('Rock',       'rock',       4),
  const _Genre('Ambient',    'ambient',    5),
  const _Genre('Acoustic',   'acoustic',   0),
  const _Genre('R & B',      'rnb',        1),
  const _Genre('Jazz',       'jazz',       2),
  const _Genre('Dance',      'dance',      3),
];

class _HomeScreenState extends State<HomeScreen> {
  final _api = JamendoService();

  late Future<List<Track>> _trending;
  late Future<List<Track>> _newReleases;
  late Future<List<Track>> _popTop;
  late Future<List<Track>> _lofi;
  late Future<List<Track>> _electronic;

  @override
  void initState() {
    super.initState();
    _trending    = _api.trending();
    _newReleases = _api.newReleases();
    _popTop      = _api.byTag('pop');
    _lofi        = _api.byTag('lofi');
    _electronic  = _api.byTag('electronic');
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final recent = context.watch<LibraryProvider>().recent;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_greeting, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('600 000+ Creative Commons tracks — stream freely.',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 12.5)),
              ]),
            ),
          ),
          // Genre shortcut grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _genres.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                itemBuilder: (context, i) {
                  final g = _genres[i];
                  final grad = AppColors.vibeGradients[g.grad];
                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // SearchScreen can be pre-filled; for now we lazy-load
                        // a new genre row inline (Search tab covers the search case).
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: grad,
                              begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        child: Text(g.label,
                            style: const TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 13, color: Colors.white)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (recent.isNotEmpty)
            SliverToBoxAdapter(
              child: SectionRow(
                  title: 'Recently played',
                  tracks: recent.take(12).toList(),
                  loading: false),
            ),
          SliverToBoxAdapter(child: _row('🔥 Trending now',    _trending)),
          SliverToBoxAdapter(child: _row('✨ New releases',    _newReleases)),
          SliverToBoxAdapter(child: _row('🎵 Pop hits',        _popTop)),
          SliverToBoxAdapter(child: _row('🌙 Lofi / Chill',   _lofi)),
          SliverToBoxAdapter(child: _row('⚡ Electronic',      _electronic)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _row(String title, Future<List<Track>> future) =>
      FutureBuilder<List<Track>>(
        future: future,
        builder: (context, snap) => SectionRow(
          title: title,
          tracks: snap.data,
          loading: snap.connectionState == ConnectionState.waiting,
        ),
      );
}
