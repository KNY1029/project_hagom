import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../state/app_state_manager.dart';
import '../screens/companion_room_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/widget_simulator_screen.dart';
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
      'badge': '가이드 1/7 · 복약 관리 💊',
      'title': '1. 복약 관리 💊',
      'body':
          '병원에서 약을 처방받았다면, 약 이름과 복용법을 입력하고 의사 처방 필수 약물에 체크해줍니다. (처방약은 중요하기 때문에 알림이 상시 작동합니다.) 그리고 복용 시간을 설정합니다. 시간대 칩은 처음 누를 때 알림 시각을 설정하고, 다음부터는 저장된 시간이 바로 적용됩니다.\n\n처방받은 약이 아닌 의약품이나 영양제의 경우, 체크 표시만 빼고 같은 방법으로 하면 됩니다.\n\n‘지금 복용’을 누르면 현재 시각이 기록되며 ‘완료’로 바뀌고, 상단의 완수율이 올라갑니다. 오늘의 복약을 모두 완료하면 100%가 됩니다.',
      'btnText': '다음 ➔ 습관 관리로 이동',
    },
    {
      'tabIndex': 1,
      'badge': '가이드 2/7 · 습관 관리 🍃',
      'title': '2. 습관 관리 🍃',
      'body':
          '습관 이름, 작은 목표와 하루 목표치를 설정합니다. 실천 주기를 입력하고, 필요하다면 알림 시각도 설정합니다.\n\n습관을 1회 수행할 때마다 상단 완수율이 올라갑니다. 목표 횟수를 모두 채우면 ‘완료’로 바뀝니다.',
      'btnText': '다음 ➔ 기록 달력으로 이동',
    },
    {
      'tabIndex': 2,
      'badge': '가이드 3/7 · 기록 달력 🗓',
      'title': '3. 기록 달력 🗓',
      'body':
          '그동안 생활한 기록을 볼 수 있는 곳입니다. 날짜를 누르면, 해당 날짜의 복약 현황, 습관 현황이 보입니다. 처방받은 약을 미복용한 경우, 붉은색❤️ 하단 바로 표시됩니다. 반면 처방받은 약은 복용했지만 다른 약물이나 습관을 완수하지 않은 경우, 회색🩶 하단 바로 표시됩니다. 모든 것을 완수했다면 초록색💚 하단 바로 표시됩니다.\n\n‘그날의 할 일’은 사용자가 별도로 추가한 일정으로, 보라색💜 점에서 완료 시 초록색💚 점으로 바뀝니다.',
      'btnText': '다음 ➔ 설정 화면 둘러보기',
    },
    {
      'tabIndex': 0,
      'badge': '가이드 4/7 · 설정 ⚙️',
      'title': '4. 설정 ⚙️',
      'body':
          '4-1. 알림 설정⏰️\n우측 상단 톱니바퀴를 누르면, 개인 성향에 따라 맞춤 설정할 수 있습니다.\n알림 반복 빈도부터 각 기능에 대한 알림을 별도로 on/off할 수 있습니다.\n(주의할 점 : 복약 알림을 꺼도 처방된 약 알림은 꺼지지 않습니다.)\n\n4-2. 리포트 다운로드📝\n앱 사용 기록을 엑셀 파일 형태로 다운로드 가능하며, 의료진에게 정보 제공 목적 등으로 활용할 수 있습니다. 어떤 데이터를 추출할지 직접 선택한 뒤, 저장이나 전송이 가능합니다.',
      'btnText': '직접 설정 화면 열어보기',
    },
    {
      'tabIndex': 0,
      'badge': '가이드 5/7 · 하곰이 🐻',
      'title': '5. 하곰이 🐻',
      'body':
          '우측 상단 하곰이가 있습니다. 짧게 누르면 하곰이가 힘이 되는 말을 건네줘요. 길게 누르면 하곰이의 방으로 이어져요.\n\n앱 어디서나 지치고 힘들 때 하곰이를 톡 탭해 보세요!',
      'btnText': '다음 ➔ 하곰이의 방 둘러보기',
    },
    {
      'tabIndex': 0,
      'badge': '가이드 6/7 · 하곰이의 방 🚪',
      'title': '6. 하곰이의 방 🚪',
      'body':
          '하곰이와 하곰이가 해주는 위로와 응원의 말들이 있는 힐링 공간입니다.🌱\n\n누적접속일수를 통해 하곰이와 함께한 시간을 확인할 수 있습니다. 접속하지 않은 날이 있어도 기록은 사라지지 않으니, 계속해서 접속일을 쌓아나가며 하곰이와의 하루를 즐기세요.',
      'btnText': '직접 하곰이의 방 입장하기',
    },
    {
      'tabIndex': 0,
      'badge': '가이드 7/7 · 위젯 📱',
      'title': '7. 위젯 📱',
      'body':
          '복약 관리, 습관 관리, 오늘의 할 일, 기록 달력을 간편하게 볼 수 있습니다. 목록은 시간 순으로 정렬되어 보기 편하게 되어 있습니다. 위젯을 누르면 바로 앱으로 이어져요.\n\n홈 화면에 위젯을 꺼내두면 앱을 켜지 않고도 1-Tap으로 복약과 습관을 손쉽게 체크할 수 있어요!',
      'btnText': '위젯 시뮬레이터 체험 및 가이드 완료',
    },
  ];

  void _nextStep() {
    if (_currentStep == 2) {
      // Step 3 (달력) ➔ Step 4 (설정): 탭을 복약(0)으로 바꾸고 설정 단계 준비
      setState(() {
        _currentStep++;
      });
      widget.onSwitchTab(0);
    } else if (_currentStep == 3) {
      // Step 4: '직접 설정 화면 열어보기'를 누르면 실제 설정 화면으로 이동!
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ).then((_) {
        // 설정 화면 둘러보고 뒤로 돌아왔을 때 Step 5 (하곰이 안내)로 부드럽게 전진!
        if (mounted) {
          setState(() {
            _currentStep = 4;
          });
          widget.onSwitchTab(0);
        }
      });
    } else if (_currentStep == 4) {
      // Step 5 ➔ Step 6 (하곰이의 방 안내)
      setState(() {
        _currentStep++;
      });
      widget.onSwitchTab(0);
    } else if (_currentStep == 5) {
      // Step 6: '직접 하곰이의 방 입장하기' 누르면 실제 하곰이의 방 화면으로 이동!
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CompanionRoomScreen()),
      ).then((_) {
        // 방을 둘러보고 돌아왔을 때 Step 7 (위젯 안내)로 전진!
        if (mounted) {
          setState(() {
            _currentStep = 6;
          });
          widget.onSwitchTab(0);
        }
      });
    } else if (_currentStep == 6) {
      // Step 7: 위젯 시뮬레이터 화면을 열어주어 위젯 작동 모습을 보여주고 완료 다이얼로그 호출!
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const WidgetSimulatorScreen()),
      ).then((_) {
        if (mounted) {
          _finishTutorial();
        }
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
                color: AppColors.primaryPurple.withValues(alpha: 0.18),
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
