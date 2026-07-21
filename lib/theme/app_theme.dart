import 'package:flutter/material.dart';

/// Semantic color tokens that adapt to light / dark mode.
///
/// Registered as a [ThemeExtension] on both light and dark [ThemeData].
/// Access via `context.colors` (see [AppColorsExt]).
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accentPrimary,
    required this.accentHover,
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.foregroundPrimary,
    required this.foregroundSecondary,
    required this.foregroundMuted,
    required this.borderSubtle,
    required this.toolbarBg,
    required this.sidebarBg,
    required this.danger,
  });

  final Color accentPrimary;
  final Color accentHover;
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color foregroundPrimary;
  final Color foregroundSecondary;
  final Color foregroundMuted;
  final Color borderSubtle;
  final Color toolbarBg;
  final Color sidebarBg;
  final Color danger;

  // ── Light palette ──────────────────────────────────────────────
  static const light = AppColors(
    accentPrimary: Color(0xFFEE6B5B),
    accentHover: Color(0xFFD95A4A),
    surfacePrimary: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFFAF9F8),
    surfaceTertiary: Color(0xFFF0EDEB),
    foregroundPrimary: Color(0xFF2D2D2D),
    foregroundSecondary: Color(0xFF5A5A5A),
    foregroundMuted: Color(0xFF8A8A8A),
    borderSubtle: Color(0xFFE5E2DF),
    toolbarBg: Color(0xFFFCFBFA),
    sidebarBg: Color(0xFFF5F3F1),
    danger: Color(0xFFD94040),
  );

  // ── Dark palette ───────────────────────────────────────────────
  static const dark = AppColors(
    accentPrimary: Color(0xFFEE6B5B),
    accentHover: Color(0xFFF07D6F),
    surfacePrimary: Color(0xFF1A1A1A),
    surfaceSecondary: Color(0xFF222222),
    surfaceTertiary: Color(0xFF2E2E2E),
    foregroundPrimary: Color(0xFFE8E8E8),
    foregroundSecondary: Color(0xFFA0A0A0),
    // 8A: surfacePrimary(#1A1A1A) 위에서 대비 ≈5.0:1 (WCAG AA 충족).
    // 기존 6A는 3.2:1로 11px 힌트 텍스트가 AA 미달이었다.
    foregroundMuted: Color(0xFF8A8A8A),
    borderSubtle: Color(0xFF3A3A3A),
    toolbarBg: Color(0xFF1E1E1E),
    sidebarBg: Color(0xFF242424),
    danger: Color(0xFFE05050),
  );

  @override
  AppColors copyWith({
    Color? accentPrimary,
    Color? accentHover,
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? surfaceTertiary,
    Color? foregroundPrimary,
    Color? foregroundSecondary,
    Color? foregroundMuted,
    Color? borderSubtle,
    Color? toolbarBg,
    Color? sidebarBg,
    Color? danger,
  }) {
    return AppColors(
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentHover: accentHover ?? this.accentHover,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceTertiary: surfaceTertiary ?? this.surfaceTertiary,
      foregroundPrimary: foregroundPrimary ?? this.foregroundPrimary,
      foregroundSecondary: foregroundSecondary ?? this.foregroundSecondary,
      foregroundMuted: foregroundMuted ?? this.foregroundMuted,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      toolbarBg: toolbarBg ?? this.toolbarBg,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      surfaceTertiary: Color.lerp(surfaceTertiary, other.surfaceTertiary, t)!,
      foregroundPrimary: Color.lerp(
        foregroundPrimary,
        other.foregroundPrimary,
        t,
      )!,
      foregroundSecondary: Color.lerp(
        foregroundSecondary,
        other.foregroundSecondary,
        t,
      )!,
      foregroundMuted: Color.lerp(foregroundMuted, other.foregroundMuted, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      toolbarBg: Color.lerp(toolbarBg, other.toolbarBg, t)!,
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Convenience accessor: `context.colors.accentPrimary` etc.
extension AppColorsExt on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Non-color design tokens (spacing, rounding) — theme-independent.
class AppTheme {
  // === Rounding ===
  static const roundedSm = 4.0;
  static const roundedMd = 6.0;
  static const roundedLg = 8.0;
  static const roundedXl = 12.0;

  // === Spacing ===
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 24.0;
}
