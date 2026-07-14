import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/track_row.dart';

class LikedScreen extends StatelessWidget {
  const LikedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final liked = context.watch<LibraryProvider>().liked;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false, expandedHeight: 200,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4B0082), AppColors.background],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Liked Songs', style: TextStyle(color: Colors.white,
                        fontSize: 28, fontWeight: FontWeight.w900)),
                    Text('${liked.length} songs',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          if (liked.isEmpty)
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No liked songs yet.\nTap ♥ on any track!',
                  style: TextStyle(color: AppColors.muted, fontSize: 14)),
            ))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList.builder(
                itemCount: liked.length,
                itemBuilder: (ctx, i) => TrackRow(
                    track: liked[i], index: i,
                    queue: liked, showIndex: true),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
