import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../state/app_state_manager.dart';
import '../screens/companion_room_screen.dart';

/// 🎮 [하곰이 실전 인터랙티브 튜토리얼 오버레이]
/// - 직접 버튼을 눌러보고 상태 변화를 눈으로 확인하며 배우는 5단계 체험 가이드!
/// 1. 복약 탭: '지금 복용' 눌러서 실제 복약 시간 전환 체험
/// 2. 복약 탭: 카드 펼쳐서 '정보 수정'과 안심 '건너뛰기' 확인
/// 3. 습관 탭: '물 마시기' 횟수 올려서 상단 게이지 올라가는 것 체감
/// 4. 달력 탭: 3단계 날짜 셀(연초록/빨간바/갈색바)과 소급 기록 확인
/// 5. 하곰이의 방: 마음 편히 쉬어가는 온기 가득한 방 입장 체험
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onFinishTutorial;
  final Function(int) onSwitchTab;

  const TutorialOverlay({
    super.key,
    required this.onFinishTutorial,
    required this.onSwitchTab,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'tabIndex': 0,
      'badge': '체험 1/5 · 복약 탭',
      'title': '직접 [지금 복용] 버튼을 눌러보세요',
      'body':
          '화면에 보이는 약 카드 우측의 [지금 복용]을 탭해 보세요!\n\n예정 시각(오전 8:00)이 방금 복용한 실제 시각으로 바뀌면서 초록색 칩으로 전환되는 것을 확인할 수 있어요.',
      'btnText': '눌러봤어요 ➔ 다음 단계',
    },
    {
      'tabIndex': 0,
      'badge': '체험 2/5 · 복약 탭',
      'title': '약 카드를 톡 눌러서 펼쳐보세요',
      'body':
          '약 카드를 탭하면 아래로 메뉴가 부드럽게 열려요.\n\n시간을 바꾸는 [정보 수정]과, 약을 못 먹었을 때 자책 없이 안전하게 넘길 수 있는 [건너뛰기]를 사용할 수 있어요.',
      'btnText': '확인했어요 ➔ 습관 관리 가기',
    },
    {
      'tabIndex': 1,
      'badge': '체험 3/5 · 습관 탭',
      'title': '물 마시기의 [3/4회] 버튼을 눌러보세요',
      'body':
          '두 번째 탭(습관)으로 이동했어요! 물 마시기 카드의 버튼을 탭해 보세요.\n\n완료 상태로 바뀌면서 상단 게이지가 쑥 차오르는 것을 볼 수 있어요. 조금만 실천해도 점수로 인정해 주는 비처벌적 게이지예요.',
      'btnText': '게이지가 올랐어요 ➔ 달력 보기',
    },
    {
      'tabIndex': 2,
      'badge': '체험 4/5 · 달력 탭',
      'title': '한눈에 들어오는 3단계 안심 달력',
      'body':
          '세 번째 탭(달력)이에요!\n\n• 연초록 파스텔 셀: 약과 습관을 다 한 날\n• 빨간 바: 중요한 처방약을 놓친 날\n• 갈색 바: 일반약이나 습관을 덜 한 날\n과거 날짜를 눌러 소급 체크해도 하곰이가 똑같이 축하해 드려요.',
      'btnText': '이해했어요 ➔ 하곰이의 방 가보기',
    },
    {
      'tabIndex': 0, // 방으로 이동
      'badge': '체험 5/5 · 하곰이의 방',
      'title': '마음 편히 쉬어가는 하곰이의 방',
      'body':
          '상단 우측의 곰돌이 얼굴을 누르면 [하곰이의 방]으로 갈 수 있어요.\n\n아무것도 못 한 날에도 하곰이를 톡톡 건드리면 따뜻한 위로와 격려를 건네줘요. 누적 발걸음 통계도 여기서 확인할 수 있어요.',
      'btnText': '하곰이의 방 둘러보기',
    },
  ];

  void _nextStep() {
    if (_currentStep == 3) {
      // Step 4 ➔ Step 5: 하곰이의 방 안내
      setState(() {
        _currentStep++;
      });
      widget.onSwitchTab(0);
    } else if (_currentStep == 4) {
      // Step 5에서 '하곰이의 방 둘러보기' 누르면 실제 방 화면으로 띄워줌!
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CompanionRoomScreen()),
      ).then((_) {
        // 방을 보고 돌아왔을 때 완료 다이얼로그 발동!
        _finishTutorial();
      });
    } else {
      setState(() {
        _currentStep++;
      });
      widget.onSwitchTab(_steps[_currentStep]['tabIndex'] as int);
    }
  }

  void _finishTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '튜토리얼 완료',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Text(
          '직접 만져보며 모든 기능을 둘러보셨어요!\n\n이제 나만의 복약과 습관을 자유롭게 등록할 수 있도록, 예시 복약과 할일은 비우고 습관들은 [대기] 상태로 깨끗하게 준비해 드릴게요.',
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AppStateManager().finishTutorialCleanSlate();
              widget.onFinishTutorial();
            },
            child: const Text('내 기록 시작하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryPurple, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.lightLavender,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      step['badge'] as String,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _finishTutorial,
                    child: const Text(
                      '튜토리얼 건너뛰기',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                step['title'] as String,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                step['body'] as String,
                style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _nextStep,
                  child: Text(
                    step['btnText'] as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
