import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecommerece_app/core/theming/colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ColorsManager.primary,
      primary: ColorsManager.primary,
      onPrimary: Colors.white,
      secondary: Colors.black,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.red,
      onError: Colors.white,
    );

    final textTheme = GoogleFonts.notoSansTextTheme().copyWith(
      displayLarge: GoogleFonts.notoSans(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
      bodyLarge: GoogleFonts.notoSans(fontSize: 16, color: Colors.black),
      bodyMedium: GoogleFonts.notoSans(fontSize: 14, color: Colors.black),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: ColorsManager.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: ColorsManager.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: GoogleFonts.notoSans(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.notoSans(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.black,
        selectionColor: Colors.black12,
        selectionHandleColor: Colors.black,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => Colors.black,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        titleTextStyle: GoogleFonts.notoSans(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        contentTextStyle: GoogleFonts.notoSans(
          color: Colors.black,
          fontSize: 15,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.black,
      ),
    );
  }
}
