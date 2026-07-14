import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../screens/youtube_player_screen.dart';
import '../screens/artist_screen.dart';
import '../theme/app_theme.dart';

String primaryArtist(String a) =>
    RegExp(r'^[^,&x/]+', caseSensitive: false).firstMatch(a.trim())?.group(0)?.trim() ?? a;

class TrackRow extends StatelessWidget {
  final Track track;
  final int?  index;
  final List<Track>? queue;
  final bool showIndex;
  const TrackRow({super.key, required this.track, this.index,
      this.queue, this.showIndex = false});

  void _play(BuildContext ctx) {
    final q = queue ?? [track];
    final i = q.indexWhere((t) => t.id == track.id);
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => YoutubePlayerScreen(
          track: track, queue: q, initialIndex: i < 0 ? 0 : i),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final liked = context.watch<LibraryProvider>().isLiked(track.id);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _play(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [
          if (showIndex && index != null)
            SizedBox(
              width: 28,
              child: Text('${index! + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: track.thumbnail, width: 44, height: 44, fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(width: 44, height: 44, color: AppColors.card),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, children: [
              Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: liked ? AppColors.primary : AppColors.muted),
            onPressed: () => context.read<LibraryProvider>().toggleLike(track),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.muted),
            color: AppColors.card,
            onSelected: (v) {
              if (v == 'artist') Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ArtistScreen(name: primaryArtist(track.artist))));
              if (v == 'like') context.read<LibraryProvider>().toggleLike(track);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'like',
                  child: Text(liked ? 'Unlike' : 'Save to Liked')),
              const PopupMenuItem(value: 'artist', child: Text('Go to artist')),
            ],
          ),
        ]),
      ),
    );
  }
}
