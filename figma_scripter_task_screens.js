// ==============================================================================
// 🏥 [보건약학프로젝트] Figma Scripter - 구글 캘린더형 일정 추가 4단계 화면 생성 스크립트
// ==============================================================================
//
// 📌 기획 배경 및 사용 목적:
// Figma에서 인터랙션을 일일이 클릭해보지 않고도, 캔버스에 4개 화면이 가로로 나열되어
// "사용자가 무엇을 눌렀을 때 화면이 어떻게 단계적으로 반응하는지" 한눈에 파악할 수 있습니다!
//
// 🌟 4대 단계별 화면 구성 (Step-by-Step Flow):
// 1. [STEP 1] 기본형 (반복 없음) : [● 반복 없음] 활성, 옵션 숨김 -> 3초 빠른 등록
// 2. [STEP 2] 기본 반복형 (구글 프리셋) : [● 반복 있음] 탭 시 -> [매일, 매주 수, 매월, 맞춤] 프리셋 펼침
// 3. [STEP 3] 맞춤 반복형 (구글 요일 칩) : [⚙️ 맞춤...] 탭 시 -> N주 간격 + [월/수/금] 요일 칩 다중 선택
// 4. [STEP 4] 종료 조건형 (기한 완결) : [종료일 조건] 설정 시 -> 특정 날짜(2026.12.31까지) 지정 완결
//
// 📌 실행 방법:
// 1. 피그마에서 [Shift + I] 누르고 Plugins -> 'Scripter' 실행
// 2. 아래 코드를 전체 복사하여 붙여넣기
// 3. 우측 상단 [▶ Run] 또는 [Ctrl + Enter] 누르기
// ==============================================================================

