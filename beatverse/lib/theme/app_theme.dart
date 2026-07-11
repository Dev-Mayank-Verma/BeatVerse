import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BeatVerse dark theme — ported 1:1 from the original web app's HSL
/// design tokens (src/index.css) so the app keeps the same "deep black +
/// emerald" premium-streaming look. Values are kept as HSL (not hard-coded
/// hex) so they read the same as the CSS they were copied from.
class AppColors {
  static Color _hsl(double h, double s, double l) =>
      HSLColor.fromAHSL(1, h, s, l).toColor();

  static final background = _hsl(0, 0, 0.04);
  static final foreground = _hsl(0, 0, 0.98);
  static final card = _hsl(0, 0, 0.08);
  static final popover = _hsl(0, 0, 0.06);
  static final primary = _hsl(152, 0.76, 0.50);
  static final primaryGlow = _hsl(152, 0.90, 0.60);
  static final secondary = _hsl(0, 0, 0.12);
  static final muted = _hsl(0, 0, 0.14);
  static final mutedForeground = _hsl(0, 0, 0.64);
  static final accent = _hsl(280, 0.85, 0.65);
  static final destructive = _hsl(0, 0.84, 0.60);
  static final border = _hsl(0, 0, 0.16);
  static final surface1 = _hsl(0, 0, 0.06);
  static final surface2 = _hsl(0, 0, 0.10);
  static final surface3 = _hsl(0, 0, 0.14);

  /// The 6 "vibe" gradients used behind the Home screen shortcut chips
  /// (--gradient-vibe-1 .. 6 in the original CSS).
  static final vibeGradients = <List<Color>>[
    [_hsl(280, 0.85, 0.55), _hsl(320, 0.80, 0.55)], // purple -> pink
    [_hsl(20, 0.90, 0.55), _hsl(45, 0.95, 0.55)], // orange -> yellow
    [_hsl(200, 0.90, 0.50), _hsl(240, 0.80, 0.55)], // blue -> indigo
    [_hsl(152, 0.76, 0.45), _hsl(180, 0.80, 0.45)], // green -> teal
    [_hsl(340, 0.85, 0.55), _hsl(10, 0.85, 0.55)], // pink -> red-orange
    [_hsl(260, 0.70, 0.50), _hsl(300, 0.70, 0.50)], // purple -> magenta
  ];
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.foreground,
      displayColor: AppColors.foreground,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: AppColors.background,
        primary: AppColors.primary,
        onPrimary: AppColors.background,
        secondary: AppColors.accent,
        error: AppColors.destructive,
      ),
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: AppColors.foreground),
      splashFactory: NoSplash.splashFactory,
    );
  }
}
