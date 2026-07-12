import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channel = AndroidNotificationChannel(
    'beatverse_music',
    'BeatVerse Music',
    description: 'New music and trending track updates',
    importance: Importance.defaultImportance,
    playSound: false,
  );

  static const _messages = [
    ('🔥 Trending Now', 'Check out today\'s hottest tracks on BeatVerse!'),
    ('🎵 New Drops', 'Fresh music just released — listen before everyone else!'),
    ('🌙 Evening Vibes', 'Perfect tracks for your evening — hand-picked for you!'),
    ('⚡ Energy Boost', 'High-energy tracks to power your afternoon!'),
    ('🎧 Discover', 'Hidden gems you haven\'t heard yet — explore now!'),
    ('✨ Chart Toppers', 'This week\'s most played tracks are waiting for you!'),
    ('🌅 Morning Beats', 'Start your day right with fresh new music!'),
    ('🎼 Chill Session', 'Lofi and ambient picks for your focus time!'),
  ];

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    _initialized = true;
  }

  static Future<void> requestPermission(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('notif_asked') ?? false;
    if (asked) return;
    await prefs.setBool('notif_asked', true);
    final status = await Permission.notification.request();
    if (status.isGranted) {
      await scheduleDaily();
    }
  }

  static Future<void> scheduleDaily() async {
    await _plugin.cancelAll();
    final rand = Random();
    // Send 3-4 notifications spread through the day
    final times = [9, 13, 17, 20];
    for (int i = 0; i < times.length; i++) {
      final msg = _messages[rand.nextInt(_messages.length)];
      await _plugin.periodicallyShowWithDuration(
        i,
        msg.$1,
        msg.$2,
        const Duration(hours: 6),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  static Future<void> showNow(String title, String body) async {
    await _plugin.show(
      99,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
