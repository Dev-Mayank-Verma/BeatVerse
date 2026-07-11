import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/artist_result.dart';
import '../providers/player_provider.dart';
import '../services/jamendo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/track_row.dart';

class ArtistScreen extends StatefulWidget {
  final String name;
  const ArtistScreen({super.key, required this.name});
  @override State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  final _api = JamendoService();
  late Future<ArtistResult> _future;

  @override
  void initState() { super.initState(); _future = _api.getArtist(widget.name); }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<ArtistResult>(
        future: _future,
        builder: (context, snap) {
          final loading = snap.connectionState == ConnectionState.waiting;
          final artist  = snap.data;
          final tracks  = artist?.topTracks ?? [];
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background,
                expandedHeight: 240,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      artist?.thumbnail != null && artist!.thumbnail!.isNotEmpty
                          ? CachedNetworkImage(imageUrl: artist.thumbnail!, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                decoration: BoxDecoration(gradient: LinearGradient(colors: AppColors.vibeGradients[0]))))
                          : Container(decoration: BoxDecoration(
                              gradient: LinearGradient(colors: AppColors.vibeGradients[0]))),
                      Container(decoration: BoxDecoration(gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.background]))),
                      Positioned(left: 20, right: 20, bottom: 16,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('ARTIST', style: TextStyle(color: Colors.white70, fontSize: 11,
                              fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          Text(widget.name, style: const TextStyle(color: Colors.white,
                              fontSize: 30, fontWeight: FontWeight.w800),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(children: [
                    Container(
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(Icons.play_arrow, color: AppColors.background),
                        onPressed: tracks.isEmpty ? null
                            : () => context.read<PlayerProvider>().playTrack(tracks.first, queueList: tracks),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.shuffle,
                          color: player.shuffle ? AppColors.primary : AppColors.mutedForeground),
                      onPressed: () => context.read<PlayerProvider>().toggleShuffle(),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text('Popular', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (loading)
                const SliverToBoxAdapter(child: Padding(
                  padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())))
              else if (tracks.isEmpty)
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No Jamendo tracks found for "${widget.name}".',
                      style: TextStyle(color: AppColors.mutedForeground))))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, i) =>
                        TrackRow(track: tracks[i], index: i, queue: tracks, showIndex: true),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}
