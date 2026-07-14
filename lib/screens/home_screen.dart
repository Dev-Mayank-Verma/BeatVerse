import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../screens/youtube_player_screen.dart';
import '../services/tuneproxy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = TuneProxyService();
  final int _year = DateTime.now().year;

  late Future<List<Track>> _trending;
  late Future<List<Track>> _bollywood;
  late Future<List<Track>> _arijit;
  late Future<List<Track>> _punjabi;
  late Future<List<Track>> _english;

  final _categories = [
    ['Bollywood Hits', 'bollywood hits', 0],
    ['Punjabi Pop', 'punjabi songs', 1],
    ['English Charts', 'english pop hits', 2],
    ['K-Pop', 'kpop bts blackpink', 3],
    ['Romantic', 'romantic hindi songs', 4],
    ['Lofi Hip-Hop', 'lofi hip hop', 5],
  ];

  @override
  void initState() {
    super.initState();
    _trending  = _api.trending();
    _bollywood = _api.search('bollywood top songs $_year');
    _arijit    = _api.search('arijit singh $_year');
    _punjabi   = _api.search('punjabi top songs $_year');
    _english   = _api.search('english top songs $_year');
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final recent = context.watch<LibraryProvider>().recent;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // ── Greeting ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(_greeting,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800)),
            ),
          ),

          // ── Recently played — Spotify style 2x3 grid ─────────────
          if (recent.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.take(6).length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 3.6,
                    mainAxisSpacing: 8, crossAxisSpacing: 8,
                  ),
                  itemBuilder: (ctx, i) {
                    final t = recent[i];
                    return GestureDetector(
                      onTap: () => Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => YoutubePlayerScreen(
                            track: t, queue: recent, initialIndex: i),
                      )),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                bottomLeft: Radius.circular(6)),
                            child: CachedNetworkImage(
                              imageUrl: t.thumbnail,
                              width: 48, height: 48, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(width: 48, height: 48,
                                      color: AppColors.cardHover),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(t.title, maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 4),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Category chips ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final c = _categories[i];
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: AppColors.cardGradients[c[2] as int],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(c[0] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14, color: Colors.white)),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Trending ───────────────────────────────────────────────
          SliverToBoxAdapter(child: _row('🔥 Trending in India', _trending)),
          SliverToBoxAdapter(child: _row('🎬 Bollywood $_year', _bollywood)),
          SliverToBoxAdapter(child: _row('🎤 Arijit Singh', _arijit)),
          SliverToBoxAdapter(child: _row('🎵 Punjabi Vibes', _punjabi)),
          SliverToBoxAdapter(child: _row('🌍 English Charts', _english)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _row(String title, Future<List<Track>> f) =>
      FutureBuilder<List<Track>>(
        future: f,
        builder: (ctx, s) => SectionRow(
          title: title, tracks: s.data,
          loading: s.connectionState == ConnectionState.waiting),
      );
}
