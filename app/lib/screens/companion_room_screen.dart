import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../constants/hagom_dialogue.dart';
import '../state/app_state_manager.dart';

/// 상단 헤더의 하곰이 미니 아바타를 통해 열리는
/// [하곰이 동반자 인터랙션 룸 화면]
/// 
/// - 하곰이를 터치할 때마다 즉시 멘트 변경
/// - 실제 복약/습관 실천 시 올라가는 [소중한 발걸음 성과표] 실시간 연동
class CompanionRoomScreen extends StatefulWidget {
  const CompanionRoomScreen({super.key});

  @override
  State<CompanionRoomScreen> createState() => _CompanionRoomScreenState();
}

class _CompanionRoomScreenState extends State<CompanionRoomScreen> {
  final AppStateManager _state = AppStateManager();

  String _currentQuote = HagomDialogue.roomQuotes.first;

  void _nextQuote() {
    setState(() {
      _currentQuote = HagomDialogue.getRandomRoomQuote(_currentQuote);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '하곰이의 방',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // 캐릭터 컨디션 배지 (Figma 디자인 반영)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightLavender,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('●', style: TextStyle(color: AppColors.successGreen, fontSize: 10)),
                    SizedBox(width: 6),
                    Text(
                      '오늘은 마음 편안한 날',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 하곰이 캐릭터 (탭 인터랙션 지원)
              GestureDetector(
                onTap: _nextQuote,
                child: Column(
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        color: AppColors.lightLavender,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryPurple.withOpacity(0.25),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          AppAssets.companionRoomMascot,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '👆 하곰이를 톡톡 터치해 보세요!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 응원 말풍선 카드 (단어 단위 자동 줄바꿈 & 넉넉한 높이)
              Container(
                constraints: const BoxConstraints(minHeight: 88),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _currentQuote.split('\n').map((paragraph) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: paragraph.split(' ').map((word) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.5),
                            child: Text(
                              word,
                              style: TextStyle(
                                fontSize: _currentQuote.length > 45 ? 13.5 : 15.0,
                                color: AppColors.textPrimary,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),
              // 작은 성과 카드 (AppStateManager 실제 데이터 연동)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '하곰이와 함께한 소중한 발걸음',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('${_state.returnedCount}회', '다시 돌아옴', AppColors.primaryPurple),
                        _buildStatItem('${_state.gentleAttempts}회', '부드럽게 시도', AppColors.warmBrown),
                        _buildStatItem('100%', '나를 위한 마음', AppColors.successGreen),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 돌아가기 버튼
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.primaryPurple),
                label: const Text(
                  '홈으로 돌아가기',
                  style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
