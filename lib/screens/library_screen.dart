import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';
import 'liked_screen.dart';
import 'playlist_screen.dart';

/// Ports src/pages/Library.tsx.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _createPlaylist(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Playlist name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<LibraryProvider>().createPlaylist(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Your library'),
        actions: [
          TextButton.icon(
            onPressed: () => _createPlaylist(context),
            icon: Icon(Icons.add, size: 18, color: AppColors.primary),
            label: Text('New', style: TextStyle(color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: library.playlists.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, i) {
            if (i == 0) {
              return _Tile(
                title: 'Liked Songs',
                subtitle: '${library.liked.length} songs',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.vibeGradients[2]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 40),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LikedScreen()),
                ),
              );
            }
            final p = library.playlists[i - 1];
            final grad = AppColors.vibeGradients[(i - 1) % AppColors.vibeGradients.length];
            return _Tile(
              title: p.name,
              subtitle: '${p.tracks.length} songs',
              child: p.cover != null && p.cover!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(imageUrl: p.cover!, fit: BoxFit.cover),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: grad),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 40),
                    ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PlaylistScreen(playlistId: p.id)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onTap;

  const _Tile({required this.title, required this.subtitle, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: AspectRatio(aspectRatio: 1, child: child)),
            const SizedBox(height: 8),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(subtitle, style: TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
