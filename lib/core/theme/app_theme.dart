import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFF05A40); // Cor principal da escola
  static const Color secondary = Color(0xFF9B675D); // Cor secundaria da escola (escura)
  static const Color third = Color(0xFF6241F0); // Cor terciaria da escola
  static const Color accent = Color(0xFFF8B6A8); // Variação da cor principal da escola
  static const Color detail = Color(0xFF88D41C); // Cor de destaque que orne com a escola

  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  // Modo escuro — só troca o fundo
  static const Color darkBackground = Color(0xFF262624);

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        brightness: Brightness.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // Idêntico ao themeData — só muda o scaffoldBackgroundColor
  static ThemeData get darkThemeData {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        brightness: Brightness.light, // mantém light para não alterar nada mais
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}