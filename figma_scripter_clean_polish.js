// ==============================================================================
// 🏥 [보건약학프로젝트] Figma Scripter - 메모/지시사항을 완성된 실제 디자인으로 변환하는 스크립트
// ==============================================================================
// 
// 📌 정리 대상:
// 1. 📅 캘린더 화면: '누르면 펼쳐지게' 메모 -> [3개 일정 ⌄] 아코디언 토글로 변경 및
//    습관에서 복사되어 어색했던 일정 설명('1분이라도', '5-10분')을 실제 과제 마감시간으로 정비
// 2. 🌱 작은 습관 추가: '밑에는 일주일 눌렀을때 펼쳐지게...' 메모 & '아무튼 일주일' 등 러프한 텍스트를
//    실제 완성된 [주간 자율 (주 3회)] / [요일 지정 (월,수,금)] / [월간 주기] 세부 옵션으로 정돈
// 3. 📝 할일 추가: '습관 이름' -> '할일 이름', '책상 위 물 한 컵' -> '유기화학 과제 제출',
//    '반복 횟수 n번/n일까지... 띄워놓고' 메모 -> 실제 [반복 설정 (ON) · 매주 수요일] 카드로 정비
//
// 📌 실행 방법:
// 1. 피그마에서 [Shift + I] 누르고 Plugins -> 'Scripter' 실행
// 2. 아래 코드를 붙여넣고 [▶ Run] 또는 [Ctrl + Enter] 누르기
// ==============================================================================

