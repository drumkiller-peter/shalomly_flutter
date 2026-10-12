import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';

/// Builds Flutter's [ThemeData] from a church's Theme.
///
/// Every color comes from the church's [ChurchColors]; nothing here is fixed
/// to a hue. The colors also ride along as a theme extension, so a widget can
/// reach the ones Material has no slot for (`success`, `warning`, `info`,
/// `raised`, `textMuted`) through `context.churchColors`.
class AppTheme {
  static ThemeData light(ChurchTheme theme) => build(theme.light, Brightness.light);

  static ThemeData dark(ChurchTheme theme) => build(theme.dark, Brightness.dark);

  /// Returns the sanctuary editorial Serif text style for scripture, titles, and citations.
  static TextStyle serif({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Returns the sanctuary geometric Sans text style for body, captions, and badges.
  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Returns an uppercase category tracking badge style.
  static TextStyle trackingBadge({
    required Color color,
    double fontSize = 10.5,
    FontWeight fontWeight = FontWeight.w800,
    double letterSpacing = 1.0,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// The sanctuary card surface: the church's surface, a hairline border, and a soft lift.
  static BoxDecoration sanctuaryCard(ChurchColors colors, {double radius = 18}) {
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      boxShadow: [
        BoxShadow(
          color: colors.text.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// A filled hero gradient from the church's primary color. It deepens or lightens
  /// toward the side that keeps [ChurchColors.onPrimary] readable across the fill.
  static LinearGradient heroGradient(ChurchColors colors) {
    final hsl = HSLColor.fromColor(colors.primary);
    final onDark = colors.onPrimary.computeLuminance() > 0.5;
    final lightness = (hsl.lightness + (onDark ? -0.1 : 0.1)).clamp(0.0, 1.0);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors.primary, hsl.withLightness(lightness).toColor()],
    );
  }

  static ThemeData build(ChurchColors colors, Brightness brightness) {
    final tint = brightness == Brightness.light ? 0.15 : 0.25;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: Color.alphaBlend(colors.primary.withValues(alpha: tint), colors.surface),
      onPrimaryContainer: colors.text,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: Color.alphaBlend(colors.secondary.withValues(alpha: tint), colors.surface),
      onSecondaryContainer: colors.text,
      error: colors.error,
      onError: colors.onError,
      surface: colors.surface,
      onSurface: colors.text,
      onSurfaceVariant: colors.textMuted,
      // The strongest neutral the Theme has, for filled-but-quiet controls.
      surfaceContainerHighest: colors.border,
      outline: colors.border,
      outlineVariant: colors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.newsreader(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: colors.text,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.newsreader(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: colors.text,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.newsreader(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: colors.text,
          height: 1.35,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.text,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.textMuted,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: colors.text,
          height: 1.55,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: colors.text,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colors.textMuted,
          height: 1.45,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border.withValues(alpha: 0.6), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.newsreader(
          color: colors.text,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.raised,
        selectedColor: colors.primary.withValues(alpha: tint),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        height: 68,
        indicatorColor: colors.primary.withValues(alpha: tint),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.primary, size: 22);
          }
          return IconThemeData(color: colors.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textMuted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: tint),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        selectedIconTheme: IconThemeData(color: colors.primary),
        unselectedIconTheme: IconThemeData(color: colors.textMuted),
        selectedLabelTextStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colors.textMuted,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.raised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
