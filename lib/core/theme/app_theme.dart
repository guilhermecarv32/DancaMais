import 'package:flutter/material.dart';

class AppTheme {
  // Nomenclatura Genérica para White-Label
  static const Color primary = Color(0xFFF05A40);   // Cor principal (ex: Laranja)
  static const Color secondary = Color(0xFF6C2E21); // Cor de contraste (ex: Marrom)
  static const Color accent = Color(0xFFF8B6A8);    // Cor de destaque suave
  
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF5F5F5);   // Cinza bem claro para inputs
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
      ),
      // Botões herdam a cor primária automaticamente
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}