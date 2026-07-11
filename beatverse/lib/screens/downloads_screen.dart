import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_record.dart';
import '../models/track.dart';
import '../providers/downloads_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

/// Ports src/pages/Downloads.tsx — plays back from the local file saved
/// by DownloadsProvider (see that file's doc comment re: audio source).
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadsState = context.watch<DownloadsProvider>();
    final downloads = downloadsState.downloads;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download_rounded, color: AppColors.primary, size: 26),
                const SizedBox(width: 8),
                const Text('Downloads',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.wifi_off, size: 14, color: AppColors.mutedForeground),
                const SizedBox(width: 6),
                Text(
                  'Available offline · ${downloads.length} songs · '
                  '${DownloadRecord.formatBytes(downloadsState.totalBytes)}',
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 12.5),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: !downloadsState.ready
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : downloads.isEmpty
                      ? _EmptyState()
                      : ListView.separated(
                          itemCount: downloads.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) => _DownloadTile(record: downloads[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_outlined, size: 48, color: AppColors.mutedForeground.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No downloads yet. Open the "⋮" menu on any track and tap Save offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadRecord record;
  const _DownloadTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: record.track.thumbnail,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(record.track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  '${record.track.artist} · ${DownloadRecord.formatBytes(record.size)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.play_arrow, color: AppColors.foreground),
            onPressed: () {
              final offlineTrack = Track(
                id: record.track.id,
                title: record.track.title,
                artist: record.track.artist,
                duration: record.track.duration,
                thumbnail: record.track.thumbnail,
                streamOverride: 'file://${record.filePath}',
              );
              context.read<PlayerProvider>().playTrack(offlineTrack);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.destructive),
            onPressed: () => context.read<DownloadsProvider>().removeDownload(record.id),
          ),
        ],
      ),
    );
  }
}
