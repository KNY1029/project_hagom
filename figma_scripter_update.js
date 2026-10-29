// ==============================================================================
// 🏥 [보건약학프로젝트] Figma Scripter - 5안 전용 생성 스크립트
// ==============================================================================
// 
// 🌟 [5안 특징]:
// 1. 평소에는 깨끗한 흰 바탕에 도톰한 캡슐 바(초록/주황)만 유지 (미니멀 & 깔끔)
// 2. 약을 빼먹은 날(3, 7, 22일)에만 [연분홍 파스텔 틴트 + 코랄 레드 바]가 켜져 시선 집중!
// 3. 등록된 할일이 있는 날(14, 16, 21, 28일)은 우측 상단 라벤더 닷(•) 표시
//
// 📌 실행 방법:
// 1. 피그마에서 [Shift + I] 누르고 Plugins -> 'Scripter' 검색 후 실행(Run)
// 2. Scripter 창에 아래 코드를 그대로 붙여넣기
// 3. 우측 상단 [▶ Run] 또는 [Ctrl + Enter] 누르기
// ==============================================================================

async function createCalendarOption5Only() {
  console.clear();
  console.log("🚀 [보건약학프로젝트] 캘린더 5안 단독 생성 시작...");

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
    } catch (e) {
      try {
        await figma.loadFontAsync({ family: "Inter", style: "Regular" });
        textNode.fontName = { family: "Inter", style: "Regular" };
        textNode.characters = newText;
        if (newColor) textNode.fills = [{ type: 'SOLID', color: newColor }];
      } catch (err) {
        console.warn("텍스트 로드 건너뜀:", err);
      }
    }
  }

  const pages = figma.root.children;
  const fullDoneDays = [1, 6, 8, 9, 12, 16];
  const partialDoneDays = [2, 5, 10, 17];
  const missedDoseDays = [3, 7, 22]; // 🔴 약 미복용일
  const taskScheduledDays = [14, 16, 21, 28]; // 🟣 할일 등록된 날

  let created = false;

  for (const page of pages) {
    // 기준이 될 캘린더 화면 찾기
    const baseCalendar = page.findOne(n => n.name === "Calendar screen" || n.name.includes("Calendar"));
    if (baseCalendar && baseCalendar.type === "FRAME") {
      // 기존 5안 프레임이 있다면 깔끔하게 제거 후 새로 생성
      const prevOpt5 = page.findOne(n => n.name === "Calendar - 5안 (평소 캡슐바 + 약 미복용만 틴트)");
      if (prevOpt5) prevOpt5.remove();

      // 복제하여 5안 생성
      const frame5 = baseCalendar.clone();
      frame5.name = "Calendar - 5안 (평소 캡슐바 + 약 미복용만 틴트)";
      frame5.x = baseCalendar.x + baseCalendar.width + 60;
      frame5.y = baseCalendar.y;

      const days5 = frame5.findAll(n => n.name === "Calendar day");
      for (const day of days5) {
        const dayText = day.findOne(n => n.type === "TEXT");
        const dayNum = dayText ? parseInt(dayText.characters) : 0;
        const statusMarkers = day.findOne(n => n.name === "Status markers");
        const isToday = (dayNum === 14);

        day.cornerRadius = 8;

        // 1) 할일 등록 닷 (우측 상단 5px 라벤더 점)
        const prevDots = day.findAll(n => n.name === "Task Marker Dot");
        for (const pd of prevDots) pd.remove();

        if (taskScheduledDays.includes(dayNum)) {
          const taskDot = figma.createEllipse();
          taskDot.name = "Task Marker Dot";
          taskDot.resize(5, 5);
          taskDot.fills = [{ type: 'SOLID', color: isToday ? { r: 1, g: 1, b: 1 } : { r: 0.48, g: 0.38, b: 0.66 } }];
          day.appendChild(taskDot);
          try {
            taskDot.layoutPositioning = "ABSOLUTE";
            taskDot.x = day.width - 9;
            taskDot.y = 4;
          } catch (e) {
            taskDot.x = day.width - 9;
            taskDot.y = 4;
          }
        }

        // 2) 셀 배경 틴트: 🔴 오직 '약 미복용일(3, 7, 22일)'에만 연분홍 틴트 적용!
        if (isToday) {
          day.fills = [{ type: 'SOLID', color: { r: 0.48, g: 0.38, b: 0.66 } }]; // 오늘: 퍼플
          if (dayText) await safeSetText(dayText, dayText.characters, { r: 1, g: 1, b: 1 });
        } else if (missedDoseDays.includes(dayNum)) {
          day.fills = [{ type: 'SOLID', color: { r: 0.99, g: 0.92, b: 0.92 } }]; // #FEECEC (연분홍 틴트!)
          if (dayText) await safeSetText(dayText, dayText.characters, { r: 0.78, g: 0.16, b: 0.16 }); // 붉은 숫자
        } else {
          day.fills = []; // 평소에는 깨끗한 투명(흰 배경)
          if (dayText) await safeSetText(dayText, dayText.characters, { r: 0.18, g: 0.22, b: 0.28 });
        }

        // 3) 캡슐 바: 평소에 모든 상태를 가로 18px 캡슐 바로 표시
        if (statusMarkers && statusMarkers.type === "FRAME") {
          while (statusMarkers.children.length > 0) {
            statusMarkers.children[0].remove();
          }

          const bar = figma.createRectangle();
          bar.name = "Status Capsule Bar";
          bar.resize(18, 4);
          bar.cornerRadius = 2;

          if (isToday) {
            bar.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
          } else if (missedDoseDays.includes(dayNum)) {
            bar.fills = [{ type: 'SOLID', color: { r: 0.90, g: 0.24, b: 0.24 } }]; // 코랄 레드 바
          } else if (fullDoneDays.includes(dayNum)) {
            bar.fills = [{ type: 'SOLID', color: { r: 0.22, g: 0.63, b: 0.41 } }]; // 초록 바
          } else if (partialDoneDays.includes(dayNum)) {
            bar.fills = [{ type: 'SOLID', color: { r: 0.93, g: 0.54, b: 0.21 } }]; // 주황 바
          } else {
            bar.visible = false;
          }

          statusMarkers.appendChild(bar);
          statusMarkers.layoutMode = "HORIZONTAL";
          statusMarkers.primaryAxisAlignItems = "CENTER";
          statusMarkers.counterAxisAlignItems = "CENTER";
        }
      }

      created = true;
      console.log("🎉 캘린더 5안 단독 생성 완료!");
      figma.notify("👑 캘린더 5안(평소 캡슐바 + 약 미복용만 연분홍 틴트)이 생성되었습니다!", { timeout: 5000 });
      break;
    }
  }

  if (!created) {
    figma.notify("⚠️ 기준이 될 캘린더 화면을 찾지 못했습니다.");
  }
}

createCalendarOption5Only();
