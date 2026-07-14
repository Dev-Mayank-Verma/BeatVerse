import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../providers/library_provider.dart';
import '../screens/youtube_player_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/track_row.dart';

class PlaylistScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final Playlist? pl = library.playlists
        .cast<Playlist?>()
        .firstWhere((p) => p?.id == playlistId, orElse: () => null);

    if (pl == null) return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Playlist not found.',
          style: const TextStyle(color: AppColors.mutedForeground))),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true, expandedHeight: 220,
          backgroundColor: AppColors.background,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: AppColors.mutedForeground),
              onPressed: () => _rename(context, library, pl),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.mutedForeground),
              onPressed: () { library.deletePlaylist(pl.id); Navigator.pop(context); },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              pl.cover != null
                  ? CachedNetworkImage(imageUrl: pl.cover!, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(gradient: LinearGradient(
                            colors: AppColors.cardGradients[2]))))
                  : Container(decoration: BoxDecoration(gradient: LinearGradient(
                      colors: AppColors.cardGradients[2]))),
              Container(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.background]))),
              Positioned(left: 20, bottom: 16, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('PLAYLIST', style: TextStyle(color: Colors.white70,
                      fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  Text(pl.name, style: const TextStyle(color: Colors.white,
                      fontSize: 26, fontWeight: FontWeight.w900)),
                  Text('${pl.tracks.length} songs',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              )),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Container(
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  onPressed: pl.tracks.isEmpty ? null : () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => YoutubePlayerScreen(
                        track: pl.tracks.first,
                        queue: pl.tracks,
                        initialIndex: 0,
                      ),
                    ));
                  },
                ),
              ),
            ]),
          ),
        ),
        if (pl.tracks.isEmpty)
          const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No songs yet. Use ⋮ on any track to add.',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
          ))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList.builder(
              itemCount: pl.tracks.length,
              itemBuilder: (ctx, i) => TrackRow(
                track: pl.tracks[i], index: i,
                queue: pl.tracks, showIndex: true,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
    );
  }

  void _rename(BuildContext ctx, LibraryProvider lib, Playlist pl) {
    final ctrl = TextEditingController(text: pl.name);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Rename playlist'),
        content: TextField(controller: ctrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.foreground)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                lib.renamePlaylist(pl.id, ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
