// VidKeep App Theme - Retro Terminal Style
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  /// Get the dark theme with retro terminal styling
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.terminalBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.neonGreen,
      secondary: AppColors.neonGreen,
      surface: AppColors.cardBg,
    ),
    // Share Tech Mono font for terminal aesthetic
    textTheme: _buildTextTheme(),
    appBarTheme: _buildAppBarTheme(),
    cardTheme: _buildCardTheme(),
    elevatedButtonTheme: _buildElevatedButtonTheme(),
    outlinedButtonTheme: _buildOutlinedButtonTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(),
    bottomNavigationBarTheme: _buildBottomNavTheme(),
    floatingActionButtonTheme: _buildFabTheme(),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.neonGreen,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkGreen,
      thickness: 1,
    ),
  );

  static TextTheme _buildTextTheme() {
    return GoogleFonts.shareTechMonoTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      headlineLarge: GoogleFonts.shareTechMono(
        color: AppColors.neonGreen,
        fontSize: 28,
        letterSpacing: 0.5,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.shareTechMono(
        color: AppColors.neonGreen,
        fontSize: 24,
        letterSpacing: 0.5,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.shareTechMono(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.shareTechMono(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: GoogleFonts.shareTechMono(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.shareTechMono(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: GoogleFonts.shareTechMono(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: GoogleFonts.shareTechMono(
        color: AppColors.neonGreen,
        fontSize: 14,
        letterSpacing: 0.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: AppColors.terminalBg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.shareTechMono(
        color: AppColors.neonGreen,
        fontSize: 20,
        letterSpacing: 1.0,
      ),
      iconTheme: const IconThemeData(color: AppColors.neonGreen),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Sharp corners for terminal look
        side: const BorderSide(color: AppColors.borderColor, width: 1),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.neonGreen,
        side: const BorderSide(color: AppColors.neonGreen, width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Sharp corners
        ),
        textStyle: GoogleFonts.shareTechMono(
          fontSize: 14,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neonGreen,
        side: const BorderSide(color: AppColors.neonGreen, width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        textStyle: GoogleFonts.shareTechMono(
          fontSize: 14,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBg,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.darkGreen),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.darkGreen),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.neonGreen, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.statusFailed),
      ),
      labelStyle: GoogleFonts.shareTechMono(color: AppColors.textSecondary),
      hintStyle: GoogleFonts.shareTechMono(color: AppColors.textSecondary),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme() {
    return BottomNavigationBarThemeData(
      backgroundColor: AppColors.terminalBg,
      selectedItemColor: AppColors.neonGreen,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: GoogleFonts.shareTechMono(fontSize: 10),
      unselectedLabelStyle: GoogleFonts.shareTechMono(fontSize: 10),
      type: BottomNavigationBarType.fixed,
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme() {
    return const FloatingActionButtonThemeData(
      backgroundColor: AppColors.cardBg,
      foregroundColor: AppColors.neonGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.neonGreen, width: 1),
      ),
    );
  }
}
