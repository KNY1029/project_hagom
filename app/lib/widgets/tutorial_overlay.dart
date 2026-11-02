import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../state/app_state_manager.dart';

/// 🐻 하곰이 온보딩 튜토리얼 오버레이 위젯
/// - 각 탭을 순회하며(복약 ➔ 습관 ➔ 달력 ➔ 방) 기능과 철학을 설명
/// - 튜토리얼 종료 시 복약/할일은 삭제하고 습관은 '대기'로 깨끗이 리셋
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
      'title': '복약 관리 탭',
      'headline': '약 복용을 편안하게 챙겨요',
      'body':
          '• [지금 복용] 버튼을 누르면 예정 시각이 실제 복약 시각으로 자동 전환돼요.\n• 카드를 톡 누르면 [정보 수정]이나 자책 없이 넘기는 [건너뛰기]를 할 수 있어요.\n• 처방 필수약은 알림이 안전하게 항상 유지돼요.',
      'btnText': '다음 (습관 관리 보기)',
    },
    {
      'tabIndex': 1,
      'title': '습관 관리 탭',
      'headline': '작은 시도도 소중한 점수로 인정돼요',
      'body':
          '• 물 마시기, 가벼운 스트레칭처럼 부담 없는 작은 루틴을 관리해요.\n• [대기] ➔ [조금 실천 (0.5점)] ➔ [완료 (1.0점)] 3단계로 유연하게 인정돼요.\n• 하루 4잔 중 1잔만 마셔도 상단 게이지에 정확하게 반영돼요.',
      'btnText': '다음 (기록 달력 보기)',
    },
    {
      'tabIndex': 2,
      'title': '기록 달력 탭',
      'headline': '한눈에 파악하는 3단계 안심 달력',
      'body':
          '• 연초록 파스텔 셀: 복약과 습관을 모두 완료한 날이에요.\n• 빨간 바: 의사의 처방 필수약을 놓친 날을 안전하게 경고해요.\n• 갈색 바: 일반약이나 습관을 덜 한 날을 다정하게 표시해요.\n• 과거 날짜를 눌러 소급 기록해도 하곰이가 똑같이 축하해 드려요.',
      'btnText': '튜토리얼 완료 (내 기록 시작하기)',
    },
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      widget.onSwitchTab(_steps[_currentStep]['tabIndex'] as int);
    } else {
      _finishTutorial();
    }
  }

  void _finishTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          '튜토리얼 완료',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: const Text(
          '수고하셨어요!\n\n이제 실제로 나만의 건강 관리를 시작할 수 있도록, 예시 복약과 할일은 비우고 습관들은 오늘 실천할 수 있게 [대기] 상태로 깨끗하게 준비해 둘게요.',
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
            child: const Text('시작하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      bottom: 24,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryPurple, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.15),
                blurRadius: 16,
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
                      '가이드 ${_currentStep + 1}/${_steps.length} · ${step['title']}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _finishTutorial,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                step['headline'] as String,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                step['body'] as String,
                style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary),
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
