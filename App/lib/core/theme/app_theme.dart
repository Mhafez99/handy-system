import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system aligned with the shadcn/ui look used in the admin dashboard:
/// a warm neutral palette, hairline borders, soft rounded corners, muted
/// secondary text and flat (elevation-free) surfaces.
abstract final class AppTheme {
  // Shared radii (mirrors shadcn --radius scale).
  static const double radiusSm = 8;
  static const double radius = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  // ---- Light tokens ----
  static const Color _lBackground = Color(0xFFFAF8F4);
  static const Color _lForeground = Color(0xFF262119);
  static const Color _lCard = Color(0xFFFFFFFF);
  static const Color _lPrimary = Color(0xFF9E5A2B);
  static const Color _lPrimaryFg = Color(0xFFFAF8F4);
  static const Color _lSecondary = Color(0xFFEFE8DB);
  static const Color _lSecondaryFg = Color(0xFF5B4527);
  static const Color _lMuted = Color(0xFFF2ECE3);
  static const Color _lMutedFg = Color(0xFF877C6C);
  static const Color _lBorder = Color(0xFFE6DDCE);
  static const Color _lDestructive = Color(0xFFC23A28);
  static const Color _lSuccess = Color(0xFF2E9E6B);

  // ---- Dark tokens ----
  static const Color _dBackground = Color(0xFF201C17);
  static const Color _dForeground = Color(0xFFF4F1EB);
  static const Color _dCard = Color(0xFF29241E);
  static const Color _dPrimary = Color(0xFFD69456);
  static const Color _dPrimaryFg = Color(0xFF2A241B);
  static const Color _dSecondary = Color(0xFF362F27);
  static const Color _dSecondaryFg = Color(0xFFF4F1EB);
  static const Color _dMuted = Color(0xFF322C25);
  static const Color _dMutedFg = Color(0xFFB3A895);
  static const Color _dBorder = Color(0xFF3A342C);
  static const Color _dDestructive = Color(0xFFD0472F);
  static const Color _dSuccess = Color(0xFF35B074);

  static const Color primary = _lPrimary;
  static const Color success = _lSuccess;
  static const Color background = _lBackground;

  /// Success color that adapts to the current theme brightness.
  static Color successOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dSuccess : _lSuccess;

  static ColorScheme get _lightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: _lPrimary,
        onPrimary: _lPrimaryFg,
        primaryContainer: _lSecondary,
        onPrimaryContainer: _lSecondaryFg,
        secondary: _lPrimary,
        onSecondary: _lPrimaryFg,
        secondaryContainer: _lSecondary,
        onSecondaryContainer: _lSecondaryFg,
        tertiary: _lPrimary,
        onTertiary: _lPrimaryFg,
        error: _lDestructive,
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFBE3DF),
        onErrorContainer: Color(0xFF7A1B13),
        surface: _lCard,
        onSurface: _lForeground,
        surfaceContainerLowest: Color(0xFFFFFFFF),
        surfaceContainerLow: _lBackground,
        surfaceContainer: Color(0xFFF6F0E8),
        surfaceContainerHigh: _lMuted,
        surfaceContainerHighest: _lMuted,
        onSurfaceVariant: _lMutedFg,
        outline: Color(0xFFD3C7B5),
        outlineVariant: _lBorder,
        shadow: Color(0x1A4D3215),
        surfaceTint: _lPrimary,
        inverseSurface: _lForeground,
        onInverseSurface: _lBackground,
        inversePrimary: _dPrimary,
      );

  static ColorScheme get _darkScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: _dPrimary,
        onPrimary: _dPrimaryFg,
        primaryContainer: _dSecondary,
        onPrimaryContainer: _dSecondaryFg,
        secondary: _dPrimary,
        onSecondary: _dPrimaryFg,
        secondaryContainer: _dSecondary,
        onSecondaryContainer: _dSecondaryFg,
        tertiary: _dPrimary,
        onTertiary: _dPrimaryFg,
        error: _dDestructive,
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFF5B1B12),
        onErrorContainer: Color(0xFFFBE3DF),
        surface: _dCard,
        onSurface: _dForeground,
        surfaceContainerLowest: Color(0xFF1A1712),
        surfaceContainerLow: _dBackground,
        surfaceContainer: Color(0xFF2C271F),
        surfaceContainerHigh: _dMuted,
        surfaceContainerHighest: _dMuted,
        onSurfaceVariant: _dMutedFg,
        outline: Color(0xFF4A4238),
        outlineVariant: _dBorder,
        shadow: Color(0x66000000),
        surfaceTint: _dPrimary,
        inverseSurface: _dForeground,
        onInverseSurface: _dBackground,
        inversePrimary: _lPrimary,
      );

  static ThemeData get light => _build(_lightScheme, _lBackground);

  static ThemeData get dark => _build(_darkScheme, _dBackground);

  static ThemeData _build(ColorScheme cs, Color scaffold) {
    final base = ThemeData(useMaterial3: true, colorScheme: cs);
    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: cs.outlineVariant,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: cs.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: border(cs.outlineVariant),
        enabledBorder: border(cs.outlineVariant),
        focusedBorder: border(cs.primary, 1.6),
        errorBorder: border(cs.error),
        focusedErrorBorder: border(cs.error, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outlineVariant),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHighest,
        selectedColor: cs.primary,
        side: BorderSide.none,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSecondaryContainer,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: cs.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: cs.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? cs.primary : cs.onSurfaceVariant,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: cs.outlineVariant,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: cs.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
      ),
    );
  }
}
