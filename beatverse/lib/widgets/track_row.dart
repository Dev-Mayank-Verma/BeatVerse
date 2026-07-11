import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/downloads_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../screens/artist_screen.dart';
import '../theme/app_theme.dart';

/// Splits a combined artist credit like "Arijit Singh, Pritam" or
/// "BTS & Halsey" down to the first/primary name, for "go to artist".
String primaryArtist(String artist) {
  final match = RegExp(r'^[^,&x/]+', caseSensitive: false).firstMatch(artist.trim());
  return (match?.group(0) ?? artist).trim();
}

/// Ports src/components/music/TrackRow.tsx as a compact list row.
class TrackRow extends StatelessWidget {
  final Track track;
  final int? index;
  final List<Track>? queue;
  final bool showIndex;

  const TrackRow({
    super.key,
    required this.track,
    this.index,
    this.queue,
    this.showIndex = false,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final library = context.watch<LibraryProvider>();
    final active = player.current?.id == track.id;
    final liked = library.isLiked(track.id);

    void onPlay() {
      final p = context.read<PlayerProvider>();
      final l = context.read<LibraryProvider>();
      if (active) {
        p.togglePlay();
      } else {
        p.playTrack(track, queueList: queue);
        l.addRecent(track);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: active ? AppColors.secondary.withOpacity(0.4) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPlay,
            child: SizedBox(
              width: 40,
              height: 40,
              child: showIndex && !active
                  ? Center(
                      child: Text(
                        '${(index ?? 0) + 1}',
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: track.thumbnail,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Container(width: 40, height: 40, color: AppColors.muted),
                          ),
                          Container(color: Colors.black.withOpacity(0.35)),
                          Icon(
                            active && player.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onPlay,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.primary : AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Text(
            track.formattedDuration,
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 11.5),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: 19,
              color: liked ? AppColors.primary : AppColors.mutedForeground,
            ),
            onPressed: () => context.read<LibraryProvider>().toggleLike(track),
          ),
          _MoreMenu(track: track),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final Track track;
  const _MoreMenu({required this.track});

  void _addToPlaylist(BuildContext context) {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final playlists = context.read<LibraryProvider>().playlists;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add to playlist',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...playlists.map((p) => ListTile(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadsProvider>();
    final saved = downloads.isDownloaded(track.id);
    final progress = downloads.inProgress[track.id];

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 19, color: AppColors.mutedForeground),
      color: AppColors.card,
      onSelected: (value) {
        if (value == 'queue') {
          context.read<PlayerProvider>().addToQueue(track);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to queue')),
          );
        } else if (value == 'download') {
          if (saved || progress != null) return;
          context.read<DownloadsProvider>().downloadTrack(track).then((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved offline: ${track.title}')),
              );
            }
          }).catchError((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not save this track offline')),
              );
            }
          });
        } else if (value == 'artist') {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ArtistScreen(name: primaryArtist(track.artist)),
          ));
        } else if (value == 'playlist') {
          _addToPlaylist(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'queue', child: Text('Add to queue')),
        const PopupMenuItem(value: 'playlist', child: Text('Add to playlist')),
        const PopupMenuItem(value: 'artist', child: Text('Go to artist')),
        PopupMenuItem(
          value: 'download',
          child: Text(
            saved
                ? 'Saved offline ✓'
                : progress != null
                    ? 'Saving… $progress%'
                    : 'Save offline',
          ),
        ),
      ],
    );
  }
}
