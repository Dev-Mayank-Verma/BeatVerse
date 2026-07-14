import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/library_provider.dart';
import 'providers/downloads_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/user_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));
  await NotificationService.init();
  runApp(const BeatVerseApp());
}

class BeatVerseApp extends StatelessWidget {
  const BeatVerseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..init()),
        ChangeNotifierProvider(create: (_) => DownloadsProvider()..init()),
      ],
      child: MaterialApp(
        title: 'BeatVerse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const SplashScreen(),
      ),
    );
  }
}
