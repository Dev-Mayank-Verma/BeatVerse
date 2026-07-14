import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../screens/youtube_player_screen.dart';
import '../theme/app_theme.dart';

class TrackCard extends StatelessWidget {
  final Track       track;
  final List<Track>? queue;
  final int          index;
  const TrackCard({super.key, required this.track, this.queue, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final q = queue ?? [track];
        final i = q.indexWhere((t) => t.id == track.id);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => YoutubePlayerScreen(
              track: track, queue: q, initialIndex: i < 0 ? 0 : i),
        ));
      },
      child: SizedBox(
        width: 148,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: track.thumbnail, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.card),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.card,
                    child: const Icon(Icons.music_note, color: AppColors.muted, size: 36)),
                ),
              ),
            ),
            Positioned(
              right: 6, bottom: 6,
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.black, size: 22),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ]),
      ),
    );
  }
}
