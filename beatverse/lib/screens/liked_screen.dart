import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/track_row.dart';

/// Ports src/pages/Liked.tsx. Pushed as a full-screen route (the original
/// web app doesn't put Liked in the bottom nav either — it's reached via
/// the sidebar/top bar, mirrored here with a heart icon in RootShell).
class LikedScreen extends StatelessWidget {
  const LikedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final liked = context.watch<LibraryProvider>().liked;
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: false,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.vibeGradients[2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 44),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'PLAYLIST',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Liked Songs',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${liked.length} songs',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
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
                      onPressed: liked.isEmpty
                          ? null
                          : () => context
                              .read<PlayerProvider>()
                              .playTrack(liked.first, queueList: liked),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: player.shuffle ? AppColors.primary : AppColors.mutedForeground,
                    ),
                    onPressed: () => context.read<PlayerProvider>().toggleShuffle(),
                  ),
                ],
              ),
            ),
          ),
          if (liked.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No liked songs yet. Tap the heart on any track.',
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList.builder(
                itemCount: liked.length,
                itemBuilder: (context, i) => TrackRow(
                  track: liked[i],
                  index: i,
                  queue: liked,
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
