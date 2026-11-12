import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants/hagom_dialogue.dart';
import '../state/app_state_manager.dart';

class HagomAlarmManager {
  static const MethodChannel _channel = MethodChannel(
    'com.healthpharma.hagom_app/export',
  );

  /// 현재 등록된 복약, 습관, 할일 및 모드별 토크 알림을 안드로이드 AlarmManager로 전송
  static Future<void> syncScheduledAlarms(AppStateManager state) async {
    if (kIsWeb) return;

    final List<Map<String, dynamic>> schedules = [];
    int nextId = 1000;

    // 1. 복약 알림 (일반 복약 알림 켜짐이거나 처방약인 경우)
    for (final med in state.medications) {
      final shouldNotify = state.medsNotificationEnabled || med.isPrescription;
      if (!shouldNotify) continue;

      for (int i = 0; i < med.doseSlots.length; i++) {
        final slot = med.doseSlots[i];
        if (slot.isCompleted || slot.isSkipped) continue;
        final timeStr = slot.scheduledTime;
        if (timeStr == null || timeStr.isEmpty) continue;

        final time = _parseKoreanTime(timeStr);
        if (time != null) {
          schedules.add({
            'id': nextId++,
            'hour': time['hour'],
            'minute': time['minute'],
            'title': '하곰이 복약 알림',
            'message': HagomDialogue.getRequiredReminder(
              '${med.name} (${slot.label})',
            ),
            'isEssential': true,
            'repeatDays': _getRepeatDaysList(
              med.recurrenceSummary,
              med.repeatDays,
            ),
          });

          // 적극적 모드: 30분 뒤 재알림 추가 등록!
          if (state.notificationFrequency == '적극적') {
            final repeatMinute = (time['minute']! + 30) % 60;
            final repeatHour = time['hour']! + ((time['minute']! + 30) ~/ 60);
            schedules.add({
              'id': nextId++,
              'hour': repeatHour % 24,
              'minute': repeatMinute,
              'title': '하곰이 복약 재알림',
              'message': '애써 돈 들여서 타온 약, 낭비하지 말자구요^^;',
              'isEssential': true,
            });
          }
        }
      }
    }

    // 2. 습관 알림
    if (state.habitNotificationEnabled) {
      for (final habit in state.habits) {
        if (!habit.isDueToday || habit.score >= 1.0) continue;
        for (final timeStr in habit.scheduledTimes) {
          final time = _parseKoreanTime(timeStr);
          if (time != null) {
            schedules.add({
              'id': nextId++,
              'hour': time['hour'],
              'minute': time['minute'],
              'title': '하곰이 습관 알림',
              'message': HagomDialogue.getRequiredReminder(habit.title),
              'isEssential': true,
              'repeatDays': _getRepeatDaysList(
                habit.recurrenceSummary,
                habit.repeatDays,
              ),
            });
          }
        }
      }
    }

    // 3. 할일 알림: 완료된 할일은 더 이상 알리지 않는다.
    if (state.tasksNotificationEnabled) {
      final now = DateTime.now();
      for (final task in state.tasks) {
        if (task.isCompleted ||
            task.time == null ||
            task.time!.isEmpty ||
            task.reminders.isEmpty)
          continue;
        final time = _parseKoreanTime(task.time!);
        if (time == null) continue;
        for (final reminder in task.reminders) {
          final offset = reminder.contains('정시')
              ? 0
              : (reminder.contains('30분')
                    ? 30
                    : (reminder.contains('1시간')
                          ? 60
                          : (reminder.contains('하루') ? 1440 : 0)));
          final dueDay = DateTime(
            task.date.year,
            task.date.month,
            task.date.day,
          );
          final dueMinutes = time['hour']! * 60 + time['minute']!;
          final alarmDate = dueDay.add(Duration(minutes: dueMinutes - offset));
          if (task.isRepeated && task.repeatCycle == '매일') {
            schedules.add({
              'id': nextId++,
              'hour': alarmDate.hour,
              'minute': alarmDate.minute,
              'title': '하곰이 할 일 알림',
              'message': HagomDialogue.getRequiredReminder(task.title),
              'isEssential': true,
            });
          } else if (alarmDate.isAfter(now)) {
            schedules.add({
              'id': nextId++,
              'triggerAtMillis': alarmDate.millisecondsSinceEpoch,
              'title': '하곰이 할 일 알림',
              'message': HagomDialogue.getRequiredReminder(task.title),
              'isEssential': true,
            });
          }
        }
      }
    }

    // 4. 토크 알림 (기본: 1회, 적극적: 3회)
    if (state.mascotNotificationEnabled) {
      if (state.notificationFrequency == '기본') {
        // 오후 2:30 일상 토크 1회
        schedules.add({
          'id': nextId++,
          'hour': 14,
          'minute': 30,
          'title': '하곰이의 따뜻한 한마디',
          'message': HagomDialogue.getTalkQuoteByFrequency('기본'),
          'isEssential': false,
        });
      } else if (state.notificationFrequency == '적극적') {
        // 오전 11:30, 오후 3:30, 저녁 8:30 스파르타/일상 토크 3회
        schedules.add({
          'id': nextId++,
          'hour': 11,
          'minute': 30,
          'title': '하곰이의 한마디',
          'message': HagomDialogue.getTalkQuoteByFrequency('적극적'),
          'isEssential': false,
        });
        schedules.add({
          'id': nextId++,
          'hour': 15,
          'minute': 30,
          'title': '하곰이의 밀착 케어',
          'message': HagomDialogue.getTalkQuoteByFrequency('적극적'),
          'isEssential': false,
        });
        schedules.add({
          'id': nextId++,
          'hour': 20,
          'minute': 30,
          'title': '하곰이의 스파르타 체크',
          'message': HagomDialogue.getTalkQuoteByFrequency('적극적'),
          'isEssential': false,
        });
      }
    }

    try {
      await _channel.invokeMethod('syncAlarms', {
        'schedulesJson': jsonEncode(schedules),
      });
    } catch (_) {}
  }

  /// 한국어 요일명(['일', '월', ...]) 또는 주기 요약문에서 요일 번호 목록(1=일요일..7=토요일) 추출
  static List<int> _getRepeatDaysList(
    String recurrenceSummary,
    List<String> repeatDays,
  ) {
    final Map<String, int> dayToCalNum = {
      '일': 1,
      '월': 2,
      '화': 3,
      '수': 4,
      '목': 5,
      '금': 6,
      '토': 7,
    };

    if (repeatDays.isNotEmpty) {
      return repeatDays.map((d) => dayToCalNum[d]).whereType<int>().toList();
    }

    if (recurrenceSummary.contains('일요일')) return [1];
    if (recurrenceSummary.contains('월요일')) return [2];
    if (recurrenceSummary.contains('화요일')) return [3];
    if (recurrenceSummary.contains('수요일')) return [4];
    if (recurrenceSummary.contains('목요일')) return [5];
    if (recurrenceSummary.contains('금요일')) return [6];
    if (recurrenceSummary.contains('토요일')) return [7];

    return []; // 비어있으면 매일 울림
  }

  /// '오전 8:30', '오후 7:00' 형태 파싱
  static Map<String, int>? _parseKoreanTime(String str) {
    try {
      final clean = str.trim();
      final isPm = clean.startsWith('오후');
      final timePart = clean.replaceAll('오전', '').replaceAll('오후', '').trim();
      final parts = timePart.split(':');
      if (parts.length != 2) return null;

      var hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());

      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      return {'hour': hour, 'minute': minute};
    } catch (_) {
      return null;
    }
  }
}
