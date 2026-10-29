// ==============================================================================
// 🏥 [보건약학프로젝트] Figma Plugin - 달력 1안~6안 정밀 복원 & 미래 날짜 정비 & 위젯 동기화
// ==============================================================================
//
// 📌 실행 내용:
// 1. [1안~6안 시안별 차별화 스타일 100% 정밀 적용]:
//    - 1안 (파스텔 틴트만) : 완료=연초록 틴트, 부분=연주황 틴트, 누락=연분홍 틴트 (바 없음)
//    - 2안 (캡슐 바만)     : 배경 흰색, 하단에 초록/주황/빨강 도톰한 캡슐 바만 노출
//    - 3안 (틴트 + 바)     : 파스텔 틴트 배경 + 하단 캡슐 바 결합
//    - 4안 (서클 뱃지)     : 날짜 숫자를 동그란 원형 뱃지(초록/주황/빨강)로 감쌈
//    - 5안 (선택적 틴트)   : 평소엔 캡슐 바만, 약 미복용일(3, 7일)만 연분홍 틴트 경고
//    - 6안 (통 + 바 대조)  : 완료한 날은 셀 전체를 '통으로' 연초록 면적 채움(바 숨김), 덜한 날은 주황 캡슐 바로 표시
//
// 2. [미래 날짜(10월 15~31일) 진행도 완벽 초기화]:
//    - 모든 시안 공통: 15~31일 및 9월 padding은 진행도(바/틴트/뱃지) 완전 제거
//    - 16, 21, 28일에만 보라색 할일 닷(Task Marker Dot #7B61A8) 노출
//
// 3. [2x1 중간 위젯 7종 & 마스코트 미니 아바타]
// ==============================================================================

