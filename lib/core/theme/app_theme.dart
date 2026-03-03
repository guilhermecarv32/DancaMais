import 'package:flutter/material.dart';

class DancaMaisTheme {
  // Cores globais que podem ser trocadas depois
  static Color primaryColor = const Color(0xFFF05A40); // O laranja do protótipo
  static Color secondaryColor = const Color(0xFF4A4A4A); 

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(backgroundColor: primaryColor),
    );
  }
}