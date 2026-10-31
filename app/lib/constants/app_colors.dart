import 'package:flutter/material.dart';

/// 하곰이 앱의 핵심 디자인 시스템 테마 색상표
/// 
/// PRD 및 Figma 디자인 분석 기반:
/// - 메인 컬러: 보라(Purple/Lavender) & 갈색(Warm Brown)
/// - 비처벌적이고 편안한 심리적 안정감을 주는 파스텔 톤앤매너
class AppColors {
  // 1. 대표 브랜드 컬러
  static const Color primaryPurple = Color(0xFF7B61A8); // 메인 라벤더 퍼플
  static const Color warmBrown = Color(0xFF8B5E3C);    // 웜 브라운 (신뢰감, 처방 강조)
  static const Color lightLavender = Color(0xFFF3EFF8); // 연한 라벤더 배경색

  // 2. 화면 배경 및 카드 색상
  static const Color background = Color(0xFFFBFBFB);     // 전체 기본 배경
  static const Color cardSurface = Colors.white;         // 카드 기본 흰색
  static const Color divider = Color(0xFFE5E7EB);         // 옅은 구분선

  // 3. 텍스트 컬러
  static const Color textPrimary = Color(0xFF1F2937);    // 주요 글자색 (진한 회색)
  static const Color textSecondary = Color(0xFF6B7280);  // 부가 설명 글자색 (중간 회색)
  static const Color textMuted = Color(0xFF9CA3AF);      // 비활성/보조 글자색

  // 4. 상태 및 피드백 컬러 (신규 6안 달력 틴트)
  static const Color successGreen = Color(0xFF065F46);   // 100% 달성 텍스트
  static const Color successBg = Color(0xFFE6F8F0);      // 100% 달성 연초록 틴트
  static const Color partialOrange = Color(0xFFF59E0B);  // 부분 달성 캡슐 바 오렌지
  static const Color neutralDark = Color(0xFF4B5563);    // 비처벌적 차분한 삭제/취소 색상 (그레이)
  static const Color missedRed = Color(0xFFEF4444);      // 약 미복용 경고 레드 (달력 일요일 등)
}
