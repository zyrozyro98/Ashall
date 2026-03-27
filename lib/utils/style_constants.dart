import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AshallTheme {
  // Brand Colors from Logo
  static const Color primaryColor = Color(0xFF01244E);    // Deep Blue
  static const Color secondaryColor = Color(0xFFF57C00);  // Radiant Orange/Red
  static const Color accentColor = Color(0xFF4CAF50);     // Progress Green
  static const Color backgroundColor = Color(0xFFF8F9FA); // Light Grey/White
  static const Color textColor = Color(0xFF212121);
  static const Color subtitleColor = Color(0xFF757575);

  // Text Styles
  static final TextStyle titleStyle = GoogleFonts.cairo(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static final TextStyle subtitleStyle = GoogleFonts.cairo(
    fontSize: 16,
    color: subtitleColor,
  );

  static final TextStyle bodyStyle = GoogleFonts.cairo(
    fontSize: 14,
    color: textColor,
  );

  // Button Decoration
  static BoxDecoration buttonDecoration = BoxDecoration(
    gradient: const LinearGradient(
      colors: [primaryColor, Color(0xFF003366)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withAlpha(76), // 0.3 * 255
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}
