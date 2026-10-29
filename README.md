# 🏥 보건약학프로젝트 - 복약 & 습관 케어 앱 디자인 및 개발 에셋

본 폴더는 Figma 디자인 분석 및 개발용으로 생성된 모든 핵심 파일들을 모아둔 작업 폴더입니다.

---

## 📂 폴더 및 파일 구조

- **`figma_design_analysis.md`**: 피그마 22개 전체 프레임 심층 분석, UI/UX 구조 및 개선 포인트 정리 보고서
- **`calendar_preview.html`**: 캘린더 점 인디케이터(다중 점 vs 단일 상태 점) 브라우저 전후 비교 미리보기 (더블 클릭하여 브라우저에서 실행 가능)
- **`key_screens/`**: 핵심 5대 화면 고해상도 렌더링 이미지
  - `meds_screen.png` (복약 탭)
  - `habits_screen.png` (작은 습관 탭)
  - `calendar_screen.png` (달력 탭)
  - `mascot_screen.png` (동반자 캐릭터 탭)
  - `settings_screen.png` (설정 탭)
- **`figma_frames/`**: 피그마에서 추출한 22개 전체 프레임 원본 고해상도 이미지 (팝업, 위젯 포함)
- **`figma_plugin/`**: 피그마 캘린더 다중 점을 1초 만에 단일 상태 점으로 일괄 변환하는 플러그인 (`manifest.json`, `code.js`)
- **`fetch_figma.js`**: 피그마 API를 통해 최신 프레임들을 다시 다운로드할 수 있는 스크립트
