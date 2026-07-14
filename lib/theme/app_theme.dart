import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background    = Color(0xFF121212);
  static const surface       = Color(0xFF212121);
  static const card          = Color(0xFF282828);
  static const cardHover     = Color(0xFF333333);
  static const primary       = Color(0xFF1DB954);
  static const primaryGlow   = Color(0xFF1ed760);
  static const primaryDark   = Color(0xFF158a3e);
  static const foreground    = Color(0xFFFFFFFF);
  static const muted         = Color(0xFFB3B3B3);
  static const mutedForeground = Color(0xFFB3B3B3);
  static const border        = Color(0xFF333333);
  static const secondary     = Color(0xFF282828);
  static const accent        = Color(0xFF8D67AB);
  static const destructive   = Color(0xFFE91429);
  static const error         = Color(0xFFE91429);

  static final vibeGradients = <List<Color>>[
    [const Color(0xFF1DB954), const Color(0xFF191414)],
    [const Color(0xFF8D67AB), const Color(0xFF191414)],
    [const Color(0xFFE8115B), const Color(0xFF191414)],
    [const Color(0xFFEB1E32), const Color(0xFF191414)],
    [const Color(0xFF148A08), const Color(0xFF191414)],
    [const Color(0xFF0D73EC), const Color(0xFF191414)],
  ];

  static final cardGradients = <List<Color>>[
    [const Color(0xFF1DB954), const Color(0xFF158a3e)],
    [const Color(0xFF8D67AB), const Color(0xFF5b3d7a)],
    [const Color(0xFFE8115B), const Color(0xFF9b0b3d)],
    [const Color(0xFF0D73EC), const Color(0xFF0952a8)],
    [const Color(0xFFEB1E32), const Color(0xFF9b1422)],
    [const Color(0xFFFC3C44), const Color(0xFFb32030)],
  ];
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: AppColors.background,
        primary: AppColors.primary,
        onPrimary: Colors.black,
        secondary: AppColors.primary,
      ),
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.foreground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.foreground),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
