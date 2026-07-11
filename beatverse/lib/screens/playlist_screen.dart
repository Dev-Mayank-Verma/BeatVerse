import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/track_row.dart';

/// Ports src/pages/Playlist.tsx. Uses proper Flutter dialogs in place of
/// the web version's browser prompt()/confirm().
class PlaylistScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistScreen({super.key, required this.playlistId});

  Future<void> _rename(BuildContext context, Playlist playlist) async {
    final controller = TextEditingController(text: playlist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Rename playlist'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<LibraryProvider>().renamePlaylist(playlist.id, name);
    }
  }

  Future<void> _delete(BuildContext context, Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete this playlist?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<LibraryProvider>().deletePlaylist(playlist.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final idx = library.playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: Center(
          child: Text('Playlist not found.', style: TextStyle(color: AppColors.mutedForeground)),
        ),
      );
    }
    final playlist = library.playlists[idx];
    final grad = AppColors.vibeGradients[idx % AppColors.vibeGradients.length];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: false,
            expandedHeight: 220,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (playlist.cover != null && playlist.cover!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: playlist.cover!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white, size: 40),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('PLAYLIST',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          Text(playlist.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                          Text('${playlist.tracks.length} songs',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: IconButton(
                      icon: Icon(Icons.play_arrow, color: AppColors.background),
                      onPressed: playlist.tracks.isEmpty
                          ? null
                          : () => context.read<PlayerProvider>().playTrack(
                                playlist.tracks.first,
                                queueList: playlist.tracks,
                              ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20, color: AppColors.mutedForeground),
                    onPressed: () => _rename(context, playlist),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: AppColors.mutedForeground),
                    onPressed: () => _delete(context, playlist),
                  ),
                ],
              ),
            ),
          ),
          if (playlist.tracks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No tracks yet. Add songs from Search or any track\'s ⋮ menu.',
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList.builder(
                itemCount: playlist.tracks.length,
                itemBuilder: (context, i) => TrackRow(
                  track: playlist.tracks[i],
                  index: i,
                  queue: playlist.tracks,
                  showIndex: true,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
