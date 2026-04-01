import 'package:flutter/material.dart';

class AppTheme {
  // === 액센트 ===
  static const accentPrimary = Color(0xFFEE6B5B); // 코랄 - CTA, 활성 상태
  static const accentHover = Color(0xFFD95A4A); // 호버/프레스 상태

  // === 표면 ===
  static const surfacePrimary = Color(0xFFFFFFFF); // 메인 배경
  static const surfaceSecondary = Color(0xFFFAF9F8); // 보조 배경 (입력필드 등)
  static const surfaceTertiary = Color(0xFFF0EDEB); // 비활성 요소

  // === 전경 (텍스트) ===
  static const foregroundPrimary = Color(0xFF2D2D2D); // 제목, 본문
  static const foregroundSecondary = Color(0xFF5A5A5A); // 보조 텍스트
  static const foregroundMuted = Color(0xFF8A8A8A); // 힌트, 비활성

  // === 기능별 ===
  static const borderSubtle = Color(0xFFE5E2DF); // 테두리
  static const toolbarBg = Color(0xFFFCFBFA); // 툴바 배경
  static const sidebarBg = Color(0xFFF5F3F1); // 사이드바 배경
  static const danger = Color(0xFFD94040); // 에러, 위험

  // === 라운딩 ===
  static const roundedSm = 4.0; // 체크박스, 태그
  static const roundedMd = 6.0; // 버튼, 입력필드
  static const roundedLg = 8.0; // 카드
  static const roundedXl = 12.0; // 다이얼로그

  // === 간격 ===
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 24.0;
}
