// VidKeep color palette - Retro Terminal Theme
import 'package:flutter/material.dart';

class AppColors {
  // Primary accent - neon phosphor green
  static const Color neonGreen = Color(0xFF00FF41);
  
  // Dark green for secondary accents
  static const Color darkGreen = Color(0xFF003B00);
  
  // Background colors
  static const Color terminalBg = Color(0xFF050505);
  static const Color cardBg = Color(0xFF0A0A0A);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF666666);
  
  // Border color
  static const Color borderColor = Color(0xFF00FF41);
  
  // Status colors
  static const Color statusQueued = Color(0xFF666666);
  static const Color statusDownloading = Color(0xFF00FF41);
  static const Color statusResuming = Color(0xFFFFAA00);
  static const Color statusComplete = Color(0xFF00FF41);
  static const Color statusFailed = Color(0xFFFF4444);
  static const Color statusCancelled = Color(0xFF888888);
}
