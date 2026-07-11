import 'package:flutter/material.dart';
import '../models/track.dart';
import 'track_card.dart';

/// Ports the `Row` helper component from src/pages/Home.tsx — a titled
/// shelf of tracks. Rendered as a horizontally scrolling carousel here
/// (the standard native music-app pattern) instead of the original's
/// responsive wrapping grid, which was a web-breakpoint concern that
/// doesn't apply on a single phone-width screen.
class SectionRow extends StatelessWidget {
  final String title;
  final List<Track>? tracks;
  final bool loading;

  const SectionRow({
    super.key,
    required this.title,
    required this.tracks,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (!loading && (tracks == null || tracks!.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: loading ? 6 : tracks!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                if (loading) return const _SkeletonCard();
                return TrackCard(track: tracks![i], queue: tracks);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 10, width: 100, color: Colors.white10),
          const SizedBox(height: 6),
          Container(height: 10, width: 70, color: Colors.white10),
        ],
      ),
    );
  }
}
