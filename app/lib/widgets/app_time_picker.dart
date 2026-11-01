import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// ⏰ 둥근 아날로그 시계판 대신, 직관적으로 [오전/오후] [시] : [분] 숫자를 직접 치는 디지털 타임피커
class AppTimePicker {
  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initialTime,
    String title = '시간 설정',
  }) async {
    String period = initialTime.period == DayPeriod.am ? '오전' : '오후';
    int hour12 = initialTime.hourOfPeriod == 0 ? 12 : initialTime.hourOfPeriod;
    int minute = initialTime.minute;

    final hourCtrl = TextEditingController(text: hour12.toString());
    final minCtrl = TextEditingController(text: minute.toString().padLeft(2, '0'));

    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

              // [ 시 ] : [ 분 ] 숫자 직접 입력
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: hourCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('시(1~12)와 분(0~59)을 숫자로 입력하세요', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                int h = int.tryParse(hourCtrl.text.trim()) ?? 12;
                int m = int.tryParse(minCtrl.text.trim()) ?? 0;
                h = h.clamp(1, 12);
                m = m.clamp(0, 59);

                int hour24;
                if (period == '오전') {
                  hour24 = (h == 12) ? 0 : h;
                } else {
                  hour24 = (h == 12) ? 12 : h + 12;
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
