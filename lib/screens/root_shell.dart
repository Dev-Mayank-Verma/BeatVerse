import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/player_provider_stub.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'downloads_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'podcasts_screen.dart';
import 'search_screen.dart';
import 'trending_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _idx = 0;

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    PodcastsScreen(),
    TrendingScreen(),
    DownloadsScreen(),
  ];

  static const _navItems = [
    [Icons.home_rounded,            Icons.home_outlined,           'Home'],
    [Icons.search_rounded,          Icons.search_outlined,         'Search'],
    [Icons.library_music_rounded,   Icons.library_music_outlined,  'Library'],
    [Icons.mic_rounded,             Icons.mic_none_rounded,        'Podcasts'],
    [Icons.local_fire_department,   Icons.local_fire_department_outlined, 'Hot'],
    [Icons.download_rounded,        Icons.download_outlined,       'Downloads'],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermission(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        backgroundColor: const Color(0xFF0A0A0A),
        indicatorColor: AppColors.primary.withOpacity(0.15),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _navItems.map((item) => NavigationDestination(
          icon: Icon(item[1] as IconData, color: AppColors.muted),
          selectedIcon: Icon(item[0] as IconData, color: AppColors.primary),
          label: item[2] as String,
        )).toList(),
      ),
    );
  }
}
