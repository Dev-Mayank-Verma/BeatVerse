import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../screens/now_playing_screen.dart';
import '../theme/app_theme.dart';

/// Ports src/components/player/PlayerBar.tsx (compact form) — a
/// persistent mini player pinned above the bottom nav while a track is
/// loaded. Tapping it opens the full NowPlayingScreen.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.current;
    if (track == null) return const SizedBox.shrink();

    final progress = player.total.inMilliseconds == 0
        ? 0.0
        : player.position.inMilliseconds / player.total.inMilliseconds;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
      ),
      child: Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: track.thumbnail,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(width: 44, height: 44, color: AppColors.muted),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.skip_previous, color: AppColors.foreground, size: 20),
                  onPressed: () => context.read<PlayerProvider>().previous(),
                ),
                IconButton(
                  icon: Icon(
                    player.isBuffering
                        ? Icons.hourglass_empty
                        : (player.isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                  color: AppColors.foreground,
                  onPressed: player.isBuffering
                      ? null
                      : () => context.read<PlayerProvider>().togglePlay(),
                ),
                IconButton(
                  icon: Icon(Icons.skip_next, color: AppColors.foreground, size: 20),
                  onPressed: () => context.read<PlayerProvider>().next(),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 2,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ],
      ),
      ),
    );
  }
}
