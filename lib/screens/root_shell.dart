import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/player_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import 'downloads_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'podcasts_screen.dart';
import 'search_screen.dart';
import 'trending_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    PodcastsScreen(),
    TrendingScreen(),
    DownloadsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermission(context);
    });
  }

  Future<void> _openTelegram() async {
    final uri = Uri.parse('https://telegram.me/scholarversepro_network');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasTrack = context.watch<PlayerProvider>().current != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top bar with BeatVerse logo
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border.withOpacity(0.4)),
                ),
              ),
              child: Row(
                children: [
                  // BeatVerse Logo
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: AppColors.vibeGradients[2],
                      ),
                    ),
                    child: const Icon(Icons.queue_music_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ).createShader(b),
                    child: const Text(
                      'BeatVerse',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.send_rounded,
                        color: AppColors.primary, size: 22),
                    onPressed: _openTelegram,
                    tooltip: 'Telegram',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(index: _index, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasTrack)
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 8, right: 8),
                child: MiniPlayerBar(),
              ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface1,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  _tab(Icons.home_rounded, 'Home', 0),
                  _tab(Icons.search_rounded, 'Search', 1),
                  _tab(Icons.library_music_rounded, 'Library', 2),
                  _tab(Icons.mic_none_rounded, 'Podcasts', 3),
                  _tab(Icons.local_fire_department_rounded, 'Hot', 4),
                  _tab(Icons.download_rounded, 'Saved', 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(IconData icon, String label, int i) {
    final active = _index == i;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22,
                  color: active
                      ? AppColors.primary
                      : AppColors.mutedForeground),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.normal,
                  color: active
                      ? AppColors.primary
                      : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
