import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

/// Ports the queue Sheet from src/components/player/PlayerBar.tsx.
void showQueueSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _QueueSheet(),
  );
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const Spacer(),
                TextButton(
                  onPressed: player.queue.length <= 1
                      ? null
                      : () => context.read<PlayerProvider>().clearQueue(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: player.queue.length,
                itemBuilder: (context, i) {
                  final t = player.queue[i];
                  final active = t.id == player.current?.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    tileColor: active ? AppColors.secondary.withOpacity(0.5) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: t.thumbnail,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(width: 40, height: 40, color: AppColors.muted),
                      ),
                    ),
                    title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                    trailing: IconButton(
                      icon: Icon(Icons.close, size: 16, color: AppColors.mutedForeground),
                      onPressed: () => context.read<PlayerProvider>().removeFromQueue(i),
                    ),
                    onTap: () => context.read<PlayerProvider>().playTrack(t, queueList: player.queue),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
