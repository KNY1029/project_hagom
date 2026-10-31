import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

/// 🐻 [하곰이 축하 & 격려 토스트 (PRD 접점 3)]
/// 
/// 복약 완료 또는 습관 완료 시 화면 하단에 앙증맞게 떠서
/// 하곰이 얼굴과 함께 비처벌적 칭찬/축하 멘트를 건네는 스낵바 알림!
class CelebrationToast {
  static void show(BuildContext context, {required String title, required String message}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        padding: EdgeInsets.zero,
        duration: const Duration(milliseconds: 2500),
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
            ],
          ),
        ),
      ),
    );
  }
}
