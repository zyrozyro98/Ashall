import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AshallTheme {
  // Brand Colors from Logo
  static const Color primaryColor = Color(0xFF01244E);    // Deep Blue
  static const Color primaryLight = Color(0xFF1A4B8C);
  static const Color secondaryColor = Color(0xFFF57C00);  // Radiant Orange
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color accentColor = Color(0xFF4CAF50);     // Progress Green
  static const Color backgroundColor = Color(0xFFF8F9FA); // Light Grey/White
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF1A1C1E);
  static const Color subtitleColor = Color(0xFF70777F);
  
  // Feedback Colors
  static const Color successColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFFBC02D);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color infoColor = Color(0xFF0288D1);

  // Advanced Gradients
  static const Gradient premiumGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF003366)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [secondaryColor, Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles - Global Standards
  static final TextStyle displayStyle = GoogleFonts.cairo(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: primaryColor,
    height: 1.1,
  );

  static final TextStyle titleStyle = GoogleFonts.cairo(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: primaryColor,
    letterSpacing: -0.5,
  );

  static final TextStyle subtitleStyle = GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: subtitleColor,
  );

  static final TextStyle bodyStyle = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  static final TextStyle captionStyle = GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: subtitleColor,
  );

  // Modern Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> deepShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.1),
      blurRadius: 30,
      offset: const Offset(0, 15),
    ),
  ];

  // Global Decorations
  static BoxDecoration premiumCardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(24),
    boxShadow: softShadow,
    border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
  );

  static BoxDecoration buttonDecoration = BoxDecoration(
    gradient: premiumGradient,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.25),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