async function runHealthPharmacySync() {
  console.clear();
  console.log("🚀 [보건약학프로젝트] 1안~6안 정밀 스타일링 및 미래 날짜 정비 시작...");

  try {
    // 폰트 로드
    await Promise.all([
      figma.loadFontAsync({ family: "Inter", style: "Regular" }),
      figma.loadFontAsync({ family: "Inter", style: "Medium" }),
      figma.loadFontAsync({ family: "Inter", style: "Bold" })
    ]);

    const page = figma.currentPage;

    // 공통 컬러 팔레트
    const C = {
      // 1안/3안 파스텔 틴트
      greenTint: { r: 0.92, g: 0.97, b: 0.95 },   // #EBF8F2
      greenText: { r: 0.11, g: 0.26, b: 0.20 },   // #1B4332
      orangeTint: { r: 1.0, g: 0.97, b: 0.94 },   // #FFF8F0
      orangeText: { r: 0.75, g: 0.34, b: 0.13 },  // #C05621
      redTint: { r: 1.0, g: 0.93, b: 0.93 },      // #FEECEC
      redText: { r: 0.77, g: 0.19, b: 0.19 },     // #C53030

      // 6안 통 채움
      greenBlock: { r: 0.90, g: 0.97, b: 0.94 },  // #E6F8F0
      greenDarkText: { r: 0.02, g: 0.37, b: 0.27 }, // #065F46

      // 캡슐 바 색상
      greenBar: { r: 0.22, g: 0.63, b: 0.41 },   // #38A169
      orangeBar: { r: 0.93, g: 0.54, b: 0.21 },  // #ED8936 (#F59E0B)
      redBar: { r: 0.90, g: 0.24, b: 0.24 },     // #E53E3E (#EF4444)

      // 서클 뱃지 (4안)
      circleGreen: { r: 0.87, g: 0.97, b: 0.93 }, // #DEF7EC
      circleOrange: { r: 1.0, g: 0.92, b: 0.78 },  // #FEEBC8
      circleRed: { r: 0.99, g: 0.91, b: 0.91 },    // #FDE8E8

      // 오늘 & 기본
      todayPurple: { r: 0.48, g: 0.38, b: 0.66 }, // #7B61A8
      white: { r: 1.0, g: 1.0, b: 1.0 },
      defaultText: { r: 0.18, g: 0.22, b: 0.28 }, // #2D3748
      prevMonthText: { r: 0.72, g: 0.76, b: 0.80 }
    };

    async function createTextNode(text, size, weight = "Regular", color = { r: 0.2, g: 0.2, b: 0.2 }) {
      const t = figma.createText();
      t.fontName = { family: "Inter", style: weight };
      t.characters = text;
      t.fontSize = size;
      t.fills = [{ type: 'SOLID', color: color }];
      return t;
    }

    async function createPill(text, fontSize, textColor, bgColor, isBold = true, radius = 6, padH = 8, padV = 3) {
      const pill = figma.createFrame();
      pill.name = "Pill Badge";
      pill.layoutMode = "HORIZONTAL";
      pill.primaryAxisAlignItems = "CENTER";
      pill.counterAxisAlignItems = "CENTER";
      pill.primaryAxisSizingMode = "AUTO";
      pill.counterAxisSizingMode = "AUTO";
      if ('layoutSizingHorizontal' in pill) {
        pill.layoutSizingHorizontal = 'HUG';
        pill.layoutSizingVertical = 'HUG';
      }
      pill.paddingLeft = padH;
      pill.paddingRight = padH;
      pill.paddingTop = padV;
      pill.paddingBottom = padV;
      pill.cornerRadius = radius;
      pill.fills = [{ type: 'SOLID', color: bgColor }];

      const t = await createTextNode(text, fontSize, isBold ? "Bold" : "Medium", textColor);
      pill.appendChild(t);
      return pill;
    }

    // ============================================================================
    // [PART 1] 주요 화면 헤더 미니 마스코트 버튼 삽입
    // ============================================================================
    const screenConfigs = [
      { screenName: "Meds screen", contentFrameName: "Medication content", tagColor: { r: 0.41, g: 0.30, b: 0.59 }, border: { r: 0.91, g: 0.88, b: 0.96 }, avatarBg: { r: 0.94, g: 0.91, b: 0.98 } },
      { screenName: "Habbits screen", contentFrameName: "Habits content", tagColor: { r: 0.18, g: 0.55, b: 0.35 }, border: { r: 0.88, g: 0.94, b: 0.90 }, avatarBg: { r: 0.91, g: 0.96, b: 0.93 } },
      { screenName: "Calendar screen", contentFrameName: "Calendar content", tagColor: { r: 0.55, g: 0.43, b: 0.39 }, border: { r: 0.94, g: 0.91, b: 0.87 }, avatarBg: { r: 0.95, g: 0.92, b: 0.89 } }
    ];

    for (const cfg of screenConfigs) {
      const screen = page.children.find(n => n.name === cfg.screenName && n.type === "FRAME");
      if (!screen) continue;
      const content = screen.findOne(n => n.name === cfg.contentFrameName && n.type === "FRAME");
      if (!content) continue;
      const header = content.findOne(n => n.name === "Screen header" && n.type === "FRAME");
      if (!header) continue;
      const headerActions = header.findOne(n => n.name === "Header actions" && n.type === "FRAME");
      if (headerActions) {
        const existingAvatar = headerActions.findOne(n => n.name === "Mascot Companion Button");
        if (existingAvatar) existingAvatar.remove();

        const companionBtn = figma.createFrame();
        companionBtn.name = "Mascot Companion Button";
        companionBtn.resize(36, 36);
        companionBtn.cornerRadius = 18;
        companionBtn.fills = [{ type: 'SOLID', color: cfg.avatarBg }];
        companionBtn.strokes = [{ type: 'SOLID', color: cfg.border }];
        companionBtn.strokeWeight = 1.2;
        companionBtn.layoutMode = "HORIZONTAL";
        companionBtn.primaryAxisAlignItems = "CENTER";
        companionBtn.counterAxisAlignItems = "CENTER";
        companionBtn.primaryAxisSizingMode = "FIXED";
        companionBtn.counterAxisSizingMode = "FIXED";

        const face = await createTextNode("•ᴗ•", 13, "Bold", cfg.tagColor);
        companionBtn.appendChild(face);
        headerActions.appendChild(companionBtn);
      }
      const existingBanner = content.findOne(n => n.name === "Mascot Nudge Banner");
      if (existingBanner) existingBanner.remove();
    }

    // ============================================================================
    // [PART 2] 🌟 6안 신규 생성: Calendar - 6안 (완료는 통 + 덜한 날은 바)
    // ============================================================================
    const existing6 = page.children.find(n => n.name.includes("6안") && n.type === "FRAME");
    if (existing6) existing6.remove();

    const refFrame = page.children.find(n => n.name.includes("2안") && n.type === "FRAME") || 
                     page.children.find(n => n.name.includes("5안") && n.type === "FRAME") ||
                     page.children.find(n => n.name.includes("1안") && n.type === "FRAME") ||
                     page.children.find(n => n.name === "Calendar screen" && n.type === "FRAME");

    let frame6 = null;
    if (refFrame) {
      frame6 = refFrame.clone();
      frame6.name = "Calendar - 6안 (완료는 통 + 덜한 날은 바)";
      frame6.x = 2874;
      frame6.y = 910;
    }

    // ============================================================================
    // [PART 3] 1안부터 6안 + 메인화면까지 각 시안별 고유 스타일 100% 정밀 적용
    // ============================================================================
    const calFrames = page.children.filter(n => 
      (n.name.includes("Calendar") || n.name.includes("달력")) && 
      n.type === "FRAME" && 
      n.width >= 360
    );

    // 시안 타입 판별 함수
    function getOptionType(name) {
      if (name.includes("1안")) return "OPT1"; // 파스텔 틴트만
      if (name.includes("2안")) return "OPT2"; // 캡슐 바만
      if (name.includes("3안")) return "OPT3"; // 파스텔 틴트 + 캡슐 바 결합
      if (name.includes("4안")) return "OPT4"; // 날짜 서클 뱃지
      if (name.includes("5안")) return "OPT5"; // 평소 바 + 약 미복용만 연분홍 틴트
      if (name.includes("6안")) return "OPT6"; // 완료는 통(면적) + 덜한 날은 바
      return "MAIN"; // 메인 화면: 6안 표준 적용
    }

    // 날짜 상태 판별
    function getDayState(dayNum) {
      if ([1, 6, 8, 9, 12, 13].includes(dayNum)) return "COMPLETED"; // 완료 (100%)
      if ([2, 5, 10].includes(dayNum)) return "PARTIAL";             // 덜한 날 (부분 달성)
      if ([3, 7].includes(dayNum)) return "MISSED";                 // 약 미복용 (0%)
      if (dayNum === 14) return "TODAY";                            // 오늘
      if ([16, 21, 28].includes(dayNum)) return "FUTURE_TASK";      // 미래 할일 있는 날
      if (dayNum > 14) return "FUTURE_PLAIN";                       // 미래 일반 날
      return "PLAIN_PAST";                                          // 4, 11일 등
    }

    for (const calFrame of calFrames) {
      const optType = getOptionType(calFrame.name);
      const calendar = calFrame.findOne(n => n.name === "Calendar" && n.type === "FRAME");
      if (!calendar) continue;

      const weeks = calendar.findAll(n => n.name === "Week" && n.type === "FRAME");
      let inOctober = false;
      let seenOctober = false;

      for (const week of weeks) {
        const days = week.findAll(n => (n.name === "Calendar day" || n.name.includes("day")) && n.type === "FRAME");
        for (const dayFrame of days) {
          const textNode = dayFrame.findOne(n => n.type === "TEXT");
          const statusMarkers = dayFrame.findOne(n => (n.name.includes("Status") || n.name.includes("marker")) && n.type === "FRAME");

          if (!textNode) {
            dayFrame.fills = [];
            dayFrame.strokes = [];
            if (statusMarkers) for (const c of statusMarkers.children) c.visible = false;
            continue;
          }

          const dayNum = parseInt(textNode.characters.trim(), 10);
          if (isNaN(dayNum)) {
            dayFrame.fills = [];
            dayFrame.strokes = [];
            if (statusMarkers) for (const c of statusMarkers.children) c.visible = false;
            continue;
          }

          // 10월 진입 및 종료 추적 (9월 27~30일 -> 10월 1일 진입)
          if (dayNum === 1 && !seenOctober) {
            inOctober = true;
            seenOctober = true;
          } else if (dayNum === 1 && inOctober) {
            inOctober = false; // 11월 1일 진입
          }

          const isPrevMonth = !inOctober && !seenOctober;
          const state = isPrevMonth ? "PREV_MONTH" : (!inOctober ? "FUTURE_PLAIN" : getDayState(dayNum));

          // 바(Rectangle) 확인 및 확보
          let bar = statusMarkers ? statusMarkers.findOne(n => n.name.includes("Bar") || n.type === "RECTANGLE") : null;
          function ensureBar() {
            if (!bar && statusMarkers) {
              bar = figma.createRectangle();
              bar.name = "Status Capsule Bar";
              bar.resize(16, 4);
              bar.cornerRadius = 2;
              statusMarkers.appendChild(bar);
            }
            if (bar) {
              bar.visible = true;
              bar.resize(16, 4);
              bar.cornerRadius = 2;
            }
            return bar;
          }

          function hideBar() {
            if (bar) bar.visible = false;
            if (statusMarkers) {
              for (const c of statusMarkers.children) {
                if (c.type === "RECTANGLE") c.visible = false;
              }
            }
          }

          function setTaskDot(show) {
            let taskDot = dayFrame.findOne(n => n.name.includes("Task") && (n.type === "ELLIPSE" || n.name.includes("Dot")));
            if (show) {
              if (!taskDot) {
                taskDot = figma.createEllipse();
                taskDot.name = "Task Marker Dot";
                taskDot.resize(5, 5);
                dayFrame.appendChild(taskDot);
              }
              taskDot.fills = [{ type: 'SOLID', color: C.todayPurple }];
              taskDot.visible = true;
              taskDot.x = dayFrame.width - 9;
              taskDot.y = 4;
            } else {
              if (taskDot) taskDot.visible = false;
            }
          }

          // ----------------------------------------------------------------------
          // [상태별 스타일 분기]
          // ----------------------------------------------------------------------
          if (state === "PREV_MONTH") {
            // 9월 날짜 (27~30일)
            dayFrame.fills = [];
            dayFrame.strokes = [];
            textNode.fills = [{ type: 'SOLID', color: C.prevMonthText }];
            hideBar();
            setTaskDot(false);
          }
          else if (state === "FUTURE_PLAIN") {
            // 미래 날짜 (15, 17, 18, 19, 20, 22, 23, 24, 25, 26, 27, 29, 30, 31일): 진행도 100% 제거
            dayFrame.fills = [];
            dayFrame.strokes = [];
            textNode.fills = [{ type: 'SOLID', color: C.defaultText }];
            hideBar();
            setTaskDot(false);
          }
          else if (state === "FUTURE_TASK") {
            // 미래 할일 날짜 (16, 21, 28일): 진행도 없이 오직 보라색 할일 닷(•)만 노출
            dayFrame.fills = [];
            dayFrame.strokes = [];
            textNode.fills = [{ type: 'SOLID', color: C.defaultText }];
            hideBar();
            setTaskDot(true);
          }
          else if (state === "TODAY") {
            // 오늘 (10월 14일 수요일): 보라색 서클 하이라이트 + 흰색 텍스트
            dayFrame.fills = [{ type: 'SOLID', color: C.todayPurple }];
            dayFrame.cornerRadius = 10;
            dayFrame.strokes = [];
            textNode.fills = [{ type: 'SOLID', color: C.white }];
            hideBar();
            setTaskDot(false);
          }
          else if (state === "PLAIN_PAST") {
            // 과거 휴식/기타일 (4, 11일)
            dayFrame.fills = [];
            dayFrame.strokes = [];
            textNode.fills = [{ type: 'SOLID', color: C.defaultText }];
            hideBar();
            setTaskDot(false);
          }
          else if (state === "COMPLETED") {
            // 🌟 과거 완료한 날 (1, 6, 8, 9, 12, 13일)
            setTaskDot(false);

            if (optType === "OPT1") {
              // 1안: 파스텔 틴트만 (바 없음)
              dayFrame.fills = [{ type: 'SOLID', color: C.greenTint }];
              dayFrame.cornerRadius = 8;
              textNode.fills = [{ type: 'SOLID', color: C.greenText }];
              hideBar();
            } else if (optType === "OPT2") {
              // 2안: 캡슐 바만 (배경 깨끗)
              dayFrame.fills = [];
              textNode.fills = [{ type: 'SOLID', color: C.defaultText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.greenBar }];
            } else if (optType === "OPT3") {
              // 3안: 파스텔 틴트 + 캡슐 바 결합
              dayFrame.fills = [{ type: 'SOLID', color: C.greenTint }];
              dayFrame.cornerRadius = 8;
              textNode.fills = [{ type: 'SOLID', color: C.greenText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.greenBar }];
            } else if (optType === "OPT4") {
              // 4안: 날짜 서클 뱃지
              dayFrame.fills = [{ type: 'SOLID', color: C.circleGreen }];
              dayFrame.cornerRadius = 18;
              textNode.fills = [{ type: 'SOLID', color: C.greenText }];
              hideBar();
            } else if (optType === "OPT5") {
              // 5안: 평소 캡슐 바 (배경 깨끗)
              dayFrame.fills = [];
              textNode.fills = [{ type: 'SOLID', color: C.defaultText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.greenBar }];
            } else {
              // 6안 & MAIN: 🌟 완료한 날은 셀 전체를 '통으로' 연초록 면적 채움 (바 숨김!)
              dayFrame.fills = [{ type: 'SOLID', color: C.greenBlock }];
              dayFrame.cornerRadius = 8;
              textNode.fills = [{ type: 'SOLID', color: C.greenDarkText }];
              hideBar();
            }
          }
          else if (state === "PARTIAL") {
            // 🌟 과거 덜한 날 / 부분 완료 (2, 5, 10일)
            setTaskDot(false);

            if (optType === "OPT1") {
              // 1안: 연주황 파스텔 틴트만
              dayFrame.fills = [{ type: 'SOLID', color: C.orangeTint }];
              dayFrame.cornerRadius = 8;
              textNode.fills = [{ type: 'SOLID', color: C.orangeText }];
              hideBar();
            } else if (optType === "OPT2") {
              // 2안: 주황 캡슐 바만
              dayFrame.fills = [];
              textNode.fills = [{ type: 'SOLID', color: C.defaultText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.orangeBar }];
            } else if (optType === "OPT3") {
              // 3안: 연주황 틴트 + 주황 바
              dayFrame.fills = [{ type: 'SOLID', color: C.orangeTint }];
              dayFrame.cornerRadius = 8;
              textNode.fills = [{ type: 'SOLID', color: C.orangeText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.orangeBar }];
            } else if (optType === "OPT4") {
              // 4안: 주황 서클 뱃지
              dayFrame.fills = [{ type: 'SOLID', color: C.circleOrange }];
              dayFrame.cornerRadius = 18;
              textNode.fills = [{ type: 'SOLID', color: C.orangeText }];
              hideBar();
            } else if (optType === "OPT5") {
              // 5안: 주황 캡슐 바 (배경 깨끗)
              dayFrame.fills = [];
              textNode.fills = [{ type: 'SOLID', color: C.defaultText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.orangeBar }];
            } else {
              // 6안 & MAIN: 🌟 덜한 날은 배경 깨끗하고 하단에 주황 캡슐 바 노출!
              dayFrame.fills = [];
              textNode.fills = [{ type: 'SOLID', color: C.defaultText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.orangeBar }];
            }
          }
          else if (state === "MISSED") {
            // 🌟 과거 약 미복용일 (3, 7일)
            setTaskDot(false);

            if (optType === "OPT1") {
              // 1안: 연분홍 틴트만
              dayFrame.fills = [{ type: 'SOLID', color: C.redTint }];
              dayFrame.cornerRadius = 8;
              textNode.fills = [{ type: 'SOLID', color: C.redText }];
              hideBar();
            } else if (optType === "OPT2") {
              // 2안: 빨강 캡슐 바만
              dayFrame.fills = [];
              textNode.fills = [{ type: 'SOLID', color: C.redText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.redBar }];
            } else if (optType === "OPT3") {
              // 3안: 연분홍 틴트 + 빨강 바
              dayFrame.fills = [{ type: 'SOLID', color: C.redTint }];
              dayFrame.cornerRadius = 8;
              textNode.fills = [{ type: 'SOLID', color: C.redText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.redBar }];
            } else if (optType === "OPT4") {
              // 4안: 빨강 서클 뱃지
              dayFrame.fills = [{ type: 'SOLID', color: C.circleRed }];
              dayFrame.cornerRadius = 18;
              textNode.fills = [{ type: 'SOLID', color: C.redText }];
              hideBar();
            } else if (optType === "OPT5") {
              // 5안: 선택적 경고 (연분홍 틴트 + 빨간 바)
              dayFrame.fills = [{ type: 'SOLID', color: C.redTint }];
              dayFrame.cornerRadius = 8;
              textNode.fills = [{ type: 'SOLID', color: C.redText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.redBar }];
            } else {
              // 6안 & MAIN: 배경 깨끗 + 빨간 캡슐 바 + 빨간 글씨
              dayFrame.fills = [];
              textNode.fills = [{ type: 'SOLID', color: C.redText }];
              const b = ensureBar();
              if (b) b.fills = [{ type: 'SOLID', color: C.redBar }];
            }
          }
        }
      }
    }

    // ============================================================================
    // [PART 4] 2x1 중간 위젯 7종 세트 (338x158 dp 엄수)
    // ============================================================================
    const prevWidgets = page.children.filter(n => n.name.startsWith("위젯 2x1 -"));
    for (const pw of prevWidgets) pw.remove();

    const refWidget = page.children.find(n => n.name === "중간 오늘 위젯");
    const startX = refWidget ? refWidget.x : -1600;
    const startY = refWidget ? refWidget.y + 250 : -800;

    function createBaseWidget(name, bgFill, strokeColor = null) {
      const w = figma.createFrame();
      w.name = name;
      w.layoutMode = "HORIZONTAL";
      w.primaryAxisAlignItems = "SPACE_BETWEEN";
      w.counterAxisAlignItems = "CENTER";
      w.resize(338, 158);
      w.primaryAxisSizingMode = "FIXED";
      w.counterAxisSizingMode = "FIXED";
      if ('layoutSizingHorizontal' in w) {
        w.layoutSizingHorizontal = 'FIXED';
        w.layoutSizingVertical = 'FIXED';
      }
      w.paddingLeft = 18;
      w.paddingRight = 18;
      w.paddingTop = 16;
      w.paddingBottom = 16;
      w.cornerRadius = 24;
      w.fills = [{ type: 'SOLID', color: bgFill }];
      if (strokeColor) {
        w.strokes = [{ type: 'SOLID', color: strokeColor }];
        w.strokeWeight = 1.2;
      }
      return w;
    }

    // 1. 도파민 연속 달성 (Streak) 위젯
    const w1 = createBaseWidget("위젯 2x1 - 도파민 연속 달성", { r: 0.99, g: 0.97, b: 0.93 }, { r: 0.97, g: 0.89, b: 0.76 });
    const w1Left = figma.createFrame();
    w1Left.name = "Left Info";
    w1Left.layoutMode = "VERTICAL";
    w1Left.itemSpacing = 6;
    w1Left.fills = [];
    w1Left.appendChild(await createPill("🔥 복약 & 습관 연속 달성", 10, { r: 0.85, g: 0.40, b: 0.05 }, { r: 1.0, g: 0.93, b: 0.82 }, true, 6, 8, 3));
    w1Left.appendChild(await createTextNode("벌써 5일째 완벽해요!", 17, "Bold", { r: 0.15, g: 0.15, b: 0.18 }));
    w1Left.appendChild(await createTextNode("약효 유지율 100% 달성 중 ✨", 12, "Regular", { r: 0.45, g: 0.45, b: 0.50 }));
    w1.appendChild(w1Left);

    const w1Right = figma.createFrame();
    w1Right.name = "Right Mascot";
    w1Right.layoutMode = "VERTICAL";
    w1Right.primaryAxisAlignItems = "CENTER";
    w1Right.counterAxisAlignItems = "CENTER";
    w1Right.resize(80, 80);
    w1Right.cornerRadius = 40;
    w1Right.fills = [{ type: 'SOLID', color: { r: 1.0, g: 0.93, b: 0.82 } }];
    w1Right.appendChild(await createTextNode("٩(ˊᗜˋ*)و", 18, "Bold", { r: 0.85, g: 0.40, b: 0.05 }));
    w1.appendChild(w1Right);

    // 2. 마스코트 격려 (Mascot Cheer) 위젯
    const w2 = createBaseWidget("위젯 2x1 - 마스코트 격려", { r: 0.96, g: 0.97, b: 1.0 }, { r: 0.88, g: 0.90, b: 0.98 });
    const w2Left = figma.createFrame();
    w2Left.name = "Left Info";
    w2Left.layoutMode = "VERTICAL";
    w2Left.itemSpacing = 6;
    w2Left.fills = [];
    w2Left.appendChild(await createPill("💬 오늘의 응원 한마디", 10, { r: 0.35, g: 0.40, b: 0.85 }, { r: 0.90, g: 0.93, b: 1.0 }, true, 6, 8, 3));
    w2Left.appendChild(await createTextNode("오늘도 한 걸음씩!", 17, "Bold", { r: 0.15, g: 0.15, b: 0.18 }));
    w2Left.appendChild(await createTextNode("점심 약 잘 챙겨 먹었지?\n남은 하루도 파이팅이야 🌱", 12, "Regular", { r: 0.40, g: 0.42, b: 0.50 }));
    w2.appendChild(w2Left);

    const w2Right = figma.createFrame();
    w2Right.name = "Right Mascot";
    w2Right.layoutMode = "VERTICAL";
    w2Right.primaryAxisAlignItems = "CENTER";
    w2Right.counterAxisAlignItems = "CENTER";
    w2Right.resize(80, 80);
    w2Right.cornerRadius = 40;
    w2Right.fills = [{ type: 'SOLID', color: { r: 0.90, g: 0.93, b: 1.0 } }];
    w2Right.appendChild(await createTextNode("( •ᴗ• )੭", 18, "Bold", { r: 0.35, g: 0.40, b: 0.85 }));
    w2.appendChild(w2Right);

    // 3. 다음 약 카운트다운 (Next Med) 위젯
    const w3 = createBaseWidget("위젯 2x1 - 다음 약 카운트다운", { r: 0.98, g: 0.96, b: 1.0 }, { r: 0.91, g: 0.86, b: 0.98 });
    const w3Left = figma.createFrame();
    w3Left.name = "Left Info";
    w3Left.layoutMode = "VERTICAL";
    w3Left.itemSpacing = 5;
    w3Left.fills = [];
    w3Left.appendChild(await createPill("⏰ 다음 복약까지", 10, { r: 0.52, g: 0.28, b: 0.85 }, { r: 0.94, g: 0.90, b: 1.0 }, true, 6, 8, 3));
    w3Left.appendChild(await createTextNode("2시간 15분 남음", 18, "Bold", { r: 0.15, g: 0.15, b: 0.18 }));
    w3Left.appendChild(await createTextNode("오후 7:00 • 소염진통제 1정", 12, "Regular", { r: 0.45, g: 0.42, b: 0.52 }));
    w3.appendChild(w3Left);

    const w3Right = figma.createFrame();
    w3Right.name = "Right Pill Card";
    w3Right.layoutMode = "VERTICAL";
    w3Right.primaryAxisAlignItems = "CENTER";
    w3Right.counterAxisAlignItems = "CENTER";
    w3Right.itemSpacing = 4;
    w3Right.resize(80, 80);
    w3Right.cornerRadius = 20;
    w3Right.fills = [{ type: 'SOLID', color: { r: 0.94, g: 0.90, b: 1.0 } }];
    w3Right.appendChild(await createTextNode("💊", 22, "Regular"));
    w3Right.appendChild(await createTextNode("식후 30분", 10, "Bold", { r: 0.52, g: 0.28, b: 0.85 }));
    w3.appendChild(w3Right);

    // 4. 주간 복약 요약 (Weekly Summary) 위젯
    const w4 = createBaseWidget("위젯 2x1 - 주간 복약 요약", { r: 0.96, g: 0.98, b: 0.97 }, { r: 0.87, g: 0.94, b: 0.90 });
    const w4Left = figma.createFrame();
    w4Left.name = "Left Info";
    w4Left.layoutMode = "VERTICAL";
    w4Left.itemSpacing = 5;
    w4Left.fills = [];
    w4Left.appendChild(await createPill("📊 이번 주 복약 성적", 10, { r: 0.15, g: 0.55, b: 0.35 }, { r: 0.89, g: 0.96, b: 0.92 }, true, 6, 8, 3));
    w4Left.appendChild(await createTextNode("주간 달성률 92%", 18, "Bold", { r: 0.15, g: 0.15, b: 0.18 }));
    w4Left.appendChild(await createTextNode("총 14회 중 13회 완료! 아주 우수해요", 11, "Regular", { r: 0.40, g: 0.48, b: 0.43 }));
    w4.appendChild(w4Left);

    const w4Right = figma.createFrame();
    w4Right.name = "Right Mini Chart";
    w4Right.layoutMode = "VERTICAL";
    w4Right.primaryAxisAlignItems = "CENTER";
    w4Right.counterAxisAlignItems = "CENTER";
    w4Right.resize(80, 80);
    w4Right.cornerRadius = 40;
    w4Right.fills = [{ type: 'SOLID', color: { r: 0.89, g: 0.96, b: 0.92 } }];
    w4Right.appendChild(await createTextNode("13/14", 16, "Bold", { r: 0.15, g: 0.55, b: 0.35 }));
    w4Right.appendChild(await createTextNode("회 완료", 10, "Medium", { r: 0.25, g: 0.60, b: 0.40 }));
    w4.appendChild(w4Right);

    // 5. 오늘의 약 원탭 복약 (One-tap Med Check)
    const w5 = createBaseWidget("위젯 2x1 - 오늘의 약 원탭 복약", { r: 1.0, g: 1.0, b: 1.0 }, { r: 0.88, g: 0.89, b: 0.92 });
    const w5Left = figma.createFrame();
    w5Left.name = "Left Info";
    w5Left.layoutMode = "VERTICAL";
    w5Left.itemSpacing = 5;
    w5Left.fills = [];
    w5Left.appendChild(await createPill("💊 지금 복용할 약", 10, { r: 0.48, g: 0.38, b: 0.66 }, { r: 0.95, g: 0.92, b: 0.98 }, true, 6, 8, 3));
    w5Left.appendChild(await createTextNode("혈압약 & 비타민D", 17, "Bold", { r: 0.15, g: 0.15, b: 0.18 }));
    w5Left.appendChild(await createTextNode("오후 1:00 • 점심 식후 1정", 12, "Regular", { r: 0.45, g: 0.45, b: 0.50 }));
    w5.appendChild(w5Left);

    const w5Btn = figma.createFrame();
    w5Btn.name = "Confirm Check Button";
    w5Btn.layoutMode = "HORIZONTAL";
    w5Btn.primaryAxisAlignItems = "CENTER";
    w5Btn.counterAxisAlignItems = "CENTER";
    w5Btn.resize(88, 48);
    w5Btn.cornerRadius = 24;
    w5Btn.fills = [{ type: 'SOLID', color: { r: 0.48, g: 0.38, b: 0.66 } }];
    w5Btn.appendChild(await createTextNode("복용 완료 ✓", 12, "Bold", { r: 1.0, g: 1.0, b: 1.0 }));
    w5.appendChild(w5Btn);

    // 6. 습관 퀵 체크 (Quick Habit Check)
    const w6 = createBaseWidget("위젯 2x1 - 습관 퀵 체크", { r: 1.0, g: 1.0, b: 1.0 }, { r: 0.88, g: 0.92, b: 0.89 });
    const w6Left = figma.createFrame();
    w6Left.name = "Left Info";
    w6Left.layoutMode = "VERTICAL";
    w6Left.itemSpacing = 5;
    w6Left.fills = [];
    w6Left.appendChild(await createPill("🌱 데일리 습관", 10, { r: 0.18, g: 0.55, b: 0.35 }, { r: 0.91, g: 0.96, b: 0.93 }, true, 6, 8, 3));
    w6Left.appendChild(await createTextNode("물 500ml 마시기", 17, "Bold", { r: 0.15, g: 0.15, b: 0.18 }));
    w6Left.appendChild(await createTextNode("오늘 3/4잔 완료 (75%)", 12, "Regular", { r: 0.42, g: 0.48, b: 0.44 }));
    w6.appendChild(w6Left);

    const w6Btn = figma.createFrame();
    w6Btn.name = "Confirm Check Button";
    w6Btn.layoutMode = "HORIZONTAL";
    w6Btn.primaryAxisAlignItems = "CENTER";
    w6Btn.counterAxisAlignItems = "CENTER";
    w6Btn.resize(88, 48);
    w6Btn.cornerRadius = 24;
    w6Btn.fills = [{ type: 'SOLID', color: { r: 0.18, g: 0.55, b: 0.35 } }];
    w6Btn.appendChild(await createTextNode("한 잔 체크 ✓", 12, "Bold", { r: 1.0, g: 1.0, b: 1.0 }));
    w6.appendChild(w6Btn);

    // 7. 다음 일정 & 할일 (Next Schedule & Task)
    const w7 = createBaseWidget("위젯 2x1 - 다음 일정 및 할일", { r: 1.0, g: 1.0, b: 1.0 }, { r: 0.90, g: 0.90, b: 0.93 });
    const w7Left = figma.createFrame();
    w7Left.name = "Left Info";
    w7Left.layoutMode = "VERTICAL";
    w7Left.itemSpacing = 5;
    w7Left.fills = [];
    w7Left.appendChild(await createPill("📅 예정된 할일", 10, { r: 0.30, g: 0.45, b: 0.70 }, { r: 0.92, g: 0.94, b: 0.98 }, true, 6, 8, 3));
    w7Left.appendChild(await createTextNode("내과 정기 검진", 17, "Bold", { r: 0.15, g: 0.15, b: 0.18 }));
    w7Left.appendChild(await createTextNode("10월 16일 (금) 오전 10:30", 12, "Regular", { r: 0.45, g: 0.45, b: 0.50 }));
    w7.appendChild(w7Left);

    const w7Btn = figma.createFrame();
    w7Btn.name = "Confirm Check Button";
    w7Btn.layoutMode = "HORIZONTAL";
    w7Btn.primaryAxisAlignItems = "CENTER";
    w7Btn.counterAxisAlignItems = "CENTER";
    w7Btn.resize(88, 48);
    w7Btn.cornerRadius = 24;
    w7Btn.fills = [{ type: 'SOLID', color: { r: 0.30, g: 0.45, b: 0.70 } }];
    w7Btn.appendChild(await createTextNode("확인 완료 ✓", 12, "Bold", { r: 1.0, g: 1.0, b: 1.0 }));
    w7.appendChild(w7Btn);

    // 위젯 배치
    const widgets = [w1, w2, w3, w4, w5, w6, w7];
    widgets.forEach((w, idx) => {
      const col = idx % 2;
      const row = Math.floor(idx / 2);
      w.x = startX + col * (338 + 24);
      w.y = startY + row * (158 + 20);
      page.appendChild(w);
    });

    // 🌟 1안~6안 전체 비교 그리드를 한 화면에 조망할 수 있도록 줌인
    const targetFrames = calFrames.filter(n => n.name.includes("안"));
    if (targetFrames.length > 0) {
      figma.viewport.scrollAndZoomIntoView(targetFrames);
      if (frame6) figma.currentPage.selection = [frame6];
    }

    figma.notify("🎉 1안~6안 시안별 차별화 스타일 복원 및 6안 정밀 적용 완료!", { timeout: 3500 });
    console.log("🎉 [보건약학프로젝트] 전체 시안 동기화 완료!");
  } catch (err) {
    console.error("❌ 플러그인 실행 중 오류 발생:", err);
    figma.notify("❌ 실행 중 오류: " + (err.message || err), { error: true });
  } finally {
    figma.closePlugin();
  }
}

runHealthPharmacySync();
