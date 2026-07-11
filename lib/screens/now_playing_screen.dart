import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/downloads_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/equalizer_button.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/sleep_timer_button.dart';
import '../widgets/track_row.dart' show primaryArtist;
import 'artist_screen.dart';

/// Ports src/components/player/NowPlaying.tsx — the full-screen expanded
/// player, opened from MiniPlayerBar.
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  int _tab = 0; // 0 = cover, 1 = lyrics

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.current;
    if (track == null) {
      // Track ended/cleared while this screen was open.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final library = context.watch<LibraryProvider>();
    final downloads = context.watch<DownloadsProvider>();
    final liked = library.isLiked(track.id);
    final saved = downloads.isDownloaded(track.id);
    final saving = downloads.inProgress[track.id];
    final progress = player.total.inMilliseconds == 0
        ? 0.0
        : player.position.inMilliseconds / player.total.inMilliseconds;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down, size: 30, color: AppColors.foreground),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('PLAYING FROM BEATVERSE',
                            style: TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.mutedForeground)),
                        Text(track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: saved
                        ? Icon(Icons.check, color: AppColors.primary)
                        : saving != null
                            ? Text('$saving%', style: TextStyle(fontSize: 10, color: AppColors.primary))
                            : Icon(Icons.download_outlined, color: AppColors.foreground),
                    onPressed: (saved || saving != null)
                        ? null
                        : () => context.read<DownloadsProvider>().downloadTrack(track),
                  ),
                ],
              ),
            ),

            // Cover / Lyrics tab switcher
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tabChip('Cover', Icons.album, 0),
                    _tabChip('Lyrics', Icons.mic_external_on, 1),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _tab == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: CachedNetworkImage(
                                  imageUrl: track.thumbnail,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(color: AppColors.muted),
                                ),
                              ),
                              if (player.isBuffering)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const LyricsView(),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                            Text(track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                            color: liked ? AppColors.primary : AppColors.foreground),
                        onPressed: () => context.read<LibraryProvider>().toggleLike(track),
                      ),
                    ],
                  ),
                  Slider(
                    value: progress.clamp(0, 1),
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.secondary,
                    onChanged: (v) {
                      final target = Duration(
                          milliseconds: (v * player.total.inMilliseconds).round());
                      context.read<PlayerProvider>().seek(target);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(player.position),
                            style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                        Text(_fmt(player.total),
                            style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.shuffle,
                            color: player.shuffle ? AppColors.primary : AppColors.mutedForeground),
                        onPressed: () => context.read<PlayerProvider>().toggleShuffle(),
                      ),
                      IconButton(
                        iconSize: 30,
                        icon: Icon(Icons.skip_previous, color: AppColors.foreground),
                        onPressed: () => context.read<PlayerProvider>().previous(),
                      ),
                      Container(
                        decoration: BoxDecoration(color: AppColors.foreground, shape: BoxShape.circle),
                        child: IconButton(
                          iconSize: 34,
                          icon: Icon(
                            player.isBuffering
                                ? Icons.hourglass_empty
                                : (player.isPlaying ? Icons.pause : Icons.play_arrow),
                            color: AppColors.background,
                          ),
                          onPressed: () => context.read<PlayerProvider>().togglePlay(),
                        ),
                      ),
                      IconButton(
                        iconSize: 30,
                        icon: Icon(Icons.skip_next, color: AppColors.foreground),
                        onPressed: () => context.read<PlayerProvider>().next(),
                      ),
                      IconButton(
                        icon: Icon(
                          player.repeat == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                          color: player.repeat != RepeatMode.off
                              ? AppColors.primary
                              : AppColors.mutedForeground,
                        ),
                        onPressed: () => context.read<PlayerProvider>().cycleRepeat(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const SleepTimerButton(),
                      const EqualizerButton(),
                      TextButton.icon(
                        onPressed: () => showQueueSheet(context),
                        icon: Icon(Icons.queue_music, size: 18, color: AppColors.mutedForeground),
                        label: Text('Queue', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: () => context.read<PlayerProvider>().setPlaybackRate(
                              player.playbackRate >= 1.25 ? 1.0 : player.playbackRate + 0.25,
                            ),
                        icon: Icon(Icons.speed, size: 18, color: AppColors.mutedForeground),
                        label: Text('${player.playbackRate.toStringAsFixed(2)}x',
                            style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ArtistScreen(name: primaryArtist(track.artist)),
                        )),
                        icon: Icon(Icons.person_outline, size: 18, color: AppColors.mutedForeground),
                        label: Text('Artist', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final library = context.read<LibraryProvider>();
                          if (library.playlists.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Create a playlist first in Your Library')),
                            );
                            return;
                          }
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: AppColors.card,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (ctx) => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Add to playlist',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 12),
                                  ...library.playlists.map((p) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(p.name, style: const TextStyle(fontSize: 14)),
                                        subtitle: Text('${p.tracks.length} songs',
                                            style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                        onTap: () {
                                          context.read<LibraryProvider>().addToPlaylist(p.id, track);
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Added to ${p.name}')),
                                          );
                                        },
                                      )),
                                ],
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.playlist_add, size: 18, color: AppColors.mutedForeground),
                        label: Text('+ Playlist', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, IconData icon, int index) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? AppColors.background : AppColors.mutedForeground),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.background : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
