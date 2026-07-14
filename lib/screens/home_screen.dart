import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../services/jamendo_service.dart';
import '../services/tuneproxy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _Shortcut {
  final String label; final String query; final int grad;
  const _Shortcut(this.label, this.query, this.grad);
}

final _year = DateTime.now().year;
final _shortcuts = [
  _Shortcut('Bollywood $_year', 'bollywood hits $_year', 0),
  _Shortcut('Arijit Singh',     'arijit singh',           1),
  _Shortcut('Punjabi',          'punjabi songs $_year',   2),
  _Shortcut('K-Pop',            'kpop hits',              3),
  _Shortcut('Lofi Chill',       'lofi chill hindi',       4),
  _Shortcut('English Pop',      'english pop hits',       5),
  _Shortcut('Romantic',         'romantic hindi songs',   0),
  _Shortcut('Workout',          'gym workout music',      1),
];

class _HomeScreenState extends State<HomeScreen> {
  final _yt     = TuneProxyService();
  final _jamendo= JamendoService();

  late Future<List<Track>> _trending;
  late Future<List<Track>> _newMusic;
  late Future<List<Track>> _lofi;
  late Future<List<Track>> _bollywood;
  late Future<List<Track>> _electronic;

  @override
  void initState() {
    super.initState();
    _trending  = _yt.trending();
    _bollywood = _yt.search('Bollywood hits $_year India');
    _newMusic  = _yt.search('new Hindi songs $_year');
    _lofi      = _jamendo.byTag('lofi');
    _electronic= _jamendo.byTag('electronic');
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_greeting,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Real YouTube music • Full CC audio',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _shortcuts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 10,
                  crossAxisSpacing: 10, childAspectRatio: 2.6,
                ),
                itemBuilder: (context, i) {
                  final s = _shortcuts[i];
                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: AppColors.vibeGradients[s.grad],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        child: Text(s.label,
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
          SliverToBoxAdapter(child: _row('🔥 Trending in India', _trending)),
          SliverToBoxAdapter(child: _row('🎵 New Bollywood', _bollywood)),
          SliverToBoxAdapter(child: _row('✨ New Hindi Songs', _newMusic)),
          SliverToBoxAdapter(child: _row('🌙 Lofi / Chill', _lofi)),
          SliverToBoxAdapter(child: _row('⚡ Electronic', _electronic)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _row(String title, Future<List<Track>> f) =>
      FutureBuilder<List<Track>>(
        future: f,
        builder: (ctx, snap) => SectionRow(
          title: title,
          tracks: snap.data,
          loading: snap.connectionState == ConnectionState.waiting,
        ),
      );
}
