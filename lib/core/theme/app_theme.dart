import 'package:flutter/material.dart';

class AppTheme {
  // Cores Genéricas (Siga este padrão em todo o projeto)
  static const Color primary = Color(0xFFF05A40);   // Cor de destaque/ação
  static const Color secondary = Color(0xFF6C2E21); // Cor de contraste/fundo
  static const Color tertiary = Color(0xFFF8B6A8);  // Cor de apoio/suave
  
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFFBFBFB);   // Cor para cards e inputs
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Colors.grey;

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
      ),
      // Customização global de botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}