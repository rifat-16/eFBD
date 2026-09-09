import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive_helper.dart';

class AppTheme {
  static const Color primaryGold = Color(0xFFFACC15);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color cardBackground = Color(0xFF1E293B);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF94A3B8);

  static double responsiveFontSize(BuildContext context, double baseSize) {
    if (ResponsiveHelper.isMobile(context)) {
      return baseSize * 0.9;
    } else if (ResponsiveHelper.isTablet(context)) {
      return baseSize * 0.95;
    }
    return baseSize;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: accentBlue,
        surface: cardBackground,
        onSurface: textWhite,
        onSurfaceVariant: textGrey,
        primaryContainer: Color(0xFF453D1F),
        onPrimaryContainer: primaryGold,
        secondaryContainer: Color(0xFF1E293B),
        onSecondaryContainer: accentBlue,
        tertiary: accentGreen,
        onTertiary: Colors.black,
        surfaceContainer: cardBackground,
        surfaceContainerLow: darkBackground,
        surfaceContainerHigh: Color(0xFF262F41),
        surfaceContainerHighest: Color(0xFF334155),
        onPrimary: Colors.black,
        onSecondary: textWhite,
        error: Colors.redAccent,
        onError: textWhite,
        outline: textGrey,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBackground,
        contentTextStyle: GoogleFonts.poppins(color: textWhite),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGold,
        circularTrackColor: Color(0xFF1E293B),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: textWhite, fontSize: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.rajdhani(
          color: primaryGold,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1,
        ),
        dataTextStyle: GoogleFonts.poppins(color: textWhite, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.rajdhani(
          color: primaryGold,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.rajdhani(
          color: primaryGold,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.rajdhani(
          color: primaryGold,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        bodyLarge: GoogleFonts.poppins(color: textWhite),
        bodyMedium: GoogleFonts.poppins(color: textWhite),
        bodySmall: GoogleFonts.poppins(color: textGrey),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGold),
        ),
        hintStyle: GoogleFonts.poppins(color: textGrey),
        labelStyle: GoogleFonts.poppins(color: primaryGold),
        prefixIconColor: primaryGold,
        suffixIconColor: primaryGold,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.poppins(color: textWhite),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(cardBackground),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGold,
          textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primaryGold,
        textColor: textWhite,
        titleTextStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
        subtitleTextStyle: GoogleFonts.poppins(color: textGrey, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryGold,
        unselectedLabelColor: textGrey,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
        unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 16, letterSpacing: 1),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryGold, width: 2),
        ),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(primaryGold.withValues(alpha: 0.1)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryGold,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBackground,
        indicatorColor: primaryGold.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rajdhani(color: primaryGold, fontSize: 13, fontWeight: FontWeight.bold);
          }
          return GoogleFonts.rajdhani(color: textGrey, fontSize: 13);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGold);
          }
          return const IconThemeData(color: textGrey);
        }),
      ),
    );
  }
}
