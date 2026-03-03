import 'package:flutter/material.dart';

class DancaMaisTheme {
  // Cores extraídas do seu protótipo
  static const Color primaryOrange = Color(0xFFF05A40); 
  static const Color accentCoral = Color(0xFFF8B6A8);

  static ThemeData get theme => ThemeData(
    primaryColor: primaryOrange,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryOrange),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Cinza claro de fundo
    // Aplica a cor laranja em todos os botões do app
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
    ),
  );
}