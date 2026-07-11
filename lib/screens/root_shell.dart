import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/player_provider.dart';
import '../services/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import 'downloads_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'podcasts_screen.dart';
import 'search_screen.dart';
import 'trending_screen.dart';

/// Ports the combination of AppLayout.tsx + MobileNav.tsx — bottom tab
/// navigation (Home / Search / Podcasts / Telegram / Trending / Saved)
/// with a persistent mini player docked above it.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
  }

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    PodcastsScreen(),
    TrendingScreen(),
    DownloadsScreen(),
  ];

  Future<void> _openTelegram() async {
    final uri = Uri.parse('https://telegram.me/scholarversepro_network');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasTrack = context.watch<PlayerProvider>().current != null;
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Text(
                    'BeatVerse',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.foreground,
                    ),
                  ),
                  if (user.ready) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: user.uid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Your ID copied — no login needed')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.displayId,
                          style: TextStyle(fontSize: 9.5, color: AppColors.mutedForeground),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
          Expanded(child: IndexedStack(index: _index, children: _screens)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasTrack)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: MiniPlayerBar(),
              ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  _navItem(Icons.home_rounded, 'Home', 0),
                  _navItem(Icons.search_rounded, 'Search', 1),
                  _navItem(Icons.library_music_rounded, 'Library', 2),
                  _navItem(Icons.mic_none_rounded, 'Podcasts', 3),
                  _navItem(Icons.local_fire_department_rounded, 'Hot', 4),
                  _navItem(Icons.download_rounded, 'Saved', 5),
                  _telegramItem(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _index == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 22, color: active ? AppColors.primary : AppColors.mutedForeground),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: active ? AppColors.primary : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telegramItem() {
    return Expanded(
      child: InkWell(
        onTap: _openTelegram,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, size: 14, color: Colors.black),
              ),
              const SizedBox(height: 3),
              Text(
                'TG',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