async function polishDraftMemosAndCopiedElements() {
  console.clear();
  console.log("🚀 [보건약학프로젝트] 메모 및 임시 UI 요소들을 실제 디자인으로 변환합니다...");

  let updateCount = 0;

  async function safeSetText(textNode, newText, newColor = null) {
    if (!textNode || textNode.type !== "TEXT") return;
    try {
      if (textNode.fontName !== figma.mixed) {
        await figma.loadFontAsync(textNode.fontName);
      } else {
        await figma.loadFontAsync({ family: "Inter", style: "Regular" });
        textNode.fontName = { family: "Inter", style: "Regular" };
      }
      textNode.characters = newText;
      if (newColor) textNode.fills = [{ type: 'SOLID', color: newColor }];
      updateCount++;
    } catch (e) {
      try {
        await figma.loadFontAsync({ family: "Inter", style: "Regular" });
        textNode.fontName = { family: "Inter", style: "Regular" };
        textNode.characters = newText;
        if (newColor) textNode.fills = [{ type: 'SOLID', color: newColor }];
        updateCount++;
      } catch (err) {
        console.warn("텍스트 변경 건너뜀:", textNode.characters, err);
      }
    }
  }

  const pages = figma.root.children;

  // ----------------------------------------------------------------------------
  // 1. 📅 캘린더 화면: '누르면 펼쳐지게' 메모 -> 아코디언 토글 & 과제 상세 정비
  // ----------------------------------------------------------------------------
  for (const page of pages) {
    const expandPills = page.findAll(n => n.type === "TEXT" && n.characters === "누르면 펼쳐지게");
    for (const pill of expandPills) {
      await safeSetText(pill, "3개 일정 ⌄", { r: 0.48, g: 0.38, b: 0.66 });
      if (pill.parent && pill.parent.fills) {
        pill.parent.fills = [{ type: 'SOLID', color: { r: 0.94, g: 0.92, b: 0.98 } }]; // 연보라 뱃지
      }
    }

    // 캘린더 하단 할일 리스트의 어색한 습관 복사 문구 교체
    const calFrames = page.findAll(n => n.name.includes("Calendar"));
    for (const cf of calFrames) {
      const texts = cf.findAll(n => n.type === "TEXT");
      for (const t of texts) {
        if (t.characters === "유연하게 · 1분이라도") {
          await safeSetText(t, "오늘 오후 6:00까지 · 마감 임박", { r: 0.78, g: 0.16, b: 0.16 }); // 마감 임박 강조
        }
        if (t.characters === "5–10분") {
          await safeSetText(t, "오늘 밤 11:59까지 · 리포트 작성");
        }
        if (t.characters === "취침 전 · 선택") {
          await safeSetText(t, "주말 전 완료 · 기숙사 정리");
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // 2. 🌱 작은 습관 추가: 러프한 반복 메모 -> 완성된 주간/월간 세부 옵션으로 정돈
  // ----------------------------------------------------------------------------
  for (const page of pages) {
    const habitAddSheet = page.findOne(n => n.name === "작은 습관 추가");
    if (habitAddSheet) {
      console.log(`🌱 [${page.name}] '작은 습관 추가' 화면 메모 정돈 중...`);
      const texts = habitAddSheet.findAll(n => n.type === "TEXT");
      for (const t of texts) {
        // 1) 지시사항 메모 교체
        if (t.characters.includes("밑에는 일주일 눌렀을때")) {
          await safeSetText(t, "💡 주간 목표를 달성할 요일 또는 횟수를 선택해 주세요", { r: 0.48, g: 0.38, b: 0.66 });
        }
        // 2) 비격식 선택지 문구 교체
        if (t.characters === "아무튼 일주일") {
          await safeSetText(t, "주간 자율 (주 3회)");
        }
        if (t.characters === "요일 선택") {
          await safeSetText(t, "요일 지정 (월, 수, 금)");
        }
        if (t.characters.includes("한달은 몇째주")) {
          await safeSetText(t, "월간 주기 (매월 둘째 주 화요일)");
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // 3. 📝 할일 추가: 습관에서 복사된 placeholder 및 반복 메모 정비
  // ----------------------------------------------------------------------------
  for (const page of pages) {
    const taskAddSheet = page.findOne(n => n.name === "할일 추가");
    if (taskAddSheet) {
      console.log(`📝 [${page.name}] '할일 추가' 화면 메모 및 복사 텍스트 정돈 중...`);
      const texts = taskAddSheet.findAll(n => n.type === "TEXT");
      for (const t of texts) {
        // 습관에서 복사되었던 라벨 및 placeholder 교체
        if (t.characters === "습관 이름") {
          await safeSetText(t, "할일 이름");
        }
        if (t.characters === "예: 책상 위 물 한 컵") {
          await safeSetText(t, "예: 유기화학 과제 제출, 정기 병원 진료");
        }
        if (t.characters === "반복 시간") {
          await safeSetText(t, "마감 기한 및 시간");
        }
        if (t.characters === "캘린더앱 참고") {
          await safeSetText(t, "오후 6:00 (시간 지정)");
        }

        // 반복 설정 지시 메모 교체 -> 실제 옵션 라벨로 승격
        if (t.characters.includes("반복 횟수 n번/n일")) {
          await safeSetText(t, "반복 설정: [있음 ●] (매주 수요일 반복)", { r: 0.48, g: 0.38, b: 0.66 });
        }

        // 하단 선택지 정돈
        if (t.characters === "언제든" && t.parent && t.parent.name.includes("Choice")) {
          await safeSetText(t, "종료일 없음");
        }
        if (t.characters === "아침" && t.parent && t.parent.name.includes("Choice")) {
          await safeSetText(t, "날짜 지정 (종료일)");
        }
        if (t.characters === "저녁" && t.parent && t.parent.name.includes("Choice")) {
          await safeSetText(t, "총 N회 완료 후 종료");
        }
      }
    }
  }

  const msg = `🎉 피그마 내 임시 메모 및 복사 요소 정돈 완료!\n총 ${updateCount}개 텍스트 및 레이어가 완성된 실제 UI 디자인으로 교체되었습니다.`;
  console.log(msg);
  figma.notify(msg, { timeout: 6000 });
}

polishDraftMemosAndCopiedElements();
