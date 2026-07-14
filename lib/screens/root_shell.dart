import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    HomeScreen(), SearchScreen(), LibraryScreen(),
    PodcastsScreen(), TrendingScreen(), DownloadsScreen(),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.search_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
            label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.library_music_rounded, color: AppColors.primary),
            label: 'Library'),
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded, color: AppColors.muted),
            selectedIcon: Icon(Icons.mic_rounded, color: AppColors.primary),
            label: 'Podcasts'),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.local_fire_department, color: AppColors.primary),
            label: 'Hot'),
          NavigationDestination(
            icon: Icon(Icons.download_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.download_rounded, color: AppColors.primary),
            label: 'Saved'),
        ],
      ),
    );
  }
}
