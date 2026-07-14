import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/tuneproxy_service.dart';
import '../theme/app_theme.dart';
import '../widgets/track_row.dart';

class ArtistScreen extends StatefulWidget {
  final String name;
  const ArtistScreen({super.key, required this.name});
  @override State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  final _api = TuneProxyService();
  late Future<List<Track>> _tracks;

  @override
  void initState() {
    super.initState();
    _tracks = _api.search(widget.name, limit: 30);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: FutureBuilder<List<Track>>(
      future: _tracks,
      builder: (ctx, snap) {
        final tracks  = snap.data ?? [];
        final loading = snap.connectionState == ConnectionState.waiting;
        return CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true, expandedHeight: 220,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                tracks.isNotEmpty
                    ? CachedNetworkImage(imageUrl: tracks.first.thumbnail,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          decoration: BoxDecoration(gradient: LinearGradient(
                              colors: AppColors.vibeGradients[0]))))
                    : Container(decoration: BoxDecoration(gradient: LinearGradient(
                        colors: AppColors.vibeGradients[0]))),
                Container(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.background]))),
                Positioned(left: 20, bottom: 16, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ARTIST', style: TextStyle(color: Colors.white70,
                        fontSize: 11, letterSpacing: 1.5,
                        fontWeight: FontWeight.bold)),
                    Text(widget.name, style: const TextStyle(color: Colors.white,
                        fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                )),
              ]),
            ),
          ),
          if (loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(
                    color: AppColors.primary))))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList.builder(
                itemCount: tracks.length,
                itemBuilder: (ctx, i) => TrackRow(
                    track: tracks[i], index: i,
                    queue: tracks, showIndex: true),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]);
      },
    ),
  );
}
