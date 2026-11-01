import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

/// 🐻 [하곰이 축하 & 격려 토스트 (PRD 접점 3)]
/// 
/// 복약 완료 또는 습관 완료 시 화면 하단에 앙증맞게 떠서
/// 하곰이 얼굴과 함께 비처벌적 칭찬/축하 멘트를 건네는 스낵바 알림!
/// [actionLabel] 및 [onAction] 전달 시 토스트 안에서 바로 1초 되돌리기 지원!
class CelebrationToast {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 16, left: 14, right: 14),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryPurple.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 하곰이 캐릭터 얼굴
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lightLavender,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppAssets.headerCompanionAvatar,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 응원 타이틀 & 멘트
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('✨', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 🌟 우측 인라인 액션 버튼 (되돌리기 등)
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.warmBrown.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction();
                  },
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: AppColors.warmBrown,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
