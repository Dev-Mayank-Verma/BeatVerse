import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

/// Ports src/components/music/TrackCard.tsx.
class TrackCard extends StatelessWidget {
  final Track track;
  final List<Track>? queue;
  const TrackCard({super.key, required this.track, this.queue});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final active = player.current?.id == track.id;
    final playingThis = active && player.isPlaying;

    return GestureDetector(
      onTap: () =>
          context.read<PlayerProvider>().playTrack(track, queueList: queue),
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: track.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.muted),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.muted,
                        child: const Icon(Icons.music_note, color: Colors.white38),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Icon(
                      playingThis ? Icons.pause : Icons.play_arrow,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
