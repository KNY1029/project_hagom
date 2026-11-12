import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// ⏰ 둥근 아날로그 시계판 대신, 직관적으로 [오전/오후] [시] : [분] 숫자를 직접 치는 디지털 타임피커
/// 
/// [기획 및 지침 준수]:
/// - 빈 칸 기본 원칙: 시간 및 분 입력 필드는 사용자가 헷갈리지 않도록 빈칸("")으로 시작합니다.
///   (힌트 텍스트 "시", "분" 제공)
/// - 미입력 기본값: 비워둔 채 [확인]을 누르면 기본값(시간은 12 또는 지정 시간, 분은 0)으로 유연하게 처리.
class AppTimePicker {
  static Future<TimeOfDay?> show(
    BuildContext context, {
    TimeOfDay? initialTime,
    String title = '시간 설정',
    bool showDefaultCheckbox = false,
    bool initialDefault = false,
    ValueChanged<bool>? onDefaultChanged,
  }) async {
    // initialTime이 주어지면 해당 period를 쓰고, 없으면 현재 시각 기준 오전/오후
    final now = TimeOfDay.now();
    final baseTime = initialTime ?? now;
    String period = baseTime.period == DayPeriod.am ? '오전' : '오후';
    bool updateDefault = initialDefault;

    // 🌟 사용자가 기존 시간을 수정하는 경우가 아니면 빈칸("")으로 시작!
    final hourCtrl = TextEditingController(
      text: initialTime != null ? (initialTime.hourOfPeriod == 0 ? '12' : initialTime.hourOfPeriod.toString()) : '',
    );
    final minCtrl = TextEditingController(
      text: initialTime != null ? initialTime.minute.toString().padLeft(2, '0') : '',
    );

    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 오전 / 오후 토글 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('오전'),
                    selected: period == '오전',
                    showCheckmark: false,
                    selectedColor: AppColors.lightLavender,
                    labelStyle: TextStyle(
                      fontWeight: period == '오전' ? FontWeight.bold : FontWeight.normal,
                      color: period == '오전' ? AppColors.primaryPurple : AppColors.textSecondary,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => period = '오전');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('오후'),
                    selected: period == '오후',
                    showCheckmark: false,
                    selectedColor: AppColors.lightLavender,
                    labelStyle: TextStyle(
                      fontWeight: period == '오후' ? FontWeight.bold : FontWeight.normal,
                      color: period == '오후' ? AppColors.primaryPurple : AppColors.textSecondary,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => period = '오후');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // [ 시 ] : [ 분 ] 숫자 직접 입력 (빈 칸 기본!)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 68,
                    child: TextField(
                      controller: hourCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '시',
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  SizedBox(
                    width: 68,
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '분',
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('시(1~12)와 분(0~59)을 숫자로 입력하세요\n(빈칸일 경우 0분으로 자동 지정돼요)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
              ),
              if (showDefaultCheckbox) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: updateDefault,
                  activeColor: AppColors.primaryPurple,
                  onChanged: (value) => setState(
                    () => updateDefault = value ?? false,
                  ),
                  title: const Text(
                    '이 시간대의 기본 시간도 변경',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // 빈 칸일 경우 시간은 12, 분은 0으로 자동 처리
                final hourText = hourCtrl.text.trim();
                final minText = minCtrl.text.trim();

                int h = hourText.isEmpty ? 12 : (int.tryParse(hourText) ?? 12);
                int m = minText.isEmpty ? 0 : (int.tryParse(minText) ?? 0);

                h = h.clamp(1, 12);
                m = m.clamp(0, 59);

                int hour24;
                if (period == '오전') {
                  hour24 = (h == 12) ? 0 : h;
                } else {
                  hour24 = (h == 12) ? 12 : h + 12;
                }
                if (showDefaultCheckbox) {
                  onDefaultChanged?.call(updateDefault);
                }
                Navigator.of(ctx).pop(TimeOfDay(hour: hour24, minute: m));
              },
              child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
