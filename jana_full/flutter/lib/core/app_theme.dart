import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary       = Color(0xFF43A047);
  static const Color primaryLight  = Color(0xFFE8F5E9);
  static const Color primaryDark   = Color(0xFF2E7D32);
  static const Color background    = Color(0xFFF0FBF0);
  static const Color card          = Colors.white;
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint      = Color(0xFFAAAAAA);
  static const Color heartRed      = Color(0xFFE53935);
  static const Color activityOrange = Color(0xFFFB8C00);
  static const Color blue          = Color(0xFF1E88E5);
  static const Color warning       = Color(0xFFFFA726);
  static const Color critical      = Color(0xFFE53935);
  static const Color botBubble     = Color(0xFFDDDDDD);
  static const Color userBubble    = Color(0xFF3F72CF);
  static const Color navBg         = Color(0xFFF5EFE6);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
