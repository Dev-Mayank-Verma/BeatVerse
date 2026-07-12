import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/downloads_provider.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'screens/root_shell.dart';
import 'services/audio_handler.dart';
import 'services/user_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await AudioService.init(
    builder: () => BeatVerseAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.beatverse.app.audio',
      androidNotificationChannelName: 'BeatVerse',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
    ),
  );

  runApp(BeatVerseApp(audioHandler: audioHandler));
}

class BeatVerseApp extends StatelessWidget {
  final BeatVerseAudioHandler audioHandler;
  const BeatVerseApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..init()),
        ChangeNotifierProvider(create: (_) => PlayerProvider(audioHandler)),
        ChangeNotifierProvider(create: (_) => DownloadsProvider()..init()),
      ],
      child: MaterialApp(
        title: 'BeatVerse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const RootShell(),
      ),
    );
  }
}
