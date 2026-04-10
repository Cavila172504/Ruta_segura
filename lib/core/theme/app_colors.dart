import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF705D00); // Yellow/Brownish dark
  static const Color primaryContainer = Color(0xFFFFD700); // Yellow gold
  static const Color secondary = Color(0xFF086B53); // Dark teal/green
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceContainerLow = Color(0xFFF3F3F4); 
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF4D4732);
  static const Color outline = Color(0xFF7E775F);
  static const Color error = Color(0xFFBA1A1A);
  
  static const LinearGradient buttonMetallic = LinearGradient(
    colors: [Color(0xFF705D00), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