async function generateGoogleCalendarTaskFlowScreens() {
  console.clear();
  console.log("🚀 [보건약학프로젝트] 구글 캘린더형 일정 추가 4단계 분기 화면 생성 시작...");

  // ----------------------------------------------------------------------------
  // 🎨 컬러 팔레트 (라벤더 & 퍼플 & 웜 브라운 조화)
  // ----------------------------------------------------------------------------
  const C = {
    primaryPurple: { r: 0.41, g: 0.30, b: 0.59 },    // #694C97 (메인 딥 퍼플)
    accentLavender: { r: 0.94, g: 0.92, b: 0.98 },   // #EFE9F7 (선택 칩 배경)
    borderLavender: { r: 0.78, g: 0.71, b: 0.88 },   // #C7B5E0 (선택 보더)
    pureWhite: { r: 1.0, g: 1.0, b: 1.0 },           // #FFFFFF
    textDark: { r: 0.12, g: 0.14, b: 0.17 },          // #1F242C (기본 본문)
    textMuted: { r: 0.45, g: 0.47, b: 0.52 },         // #737885 (설명/비활성)
    borderLight: { r: 0.88, g: 0.90, b: 0.93 },       // #E1E6EE (비활성 테두리)
    bgLight: { r: 0.97, g: 0.98, b: 0.99 },           // #F7F9FC (카드 배경)
    badgeBg: { r: 0.92, g: 0.89, b: 0.96 },           // #EBE3F5 (스텝 뱃지 배경)
    successGreen: { r: 0.18, g: 0.65, b: 0.42 },      // #2EA66B
    coralPoint: { r: 0.89, g: 0.24, b: 0.24 }         // #E53E3E
  };

  // ----------------------------------------------------------------------------
  // 🔤 폰트 안전 로드 및 텍스트 설정 헬퍼
  // ----------------------------------------------------------------------------
  async function loadInter(style = "Regular") {
    try {
      await figma.loadFontAsync({ family: "Inter", style: style });
      return { family: "Inter", style: style };
    } catch (e) {
      await figma.loadFontAsync({ family: "Inter", style: "Regular" });
      return { family: "Inter", style: "Regular" };
    }
  }

  await loadInter("Regular");
  await loadInter("Medium");
  await loadInter("Bold");

  async function safeSetText(textNode, text, color = null, fontSize = null, isBold = false) {
    if (!textNode || textNode.type !== "TEXT") return;
    try {
      const font = await loadInter(isBold ? "Bold" : "Regular");
      textNode.fontName = font;
      textNode.characters = text;
      if (color) textNode.fills = [{ type: 'SOLID', color: color }];
      if (fontSize) textNode.fontSize = fontSize;
    } catch (err) {
      console.warn("텍스트 설정 예외:", err);
    }
  }

  function setFlexFill(node) {
    try { node.layoutAlign = "STRETCH"; } catch (e) {}
    try { node.layoutSizingHorizontal = "FILL"; } catch (e) {}
  }

  // ----------------------------------------------------------------------------
  // 🛠️ UI 컴포넌트 생성 헬퍼 함수들
  // ----------------------------------------------------------------------------

  // 1) 상단 스텝 안내 배너 (화면 상단에 배치되어 인터랙션을 설명)
  async function createStepHeaderBanner(stepNumber, titleText, descText) {
    const banner = figma.createFrame();
    banner.name = `Step Banner - STEP ${stepNumber}`;
    banner.layoutMode = "VERTICAL";
    banner.primaryAxisSizingMode = "AUTO";
    banner.counterAxisSizingMode = "AUTO";
    setFlexFill(banner);
    banner.paddingTop = 14;
    banner.paddingBottom = 14;
    banner.paddingLeft = 16;
    banner.paddingRight = 16;
    banner.itemSpacing = 4;
    banner.cornerRadius = 14;
    banner.fills = [{ type: 'SOLID', color: C.badgeBg }];
    banner.strokes = [{ type: 'SOLID', color: C.borderLavender }];
    banner.strokeWeight = 1.5;

    // 배지 & 타이틀 행
    const topRow = figma.createFrame();
    topRow.name = "Banner Top Row";
    topRow.layoutMode = "HORIZONTAL";
    topRow.counterAxisAlignItems = "CENTER";
    topRow.itemSpacing = 8;
    topRow.fills = [];
    setFlexFill(topRow);

    const badge = figma.createFrame();
    badge.name = "Step Badge";
    badge.layoutMode = "HORIZONTAL";
    badge.primaryAxisAlignItems = "CENTER";
    badge.counterAxisAlignItems = "CENTER";
    badge.paddingTop = 3;
    badge.paddingBottom = 3;
    badge.paddingLeft = 8;
    badge.paddingRight = 8;
    badge.cornerRadius = 6;
    badge.fills = [{ type: 'SOLID', color: C.primaryPurple }];

    const badgeTxt = figma.createText();
    await safeSetText(badgeTxt, `STEP ${stepNumber}`, C.pureWhite, 11, true);
    badge.appendChild(badgeTxt);

    const titleTxt = figma.createText();
    await safeSetText(titleTxt, titleText, C.primaryPurple, 13.5, true);

    topRow.appendChild(badge);
    topRow.appendChild(titleTxt);

    // 하단 설명 가이드 텍스트
    const descTxt = figma.createText();
    await safeSetText(descTxt, descText, C.textDark, 11.5, false);

    banner.appendChild(topRow);
    banner.appendChild(descTxt);
    return banner;
  }

  // 2) 칩 버튼 생성 헬퍼
  async function createChip(label, isSelected, icon = "") {
    const chip = figma.createFrame();
    chip.name = `Chip - ${label}`;
    chip.layoutMode = "HORIZONTAL";
    chip.primaryAxisAlignItems = "CENTER";
    chip.counterAxisAlignItems = "CENTER";
    chip.paddingTop = 7;
    chip.paddingBottom = 7;
    chip.paddingLeft = 12;
    chip.paddingRight = 12;
    chip.itemSpacing = 4;
    chip.cornerRadius = 18;

    if (isSelected) {
      chip.fills = [{ type: 'SOLID', color: C.accentLavender }];
      chip.strokes = [{ type: 'SOLID', color: C.primaryPurple }];
      chip.strokeWeight = 1.5;
    } else {
      chip.fills = [{ type: 'SOLID', color: C.pureWhite }];
      chip.strokes = [{ type: 'SOLID', color: C.borderLight }];
      chip.strokeWeight = 1;
    }

    const txt = figma.createText();
    const fullText = (isSelected ? "● " : "") + (icon ? `${icon} ` : "") + label;
    await safeSetText(txt, fullText, isSelected ? C.primaryPurple : C.textMuted, 12, isSelected);
    chip.appendChild(txt);
    return chip;
  }

  // 3) 요일 원형 칩 생성 (월, 화, 수, 목, 금, 토, 일)
  async function createWeekdayCircleChip(dayName, isSelected) {
    const circle = figma.createFrame();
    circle.name = `DayChip - ${dayName}`;
    circle.layoutMode = "HORIZONTAL";
    circle.primaryAxisAlignItems = "CENTER";
    circle.counterAxisAlignItems = "CENTER";
    circle.resize(36, 36);
    circle.cornerRadius = 18;

    if (isSelected) {
      circle.fills = [{ type: 'SOLID', color: C.primaryPurple }];
    } else {
      circle.fills = [{ type: 'SOLID', color: C.pureWhite }];
      circle.strokes = [{ type: 'SOLID', color: C.borderLight }];
      circle.strokeWeight = 1;
    }

    const txt = figma.createText();
    await safeSetText(txt, dayName, isSelected ? C.pureWhite : C.textMuted, 12.5, isSelected);
    circle.appendChild(txt);
    return circle;
  }

  // 4) 요약 알림 배너
  async function createSummaryBanner(icon, text) {
    const box = figma.createFrame();
    box.name = "Summary Banner";
    box.layoutMode = "HORIZONTAL";
    box.counterAxisAlignItems = "CENTER";
    setFlexFill(box);
    box.paddingTop = 9;
    box.paddingBottom = 9;
    box.paddingLeft = 12;
    box.paddingRight = 12;
    box.itemSpacing = 6;
    box.cornerRadius = 8;
    box.fills = [{ type: 'SOLID', color: { r: 0.95, g: 0.93, b: 0.98 } }];

    const t = figma.createText();
    await safeSetText(t, `${icon} ${text}`, C.primaryPurple, 11.5, true);
    box.appendChild(t);
    return box;
  }

  // ----------------------------------------------------------------------------
  // 🚀 메인 프로세스: 피그마 페이지 순회 및 프레임 생성
  // ----------------------------------------------------------------------------
  const pages = figma.root.children;

  for (const page of pages) {
    // 기준 프레임 찾기
    const origTaskFrame = page.findOne(n => 
      (n.name === "할일 추가" && !n.name.includes("형") && !n.name.includes("STEP")) ||
      n.name.includes("할일 추가 - 1") ||
      n.name.startsWith("할일 추가")
    );

    if (!origTaskFrame || origTaskFrame.type !== "FRAME") continue;

    console.log(`📄 [${page.name}] 기준 프레임 '${origTaskFrame.name}' 발견! 4단계 화면 생성...`);

    // 이전 생성된 스텝 프레임들 삭제
    const prevs = page.findAll(n => 
      n.name.includes("할일 추가 - STEP") || 
      n.name.includes("할일 추가 - 1") || 
      n.name.includes("할일 추가 - 2") ||
      n.name.includes("할일 추가 - 3") ||
      n.name.includes("할일 추가 - 4")
    );
    for (const p of prevs) p.remove();

    const frameW = origTaskFrame.width || 375;
    const spacingX = frameW + 60;
    const baseY = origTaskFrame.y + origTaskFrame.height + 120;
    const baseX = origTaskFrame.x;

    // ==========================================================================
    // 🌟 [STEP 1] 기본형 (반복 없음 선택 상태)
    // ==========================================================================
    const frame1 = origTaskFrame.clone();
    frame1.name = "할일 추가 - STEP 1 (기본형: 반복 없음)";
    frame1.x = baseX;
    frame1.y = baseY;

    const banner1 = await createStepHeaderBanner(
      1, 
      "단발성 기본 등록 (반복 없음)", 
      "👉 [반복 없음] 선택 시: 하단 옵션 없이 3초 만에 빠른 등록"
    );
    frame1.insertChild(0, banner1);

    const form1 = frame1.findOne(n => n.name === "Habit form") || frame1.findOne(n => n.type === "FRAME" && n.children.length >= 3);
    if (form1) {
      // 1) 이름
      const f0 = form1.children[0];
      if (f0) {
        for (const t of f0.findAll(n => n.type === "TEXT")) {
          if (t.characters === "습관 이름") await safeSetText(t, "할일 이름", null, null, true);
          if (t.characters.includes("책상") || t.characters.includes("예:")) await safeSetText(t, "유기화학 3단원 과제 제출");
        }
      }
      // 2) 날짜/시간
      const f1 = form1.children[1];
      if (f1) {
        for (const t of f1.findAll(n => n.type === "TEXT")) {
          if (t.characters === "반복 시간") await safeSetText(t, "날짜 및 마감 시간", null, null, true);
          if (t.characters.includes("10/14") || t.characters.includes("오늘")) await safeSetText(t, "오늘 (10/14 수)");
          if (t.characters === "일주일마다") await safeSetText(t, "종일");
          if (t.characters === "직접 입력") await safeSetText(t, "오후 6:00");
        }
      }
      // 3) 반복 토글 버튼
      const f2 = form1.children[2];
      if (f2) {
        const timeChoices = f2.findOne(n => n.name === "Time choices");
        if (timeChoices && timeChoices.children.length >= 2) {
          const btnNo = timeChoices.children[0];
          const btnYes = timeChoices.children[1];
          if (btnNo) {
            btnNo.fills = [{ type: 'SOLID', color: C.accentLavender }];
            const t = btnNo.findOne(n => n.type === "TEXT");
            if (t) await safeSetText(t, "● 반복 없음", C.primaryPurple, 12.5, true);
          }
          if (btnYes) {
            btnYes.fills = [{ type: 'SOLID', color: C.pureWhite }];
            const t = btnYes.findOne(n => n.type === "TEXT");
            if (t) await safeSetText(t, "○ 반복 있음", C.textMuted, 12.5, false);
          }
        }
      }
      // 4) 1번 화면에서는 하단 세부 박스 숨김
      if (form1.children.length > 3) {
        form1.children[3].remove();
      }
      const reminder = form1.findOne(n => n.name === "Reminder note");
      if (reminder) {
        const t = reminder.findOne(n => n.type === "TEXT");
        if (t) await safeSetText(t, "놓쳐도 괜찮아요. 언제든 다시 일정을 조율할 수 있어요.");
      }
    }
    const cta1 = frame1.findOne(n => n.type === "TEXT" && (n.characters.includes("저장") || n.characters.includes("추가")));
    if (cta1) await safeSetText(cta1, "할일 저장", C.pureWhite, 14, true);

    // ==========================================================================
    // 🌟 [STEP 2] 구글 캘린더 기본 프리셋 (매일/매주/매월 빠른 선택)
    // ==========================================================================
    const frame2 = origTaskFrame.clone();
    frame2.name = "할일 추가 - STEP 2 (반복 켬: 구글 프리셋)";
    frame2.x = baseX + spacingX * 1;
    frame2.y = baseY;

    const banner2 = await createStepHeaderBanner(
      2, 
      "[반복 있음] 탭 시 -> 프리셋 선택", 
      "👉 구글 캘린더의 대표 반복 주기(매일/매주/매월)가 즉시 펼쳐짐"
    );
    frame2.insertChild(0, banner2);

    const form2 = frame2.findOne(n => n.name === "Habit form") || frame2.findOne(n => n.type === "FRAME" && n.children.length >= 3);
    if (form2) {
      // 1) 이름
      const f0 = form2.children[0];
      if (f0) {
        for (const t of f0.findAll(n => n.type === "TEXT")) {
          if (t.characters === "습관 이름") await safeSetText(t, "할일 이름", null, null, true);
          if (t.characters.includes("책상") || t.characters.includes("예:")) await safeSetText(t, "정기 정신건강의학과 상담");
        }
      }
      // 2) 반복 토글 버튼: [반복 있음] 선택!
      const f2 = form2.children[2];
      if (f2) {
        const timeChoices = f2.findOne(n => n.name === "Time choices");
        if (timeChoices && timeChoices.children.length >= 2) {
          const btnNo = timeChoices.children[0];
          const btnYes = timeChoices.children[1];
          if (btnNo) {
            btnNo.fills = [{ type: 'SOLID', color: C.pureWhite }];
            const t = btnNo.findOne(n => n.type === "TEXT");
            if (t) await safeSetText(t, "○ 반복 없음", C.textMuted, 12.5, false);
          }
          if (btnYes) {
            btnYes.fills = [{ type: 'SOLID', color: C.accentLavender }];
            const t = btnYes.findOne(n => n.type === "TEXT");
            if (t) await safeSetText(t, "● 반복 있음", C.primaryPurple, 12.5, true);
          }
        }
      }
      // 3) 세부 박스: 구글 캘린더 프리셋 카드로 완전 교체
      let detailBox = form2.children[3];
      if (!detailBox) {
        detailBox = figma.createFrame();
        form2.appendChild(detailBox);
      }
      while (detailBox.children.length > 0) detailBox.children[0].remove();

      detailBox.name = "Google Presets Box";
      detailBox.layoutMode = "VERTICAL";
      detailBox.primaryAxisSizingMode = "AUTO";
      detailBox.counterAxisSizingMode = "AUTO";
      setFlexFill(detailBox);
      detailBox.paddingTop = 14;
      detailBox.paddingBottom = 14;
      detailBox.paddingLeft = 14;
      detailBox.paddingRight = 14;
      detailBox.itemSpacing = 10;
      detailBox.cornerRadius = 12;
      detailBox.fills = [{ type: 'SOLID', color: C.bgLight }];
      detailBox.strokes = [{ type: 'SOLID', color: C.borderLavender }];
      detailBox.strokeWeight = 1;

      // 헤더 레이블
      const boxTitle = figma.createText();
      await safeSetText(boxTitle, "반복 주기 (Google Calendar Presets)", C.primaryPurple, 12, true);
      detailBox.appendChild(boxTitle);

      // 프리셋 칩 행 1: 매일, 매주 수요일, 매월
      const chipRow1 = figma.createFrame();
      chipRow1.layoutMode = "HORIZONTAL";
      chipRow1.itemSpacing = 8;
      chipRow1.fills = [];
      setFlexFill(chipRow1);

      chipRow1.appendChild(await createChip("매일", false));
      chipRow1.appendChild(await createChip("매주 수요일", true)); // 선택됨!
      chipRow1.appendChild(await createChip("매월 14일", false));
      detailBox.appendChild(chipRow1);

      // 프리셋 칩 행 2: 평일, 맞춤...
      const chipRow2 = figma.createFrame();
      chipRow2.layoutMode = "HORIZONTAL";
      chipRow2.itemSpacing = 8;
      chipRow2.fills = [];
      setFlexFill(chipRow2);

      chipRow2.appendChild(await createChip("주중(월~금)", false));
      chipRow2.appendChild(await createChip("맞춤 설정...", false, "⚙️"));
      detailBox.appendChild(chipRow2);

      // 요약 알림
      detailBox.appendChild(await createSummaryBanner("📅", "매주 수요일마다 같은 시간에 반복됩니다."));
    }
    const cta2 = frame2.findOne(n => n.type === "TEXT" && (n.characters.includes("저장") || n.characters.includes("추가")));
    if (cta2) await safeSetText(cta2, "반복 일정 저장", C.pureWhite, 14, true);

    // ==========================================================================
    // 🌟 [STEP 3] 구글 캘린더 맞춤 설정 (N주 간격 + 요일 다중 선택 칩)
    // ==========================================================================
    const frame3 = origTaskFrame.clone();
    frame3.name = "할일 추가 - STEP 3 (맞춤: 요일 다중 선택)";
    frame3.x = baseX + spacingX * 2;
    frame3.y = baseY;

    const banner3 = await createStepHeaderBanner(
      3, 
      "[맞춤...] 탭 시 -> 요일 칩 다중 선택", 
      "👉 구글 캘린더의 핵심: N주 주기 + [월/수/금] 요일 다중 선택"
    );
    frame3.insertChild(0, banner3);

    const form3 = frame3.findOne(n => n.name === "Habit form") || frame3.findOne(n => n.type === "FRAME" && n.children.length >= 3);
    if (form3) {
      const f0 = form3.children[0];
      if (f0) {
        for (const t of f0.findAll(n => n.type === "TEXT")) {
          if (t.characters === "습관 이름") await safeSetText(t, "할일 이름", null, null, true);
          if (t.characters.includes("책상") || t.characters.includes("예:")) await safeSetText(t, "유산소 운동 & 햇볕 쬐기");
        }
      }
      // [반복 있음] 활성화
      const f2 = form3.children[2];
      if (f2) {
        const timeChoices = f2.findOne(n => n.name === "Time choices");
        if (timeChoices && timeChoices.children.length >= 2) {
          const btnNo = timeChoices.children[0];
          const btnYes = timeChoices.children[1];
          if (btnNo) {
            btnNo.fills = [{ type: 'SOLID', color: C.pureWhite }];
            const t = btnNo.findOne(n => n.type === "TEXT");
            if (t) await safeSetText(t, "○ 반복 없음", C.textMuted, 12.5, false);
          }
          if (btnYes) {
            btnYes.fills = [{ type: 'SOLID', color: C.accentLavender }];
            const t = btnYes.findOne(n => n.type === "TEXT");
            if (t) await safeSetText(t, "● 반복 있음", C.primaryPurple, 12.5, true);
          }
        }
      }

      // 맞춤 요일 다중 선택 박스
      let detailBox = form3.children[3];
      if (!detailBox) {
        detailBox = figma.createFrame();
        form3.appendChild(detailBox);
      }
      while (detailBox.children.length > 0) detailBox.children[0].remove();

      detailBox.name = "Custom Weekday Box";
      detailBox.layoutMode = "VERTICAL";
      detailBox.primaryAxisSizingMode = "AUTO";
      detailBox.counterAxisSizingMode = "AUTO";
      setFlexFill(detailBox);
      detailBox.paddingTop = 14;
      detailBox.paddingBottom = 14;
      detailBox.paddingLeft = 14;
      detailBox.paddingRight = 14;
      detailBox.itemSpacing = 12;
      detailBox.cornerRadius = 12;
      detailBox.fills = [{ type: 'SOLID', color: C.bgLight }];
      detailBox.strokes = [{ type: 'SOLID', color: C.borderLavender }];
      detailBox.strokeWeight = 1.5;

      // 1) 주기 간격 인풋 행
      const intervalRow = figma.createFrame();
      intervalRow.layoutMode = "HORIZONTAL";
      intervalRow.counterAxisAlignItems = "CENTER";
      intervalRow.itemSpacing = 8;
      intervalRow.fills = [];
      setFlexFill(intervalRow);

      const intervalLbl = figma.createText();
      await safeSetText(intervalLbl, "반복 주기", C.textDark, 12, true);

      const numInput = figma.createFrame();
      numInput.layoutMode = "HORIZONTAL";
      numInput.primaryAxisAlignItems = "CENTER";
      numInput.counterAxisAlignItems = "CENTER";
      numInput.paddingTop = 5; numInput.paddingBottom = 5; numInput.paddingLeft = 10; numInput.paddingRight = 10;
      numInput.cornerRadius = 6;
      numInput.fills = [{ type: 'SOLID', color: C.pureWhite }];
      numInput.strokes = [{ type: 'SOLID', color: C.borderLight }];
      const numTxt = figma.createText();
      await safeSetText(numTxt, "1", C.primaryPurple, 13, true);
      numInput.appendChild(numTxt);

      const unitSelect = figma.createFrame();
      unitSelect.layoutMode = "HORIZONTAL";
      unitSelect.primaryAxisAlignItems = "CENTER";
      unitSelect.counterAxisAlignItems = "CENTER";
      unitSelect.paddingTop = 5; unitSelect.paddingBottom = 5; unitSelect.paddingLeft = 10; unitSelect.paddingRight = 10;
      unitSelect.cornerRadius = 6;
      unitSelect.fills = [{ type: 'SOLID', color: C.accentLavender }];
      const unitTxt = figma.createText();
      await safeSetText(unitTxt, "주마다 ⌄", C.primaryPurple, 12, true);
      unitSelect.appendChild(unitTxt);

      intervalRow.appendChild(intervalLbl);
      intervalRow.appendChild(numInput);
      intervalRow.appendChild(unitSelect);
      detailBox.appendChild(intervalRow);

      // 2) 7대 요일 선택기 (일, 월, 화, 수, 목, 금, 토) -> 월/수/금 활성화!
      const weekdayBox = figma.createFrame();
      weekdayBox.layoutMode = "VERTICAL";
      weekdayBox.itemSpacing = 6;
      weekdayBox.fills = [];
      setFlexFill(weekdayBox);

      const weekdayLbl = figma.createText();
      await safeSetText(weekdayLbl, "반복 요일 (다중 선택 가능)", C.textDark, 12, true);
      weekdayBox.appendChild(weekdayLbl);

      const daysRow = figma.createFrame();
      daysRow.layoutMode = "HORIZONTAL";
      daysRow.primaryAxisAlignItems = "SPACE_BETWEEN";
      daysRow.counterAxisAlignItems = "CENTER";
      daysRow.fills = [];
      setFlexFill(daysRow);

      daysRow.appendChild(await createWeekdayCircleChip("일", false));
      daysRow.appendChild(await createWeekdayCircleChip("월", true));  // 선택
      daysRow.appendChild(await createWeekdayCircleChip("화", false));
      daysRow.appendChild(await createWeekdayCircleChip("수", true));  // 선택
      daysRow.appendChild(await createWeekdayCircleChip("목", false));
      daysRow.appendChild(await createWeekdayCircleChip("금", true));  // 선택
      daysRow.appendChild(await createWeekdayCircleChip("토", false));
      weekdayBox.appendChild(daysRow);
      detailBox.appendChild(weekdayBox);

      // 3) 요약 배너 & 하단 힌트
      detailBox.appendChild(await createSummaryBanner("✨", "매주 월, 수, 금요일마다 반복"));

      const hintText = figma.createText();
      await safeSetText(hintText, "종료일: 계속 반복 (탭하여 기한 지정 ⌄)", C.textMuted, 11, false);
      detailBox.appendChild(hintText);
    }
    const cta3 = frame3.findOne(n => n.type === "TEXT" && (n.characters.includes("저장") || n.characters.includes("추가")));
    if (cta3) await safeSetText(cta3, "맞춤 일정 저장", C.pureWhite, 14, true);

    // ==========================================================================
    // 🌟 [STEP 4] 구글 캘린더 종료 조건 (특정 날짜까지 지정 완결)
    // ==========================================================================
    const frame4 = origTaskFrame.clone();
    frame4.name = "할일 추가 - STEP 4 (종료 조건: 기한 완결)";
    frame4.x = baseX + spacingX * 3;
    frame4.y = baseY;

    const banner4 = await createStepHeaderBanner(
      4, 
      "[종료 조건] 설정 시 -> 기한 완결", 
      "👉 구글 캘린더 종료 옵션: 특정 날짜(2026.12.31까지) 또는 N회 지정"
    );
    frame4.insertChild(0, banner4);

    const form4 = frame4.findOne(n => n.name === "Habit form") || frame4.findOne(n => n.type === "FRAME" && n.children.length >= 3);
    if (form4) {
      const f0 = form4.children[0];
      if (f0) {
        for (const t of f0.findAll(n => n.type === "TEXT")) {
          if (t.characters === "습관 이름") await safeSetText(t, "할일 이름", null, null, true);
          if (t.characters.includes("책상") || t.characters.includes("예:")) await safeSetText(t, "캡스톤 프로젝트 정기 랩미팅");
        }
      }
      const f2 = form4.children[2];
      if (f2) {
        const timeChoices = f2.findOne(n => n.name === "Time choices");
        if (timeChoices && timeChoices.children.length >= 2) {
          const btnNo = timeChoices.children[0];
          const btnYes = timeChoices.children[1];
          if (btnNo) {
            btnNo.fills = [{ type: 'SOLID', color: C.pureWhite }];
            const t = btnNo.findOne(n => n.type === "TEXT");
            if (t) await safeSetText(t, "○ 반복 없음", C.textMuted, 12.5, false);
          }
          if (btnYes) {
            btnYes.fills = [{ type: 'SOLID', color: C.accentLavender }];
            const t = btnYes.findOne(n => n.type === "TEXT");
            if (t) await safeSetText(t, "● 반복 있음", C.primaryPurple, 12.5, true);
          }
        }
      }

      // 맞춤 설정 + 구글 캘린더 종료 조건 라디오 박스
      let detailBox = form4.children[3];
      if (!detailBox) {
        detailBox = figma.createFrame();
        form4.appendChild(detailBox);
      }
      while (detailBox.children.length > 0) detailBox.children[0].remove();

      detailBox.name = "End Condition Box";
      detailBox.layoutMode = "VERTICAL";
      detailBox.primaryAxisSizingMode = "AUTO";
      detailBox.counterAxisSizingMode = "AUTO";
      setFlexFill(detailBox);
      detailBox.paddingTop = 14;
      detailBox.paddingBottom = 14;
      detailBox.paddingLeft = 14;
      detailBox.paddingRight = 14;
      detailBox.itemSpacing = 10;
      detailBox.cornerRadius = 12;
      detailBox.fills = [{ type: 'SOLID', color: C.bgLight }];
      detailBox.strokes = [{ type: 'SOLID', color: C.borderLavender }];
      detailBox.strokeWeight = 1.5;

      // 1) 상단 요약
      const topSummary = figma.createFrame();
      topSummary.layoutMode = "HORIZONTAL";
      topSummary.primaryAxisAlignItems = "SPACE_BETWEEN";
      topSummary.counterAxisAlignItems = "CENTER";
      topSummary.fills = [];
      setFlexFill(topSummary);

      const sumTxt = figma.createText();
      await safeSetText(sumTxt, "주기: 매주 월, 수, 금 (1주 간격)", C.textDark, 12, true);
      const editTxt = figma.createText();
      await safeSetText(editTxt, "변경", C.primaryPurple, 11, true);
      topSummary.appendChild(sumTxt);
      topSummary.appendChild(editTxt);
      detailBox.appendChild(topSummary);

      // 구분선
      const divider = figma.createFrame();
      divider.resize(100, 1);
      setFlexFill(divider);
      divider.fills = [{ type: 'SOLID', color: C.borderLight }];
      detailBox.appendChild(divider);

      // 2) 종료 조건 라디오 그룹
      const endTitle = figma.createText();
      await safeSetText(endTitle, "종료 조건 (Google Calendar Type)", C.primaryPurple, 12, true);
      detailBox.appendChild(endTitle);

      // 라디오 1: 계속 반복
      const radio1 = figma.createFrame();
      radio1.layoutMode = "HORIZONTAL";
      radio1.counterAxisAlignItems = "CENTER";
      radio1.itemSpacing = 6;
      radio1.fills = [];
      const r1Txt = figma.createText();
      await safeSetText(r1Txt, "○  계속 반복 (종료 기한 없음)", C.textMuted, 11.5, false);
      radio1.appendChild(r1Txt);
      detailBox.appendChild(radio1);

      // 라디오 2: 특정 날짜까지 (선택됨!)
      const radio2 = figma.createFrame();
      radio2.layoutMode = "HORIZONTAL";
      radio2.counterAxisAlignItems = "CENTER";
      radio2.itemSpacing = 8;
      radio2.fills = [];
      setFlexFill(radio2);

      const r2Txt = figma.createText();
      await safeSetText(r2Txt, "●  특정 날짜까지:", C.primaryPurple, 11.5, true);

      const datePill = figma.createFrame();
      datePill.layoutMode = "HORIZONTAL";
      datePill.counterAxisAlignItems = "CENTER";
      datePill.paddingTop = 4; datePill.paddingBottom = 4; datePill.paddingLeft = 8; datePill.paddingRight = 8;
      datePill.cornerRadius = 6;
      datePill.fills = [{ type: 'SOLID', color: C.accentLavender }];
      datePill.strokes = [{ type: 'SOLID', color: C.primaryPurple }];
      datePill.strokeWeight = 1;
      const dpTxt = figma.createText();
      await safeSetText(dpTxt, "2026. 12. 31 (목) 📅", C.primaryPurple, 11.5, true);
      datePill.appendChild(dpTxt);

      radio2.appendChild(r2Txt);
      radio2.appendChild(datePill);
      detailBox.appendChild(radio2);

      // 라디오 3: N회 후 종료
      const radio3 = figma.createFrame();
      radio3.layoutMode = "HORIZONTAL";
      radio3.counterAxisAlignItems = "CENTER";
      radio3.itemSpacing = 6;
      radio3.fills = [];
      const r3Txt = figma.createText();
      await safeSetText(r3Txt, "○  특정 횟수 후 종료 (예: 10회)", C.textMuted, 11.5, false);
      radio3.appendChild(r3Txt);
      detailBox.appendChild(radio3);

      // 3) 최종 완결 배너
      detailBox.appendChild(await createSummaryBanner("🏁", "2026.12.31까지 매주 월, 수, 금 반복"));
    }
    const cta4 = frame4.findOne(n => n.type === "TEXT" && (n.characters.includes("저장") || n.characters.includes("추가")));
    if (cta4) await safeSetText(cta4, "반복 일정 최종 저장", C.pureWhite, 14, true);

    // ==========================================================================
    // 📐 프레임 높이 자동 보정 (콘텐츠가 늘어나도 잘리지 않도록 안전 확보)
    // ==========================================================================
    for (const f of [frame1, frame2, frame3, frame4]) {
      const childForm = f.findOne(n => n.name === "Habit form") || f.findOne(n => n.type === "FRAME" && n.children.length >= 3);
      if (childForm) {
        const requiredH = childForm.y + childForm.height + 70;
        if (requiredH > f.height) {
          f.resize(f.width, requiredH);
        }
      }
    }

    console.log("🎉 [성공] 4개 화면 나란히 생성 완료!");
    figma.notify("🎉 구글 캘린더형 4단계 인터랙션 화면이 피그마에 완벽히 생성되었습니다!", { timeout: 6000 });
    break;
  }
}

generateGoogleCalendarTaskFlowScreens();
