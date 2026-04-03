import 'package:flutter/material.dart';

class AppTheme {
  // === Brand ===
  static const brandBlue = Color(0xFF5A7EB5); // Logo "PDF" text color

  // === Accent ===
  static const accentPrimary = Color(0xFFEE6B5B); // Coral - CTA, active state
  static const accentHover = Color(0xFFD95A4A); // Hover/press state

  // === Surface ===
  static const surfacePrimary = Color(0xFFFFFFFF); // Main background
  static const surfaceSecondary = Color(0xFFFAF9F8); // Secondary background (input fields, etc.)
  static const surfaceTertiary = Color(0xFFF0EDEB); // Disabled elements

  // === Foreground (text) ===
  static const foregroundPrimary = Color(0xFF2D2D2D); // Title, body
  static const foregroundSecondary = Color(0xFF5A5A5A); // Secondary text
  static const foregroundMuted = Color(0xFF8A8A8A); // Hint, disabled

  // === Functional ===
  static const borderSubtle = Color(0xFFE5E2DF); // Border
  static const toolbarBg = Color(0xFFFCFBFA); // Toolbar background
  static const sidebarBg = Color(0xFFF5F3F1); // Sidebar background
  static const danger = Color(0xFFD94040); // Error, danger

  // === Rounding ===
  static const roundedSm = 4.0; // Checkbox, tag
  static const roundedMd = 6.0; // Button, input field
  static const roundedLg = 8.0; // Card
  static const roundedXl = 12.0; // Dialog

  // === Spacing ===
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 24.0;
}
