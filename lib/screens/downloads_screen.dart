import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_record.dart';
import '../providers/downloads_provider.dart';
import '../theme/app_theme.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dl = context.watch<DownloadsProvider>();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.download_rounded, color: AppColors.primary, size: 26),
            const SizedBox(width: 8),
            const Text('Downloads', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          Text('${dl.downloads.length} saved · ${DownloadRecord.formatBytes(dl.totalBytes)}',
              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12.5)),
          const SizedBox(height: 20),
          Expanded(
            child: !dl.ready
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : dl.downloads.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No downloads yet.\nUse ⋮ on any track to save offline.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.mutedForeground, fontSize: 13))))
                    : ListView.separated(
                        itemCount: dl.downloads.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _tile(context, dl.downloads[i], dl),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _tile(BuildContext ctx, DownloadRecord r, DownloadsProvider dl) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(imageUrl: r.track.thumbnail,
                width: 48, height: 48, fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(width: 48, height: 48, color: AppColors.cardHover)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${r.track.artist} · ${DownloadRecord.formatBytes(r.size)}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
          ])),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.destructive),
            onPressed: () => dl.removeDownload(r.id),
          ),
        ]),
      );
}
