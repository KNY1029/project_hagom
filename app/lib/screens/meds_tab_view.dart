import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/medication_item.dart';
import '../state/app_state_manager.dart';
import '../constants/hagom_dialogue.dart';
import '../constants/app_assets.dart';
import '../widgets/celebration_toast.dart';
import '../widgets/app_time_picker.dart';
import '../widgets/hagom_celebration_overlay.dart';

///
/// 1. 한눈에 쏙 들어오는 2단계 마법사 UX:
///    - 1단계 (기본 정보): 약 이름 + 용량/복용법 + 처방 여부
///    - 2단계 (일정 및 시간): 복용 주기 + 시간대 칩 + 기간
///    ➔ 스크롤이 전혀 생기지 않고 화면에 시원하게 한눈에 들어옴!
/// 2. 지저분한 괄호 예시 제거:
///    - 라벨에 붙어있던 (예: Focusin...), (예: 10mg...) 등을 싹 지우고 단정하고 깨끗한 힌트로 정돈
class MedsTabView extends StatefulWidget {
  const MedsTabView({super.key});

  @override
  State<MedsTabView> createState() => _MedsTabViewState();
}

class _MedsTabViewState extends State<MedsTabView> {
  final AppStateManager _state = AppStateManager();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  // 약 추가 또는 정보 수정 모달 (2단계 스텝 구조)
  void _showMedEditModal({MedicationItem? med}) {
    final isEditing = med != null;
    int currentStep = 1; // 1: 기본 정보, 2: 복용 일정

    final nameCtrl = TextEditingController(text: isEditing ? med.name : '');
    final dosageCtrl = TextEditingController(text: isEditing ? med.dosage : '');
    final memoCtrl = TextEditingController(
      text: isEditing ? (med.memo ?? '') : '',
    );
    String recurrenceType = '매일';
    if (isEditing) {
      final summary = med.recurrenceSummary;
      if (summary.contains('시간')) {
        recurrenceType = '시간 간격';
      } else if (summary.contains('간격')) {
        recurrenceType = '며칠 간격';
      } else if (summary.contains('요일') || summary.startsWith('매주')) {
        recurrenceType = '특정 요일';
      } else if (summary == '오늘만') {
        recurrenceType = '오늘만';
      } else if (summary == '필요 시') {
        recurrenceType = '필요 시';
      } else {
        recurrenceType = '매일';
      }
    }
    final intervalCtrl = TextEditingController(
      text: isEditing && med.recurrenceSummary.contains('일 간격')
          ? med.recurrenceSummary.replaceAll(RegExp(r'[^0-9]'), '')
          : '',
    );
    final hourIntervalCtrl = TextEditingController(
      text: isEditing && med.recurrenceSummary.contains('시간')
          ? (RegExp(r'(\d+)시간').firstMatch(med.recurrenceSummary)?.group(1) ??
                '')
          : '',
    );
    final minIntervalCtrl = TextEditingController(
      text: isEditing && med.recurrenceSummary.contains('분')
          ? (RegExp(r'(\d+)분').firstMatch(med.recurrenceSummary)?.group(1) ??
                '')
          : '',
    );

    final existingAsNeededHistory = isEditing && med.recurrenceSummary == '필요 시'
        ? med.doseSlots
              .where((s) => s.isCompleted || s.isSkipped)
              .map(
                (s) => DoseSlot(
                  label: s.label,
                  scheduledTime: s.scheduledTime,
                  isCompleted: s.isCompleted,
                  isSkipped: s.isSkipped,
                  takenTime: s.takenTime,
                  takenDate: s.takenDate,
                ),
              )
              .toList()
        : <DoseSlot>[];

    List<DoseSlot> currentSlots = isEditing && med.recurrenceSummary != '필요 시'
        ? med.doseSlots
              .map(
                (s) => DoseSlot(
                  label: s.label,
                  scheduledTime: s.scheduledTime,
                  isCompleted: s.isCompleted,
                  isSkipped: s.isSkipped,
                  takenTime: s.takenTime,
                  takenDate: s.takenDate,
                ),
              )
              .toList()
        : [];

    bool isOngoing = isEditing ? (med.durationSummary == '계속 복용') : true;
    final durationDaysCtrl = TextEditingController(
      text: isEditing && med.durationSummary.contains('일간')
          ? med.durationSummary.replaceAll(RegExp(r'[^0-9]'), '')
          : '',
    );
    final List<String> selectedRepeatDays = isEditing
        ? List.from(med.repeatDays)
        : [];
    bool isPrescription = isEditing ? med.isPrescription : false;
    showModalBottomSheet(
      context: context,
      useRootNavigator: false, // 하단 탭 바가 항상 최상단에 안정적으로 유지되도록 설정!
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 헤더: 타이틀 + 단계 표시 + 닫기
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? '약 정보 수정' : '새로운 약 추가',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentStep == 1
                                  ? '1단계: 기본 정보 입력'
                                  : '2단계: 복용 시간 및 주기 설정',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ================= [1단계: 기본 정보] =================
                    if (currentStep == 1) ...[
                      TextField(
                        controller: nameCtrl,
                        autofocus: !isEditing,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: '약 이름',
                          hintText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: dosageCtrl,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: '복용법',
                          hintText: '식후 30분, 공복 등',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: memoCtrl,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: '기타 (용량, 보관법 등 - 선택)',
                          hintText: '10mg, 1정 등 필요 시 입력',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setModalState(() {
                            isPrescription = !isPrescription;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isPrescription,
                                activeColor: AppColors.warmBrown,
                                visualDensity: VisualDensity.compact,
                                onChanged: (val) {
                                  setModalState(() {
                                    isPrescription = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                '의사 처방 필수 약물 (알림 상시 작동)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (isEditing) ...[
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.neutralDark,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _confirmDeleteMed(med);
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: AppColors.neutralDark,
                                    size: 17,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '삭제',
                                    style: TextStyle(
                                      color: AppColors.neutralDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (nameCtrl.text.trim().isEmpty) return;
                                  setModalState(() {
                                    currentStep = 2; // 2단계로 부드럽게 전환!
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  '복용 시간 설정 ➔',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ================= [2단계: 복용 시간 및 주기] =================
                    if (currentStep == 2) ...[
                      // 1. 복용 주기 (매일, 오늘만, N일마다, N시간마다, 필요 시)
                      Text(
                        '복용 주기',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children:
                            [
                              '매일',
                              '특정 요일',
                              '며칠 간격',
                              '시간 간격',
                              '오늘만',
                              '필요 시',
                            ].map((type) {
                              final isSel = recurrenceType == type;
                              return ChoiceChip(
                                showCheckmark: false,
                                label: Text(type),
                                selected: isSel,
                                selectedColor: AppColors.lightLavender,
                                labelStyle: TextStyle(
                                  color: isSel
                                      ? AppColors.primaryPurple
                                      : AppColors.textPrimary,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 11.5,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() {
                                      recurrenceType = type;
                                      if (type == '시간 간격') {
                                        final intervalH =
                                            int.tryParse(
                                              hourIntervalCtrl.text,
                                            ) ??
                                            8;
                                        final totalDoses = (24 / intervalH)
                                            .floor();
                                        currentSlots = List.generate(
                                          totalDoses,
                                          (i) {
                                            return DoseSlot(
                                              label: '${i + 1}회차',
                                              scheduledTime: i == 0
                                                  ? '첫 복용 시각'
                                                  : '${intervalH * i}시간 뒤',
                                            );
                                          },
                                        );
                                      } else {
                                        currentSlots.removeWhere(
                                          (s) => s.label.contains('회차'),
                                        );
                                        if (type == '오늘만') {
                                          isOngoing = false;
                                          durationDaysCtrl.text = '1';
                                        }
                                      }
                                    });
                                  }
                                },
                              );
                            }).toList(),
                      ),
                      if (recurrenceType == '오늘만' ||
                          recurrenceType == '필요 시') ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.lightLavender.withValues(
                              alpha: 0.45,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            recurrenceType == '오늘만'
                                ? '오늘만: 등록한 당일에만 복약 목록에 표시되고 내일부터는 사라지는 약이에요. 정기 복약 성공·실패와 복약 퍼센트에는 포함되지 않아요.'
                                : '필요 시: 직접 삭제하기 전까지 복약지도에 계속 남아 있지만, 실제로 복용했을 때만 기록하는 약이에요. 정기 복약 성공·실패와 복약 퍼센트에는 포함되지 않아요.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      if (recurrenceType == '특정 요일') ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['월', '화', '수', '목', '금', '토', '일'].map((
                            day,
                          ) {
                            final isDaySel = selectedRepeatDays.contains(day);
                            return InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                setModalState(() {
                                  if (isDaySel) {
                                    selectedRepeatDays.remove(day);
                                  } else {
                                    selectedRepeatDays.add(day);
                                  }
                                });
                              },
                              child: Container(
                                width: 36,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDaySel
                                      ? AppColors.lightLavender
                                      : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDaySel
                                        ? AppColors.primaryPurple
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isDaySel
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isDaySel
                                        ? AppColors.primaryPurple
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (recurrenceType == '며칠 간격') ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: intervalCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '일마다 1회 복용',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (recurrenceType == '시간 간격') ...[
                        const SizedBox(height: 6),
                        // 🌟 기본 칩 없이 바로 숫자 직접 입력받기!
                        Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: TextField(
                                controller: hourIntervalCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: '',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '시간',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 50,
                              child: TextField(
                                controller: minIntervalCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: '',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '분마다 복용',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 🌟 첫 복용 예정 시간만 설정받기 (나머지 회차는 복용 시점에 동적 계산!)
                        Row(
                          children: [
                            Text(
                              '첫 복용 예정 시각',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.divider),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                final time = await AppTimePicker.show(
                                  context,
                                  initialTime: null,
                                  title: '첫 복용 예정 시각',
                                );
                                if (time != null) {
                                  final period = time.period == DayPeriod.am
                                      ? '오전'
                                      : '오후';
                                  final hour = time.hourOfPeriod == 0
                                      ? 12
                                      : time.hourOfPeriod;
                                  final min = time.minute.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  final timeStr = '$period $hour:$min';
                                  setModalState(() {
                                    if (currentSlots.isNotEmpty) {
                                      currentSlots[0].scheduledTime = timeStr;
                                    } else {
                                      currentSlots.add(
                                        DoseSlot(
                                          label: '1회차',
                                          scheduledTime: timeStr,
                                        ),
                                      );
                                    }
                                  });
                                }
                              },
                              child: Text(
                                currentSlots.isNotEmpty
                                    ? (currentSlots[0].scheduledTime ??
                                          '오전 8:00')
                                    : '오전 8:00',
                                style: TextStyle(
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      // 2. 일반 복용 시간대 슬롯 선택 (시간 간격일 때는 숨김!)
                      if (recurrenceType != '필요 시' &&
                          recurrenceType != '시간 간격') ...[
                        Text(
                          '복용 시간대 선택',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ...['아침', '점심', '저녁', '취침 전'].map((label) {
                              final isSel = currentSlots.any(
                                (s) => s.label.startsWith(label),
                              );
                              return FilterChip(
                                showCheckmark: false,
                                label: Text(label),
                                selected: isSel,
                                selectedColor: AppColors.primaryPurple
                                    .withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isSel
                                      ? AppColors.primaryPurple
                                      : AppColors.textPrimary,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      final defaultTime =
                                          _state.routineTimes[label] ??
                                          '오전 8:00';
                                      currentSlots.add(
                                        DoseSlot(
                                          label: label,
                                          scheduledTime: defaultTime,
                                        ),
                                      );
                                    } else {
                                      currentSlots.removeWhere(
                                        (s) => s.label.startsWith(label),
                                      );
                                    }
                                  });
                                },
                              );
                            }),
                            // 커스텀 시간대 슬롯들 (기본 칩들과 동일한 FilterChip 크기, 높이, 라운딩 및 삭제 버튼 적용!)
                            ..._state.customTimeSlots.map((customLabel) {
                              final existingIdx = currentSlots.indexWhere(
                                (s) => s.label == customLabel,
                              );
                              final isSel = existingIdx != -1;
                              return FilterChip(
                                showCheckmark: false,
                                selected: isSel,
                                selectedColor: AppColors.primaryPurple
                                    .withValues(alpha: 0.2),
                                label: Text(
                                  customLabel,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isSel
                                        ? AppColors.primaryPurple
                                        : AppColors.textPrimary,
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                deleteIcon: const Icon(
                                  Icons.close,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                onDeleted: () {
                                  setModalState(() {
                                    currentSlots.removeWhere(
                                      (s) => s.label == customLabel,
                                    );
                                    _state.removeCustomTimeSlot(customLabel);
                                  });
                                },
                                onSelected: (sel) {
                                  if (sel) {
                                    // 🌟 시간 설정을 강제하지 않고 옵셔널로 즉시 추가!
                                    final defaultTime =
                                        _state.routineTimes[customLabel] ??
                                        '오전 8:00';
                                    setModalState(() {
                                      currentSlots.add(
                                        DoseSlot(
                                          label: customLabel,
                                          scheduledTime: defaultTime,
                                        ),
                                      );
                                    });
                                  } else {
                                    setModalState(() {
                                      currentSlots.removeAt(existingIdx);
                                    });
                                  }
                                },
                              );
                            }),
                            // [+ 기타] 추가 버튼 (다른 필터 칩들과 동일한 크기/디자인 적용)
                            FilterChip(
                              showCheckmark: false,
                              avatar: Icon(
                                Icons.add,
                                size: 14,
                                color: AppColors.primaryPurple,
                              ),
                              label: const Text('기타'),
                              selected: false,
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primaryPurple,
                              ),
                              onSelected: (_) async {
                                final textCtrl = TextEditingController();
                                final name = await showDialog<String>(
                                  context: context,
                                  builder: (dCtx) {
                                    return AlertDialog(
                                      title: const Text(
                                        '새로운 복약 시점 추가',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: TextField(
                                        controller: textCtrl,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          hintText: '',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dCtx).pop(),
                                          child: const Text('취소'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(dCtx)
                                                  .pop(textCtrl.text.trim()),
                                          child: const Text('추가'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (name != null && name.isNotEmpty) {
                                  _state.addCustomTimeSlot(name);
                                  final time = await AppTimePicker.show(
                                    context,
                                    initialTime: null,
                                    title: '$name 알림 시각 설정',
                                  );
                                  String? finalTime;
                                  if (time != null) {
                                    final period = time.period == DayPeriod.am
                                        ? '오전'
                                        : '오후';
                                    final hour = time.hourOfPeriod == 0
                                        ? 12
                                        : time.hourOfPeriod;
                                    final min = time.minute.toString().padLeft(
                                      2,
                                      '0',
                                    );
                                    finalTime = '$period $hour:$min';
                                    _state.routineTimes[name] = finalTime;
                                  }
                                  setModalState(() {
                                    currentSlots.add(
                                      DoseSlot(
                                        label: name,
                                        scheduledTime: finalTime,
                                      ),
                                    );
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 등록된 회차 목록 표시 (시간 간격 약물은 첫 복용 시각만 위에 표시하므로 숨김!)
                        if (currentSlots.isNotEmpty &&
                            recurrenceType != '시간 간격' &&
                            recurrenceType != '필요 시')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: currentSlots.asMap().entries.map((
                                entry,
                              ) {
                                final idx = entry.key;
                                final slot = entry.value;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 1.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${slot.label}: ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        slot.scheduledTime ?? '시각 미지정',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primaryPurple,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () async {
                                          final time = await AppTimePicker.show(
                                            context,
                                            initialTime: TimeOfDay.now(),
                                            title: '${slot.label} 알림 예정 시각 변경',
                                          );
                                          if (time != null) {
                                            final period =
                                                time.period == DayPeriod.am
                                                ? '오전'
                                                : '오후';
                                            final hour = time.hourOfPeriod == 0
                                                ? 12
                                                : time.hourOfPeriod;
                                            final min = time.minute
                                                .toString()
                                                .padLeft(2, '0');
                                            setModalState(() {
                                              slot.scheduledTime =
                                                  '$period $hour:$min';
                                            });
                                          }
                                        },
                                        child: const Text(
                                          '시각 변경',
                                          style: TextStyle(fontSize: 11.5),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.close,
                                          size: 15,
                                          color: AppColors.textMuted,
                                        ),
                                        onPressed: () {
                                          setModalState(() {
                                            currentSlots.removeAt(idx);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 10),
                      ],

                      // 3. 복용 기간
                      if (recurrenceType != '오늘만') ...[
                        Text(
                          '복용 기간',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ChoiceChip(
                              showCheckmark: false,
                              label: const Text('계속 꾸준히'),
                              selected: isOngoing,
                              selectedColor: AppColors.lightLavender,
                              labelStyle: TextStyle(
                                color: isOngoing
                                    ? AppColors.primaryPurple
                                    : AppColors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: isOngoing
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                setModalState(() {
                                  isOngoing = true;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              showCheckmark: false,
                              label: const Text('투약 일수 입력'),
                              selected: !isOngoing,
                              selectedColor: AppColors.lightLavender,
                              labelStyle: TextStyle(
                                color: !isOngoing
                                    ? AppColors.primaryPurple
                                    : AppColors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: !isOngoing
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                setModalState(() {
                                  isOngoing = false;
                                });
                              },
                            ),
                          ],
                        ),
                        if (!isOngoing) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: durationDaysCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 6,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '일간 복용',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],

                      // 하단 이전 / 저장 버튼
                      Row(
                        children: [
                          if (isEditing) ...[
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.neutralDark,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _confirmDeleteMed(med);
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: AppColors.neutralDark,
                                    size: 17,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '삭제',
                                    style: TextStyle(
                                      color: AppColors.neutralDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                currentStep = 1; // 1단계로 되돌아가기
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(color: AppColors.divider),
                            ),
                            child: Text(
                              '이전',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  String recurrenceSummary = '매일';
                                  if (recurrenceType == '오늘만') {
                                    recurrenceSummary = '오늘만';
                                  } else if (recurrenceType == '특정 요일') {
                                    recurrenceSummary =
                                        selectedRepeatDays.isEmpty
                                        ? '매일'
                                        : '매주 ${selectedRepeatDays.join(",")}요일';
                                  } else if (recurrenceType == '며칠 간격') {
                                    final n = intervalCtrl.text.trim().isEmpty
                                        ? '2'
                                        : intervalCtrl.text.trim();
                                    recurrenceSummary = '$n일 간격';
                                  } else if (recurrenceType == '필요 시') {
                                    recurrenceSummary = '필요 시';
                                  } else if (recurrenceType == '시간 간격') {
                                    final h =
                                        int.tryParse(
                                          hourIntervalCtrl.text.trim(),
                                        ) ??
                                        0;
                                    final m =
                                        int.tryParse(
                                          minIntervalCtrl.text.trim(),
                                        ) ??
                                        0;
                                    if (h > 0 && m > 0) {
                                      recurrenceSummary = '$h시간 $m분 간격';
                                    } else if (h > 0) {
                                      recurrenceSummary = '$h시간 간격';
                                    } else {
                                      recurrenceSummary =
                                          '${m > 0 ? m : 30}분 간격';
                                    }
                                  } else {
                                    recurrenceSummary = currentSlots.length > 1
                                        ? '하루 ${currentSlots.length}회'
                                        : '매일';
                                  }

                                  String durationSummary = '계속 복용';
                                  if (recurrenceType == '오늘만') {
                                    durationSummary = '오늘만';
                                  } else if (!isOngoing) {
                                    final days =
                                        durationDaysCtrl.text.trim().isEmpty
                                        ? '7'
                                        : durationDaysCtrl.text.trim();
                                    durationSummary = '$days일간';
                                  }

                                  if (recurrenceType == '시간 간격') {
                                    // 🌟 시간 간격 약물: 처음에 여러 회차를 미리 만들지 않고, 1회차(첫 복용 예정 시각)만 생성!
                                    final firstTime = currentSlots.isNotEmpty
                                        ? currentSlots[0].scheduledTime
                                        : '오전 8:00';
                                    currentSlots = [
                                      DoseSlot(
                                        label: '1회차',
                                        scheduledTime: firstTime,
                                      ),
                                    ];
                                  } else if (currentSlots.isEmpty &&
                                      recurrenceType != '필요 시') {
                                    currentSlots.add(
                                      DoseSlot(
                                        label: '복용',
                                        scheduledTime: null,
                                      ),
                                    );
                                  }
                                  final slotsToSave = recurrenceType == '필요 시'
                                      ? [
                                          ...existingAsNeededHistory,
                                          ...currentSlots,
                                        ]
                                      : currentSlots;
                                  if (isEditing) {
                                    _state.updateMedication(
                                      id: med.id,
                                      name: nameCtrl.text.trim(),
                                      dosage: dosageCtrl.text.trim().isEmpty
                                          ? '1정'
                                          : dosageCtrl.text.trim(),
                                      doseSlots: slotsToSave,
                                      recurrenceSummary: recurrenceSummary,
                                      durationSummary: durationSummary,
                                      isPrescription: isPrescription,
                                      repeatDays: recurrenceType == '특정 요일'
                                          ? selectedRepeatDays
                                          : [],
                                      memo: memoCtrl.text.trim().isNotEmpty
                                          ? memoCtrl.text.trim()
                                          : null,
                                    );
                                  } else {
                                    _state.addMedication(
                                      name: nameCtrl.text.trim(),
                                      dosage: dosageCtrl.text.trim().isEmpty
                                          ? '1정'
                                          : dosageCtrl.text.trim(),
                                      doseSlots: slotsToSave,
                                      recurrenceSummary: recurrenceSummary,
                                      durationSummary: durationSummary,
                                      isPrescription: isPrescription,
                                      repeatDays: recurrenceType == '특정 요일'
                                          ? selectedRepeatDays
                                          : [],
                                      memo: memoCtrl.text.trim().isNotEmpty
                                          ? memoCtrl.text.trim()
                                          : null,
                                    );
                                  }
                                  Navigator.of(ctx).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  isEditing ? '수정 내용 저장' : '약 추가 완료',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🌟 완료된 회차 슬롯 터치 시 뜨는 안전 액션 시트
  void _showSlotActionSheet(MedicationItem med, int slotIndex, DoseSlot slot) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 36, left: 12, right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, -4),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.successGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${med.name} · ${slot.label} 복용 완료됨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '기록된 복용 시각: ${slot.takenTime ?? slot.scheduledTime ?? "확인됨"}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // 1. 복용 시간 수정 버튼
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.access_time,
                  color: AppColors.primaryPurple,
                  size: 22,
                ),
                title: const Text(
                  '복용 시간 수정하기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '실제로 먹은 정확한 시간으로 변경합니다',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final time = await AppTimePicker.show(
                    context,
                    initialTime: TimeOfDay.now(),
                    title: '${slot.label} 실제 복용 시각 변경',
                  );
                  if (time != null) {
                    final period = time.period == DayPeriod.am ? '오전' : '오후';
                    final hour = time.hourOfPeriod == 0
                        ? 12
                        : time.hourOfPeriod;
                    final min = time.minute.toString().padLeft(2, '0');
                    _state.updateSlotTakenTime(
                      med.id,
                      slotIndex,
                      '$period $hour:$min',
                    );
                  }
                },
              ),

              const SizedBox(height: 4),

              // 2. 이 회차만 복약 취소 버튼 (완료된 경우)
              if (slot.isCompleted)
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.undo,
                    color: AppColors.warmBrown,
                    size: 22,
                  ),
                  title: Text(
                    '이 회차만 복약 취소하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  subtitle: Text(
                    '점심/저녁 등 다른 회차는 그대로 유지됩니다',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _state.cancelSpecificSlot(med.id, slotIndex);
                  },
                ),

              // 3. 건너뛴 회차 복구 버튼 (이미 건너뛴 경우)
              if (slot.isSkipped)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.refresh,
                    color: AppColors.primaryPurple,
                    size: 22,
                  ),
                  title: Text(
                    '건너뜀 복구하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  subtitle: Text(
                    '다시 복용 대기 상태로 되돌립니다',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _state.restoreSkippedSlot(med.id, slotIndex);
                  },
                ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    '닫기',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 복용 건너뛰기 확인 다이얼로그 (해당 회차만 덜 눈에 띄게 + 잠깐 토스트 알림)
  void _showSkipConfirmDialog(MedicationItem med) {
    final targetSlot = med.nextPendingSlot;
    final slotName = targetSlot?.label ?? '이번 회차';
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(
          '$slotName 복약 건너뛰기',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\'${med.name} ($slotName)\' 복용을 건너뛸까요?'),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: '건너뛴 이유 (선택사항)',
                hintText: '이유를 남기지 않아도 괜찮아요',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmBrown,
            ),
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.skipNextSlot(med.id, reason: reasonController.text);
              CelebrationToast.show(
                context,
                title: '이번 복용을 건너뛰었어요',
                message: '자책하지 마세요. 다음 복용에 편안하게 집중하면 충분해요 :)',
              );
            },
            child: const Text(
              '건너뛰기 확정',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMed(MedicationItem med) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text(
          '복약 삭제',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text('\'${med.name}\' 약을 목록에서 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neutralDark,
            ),
            onPressed: () {
              _state.deleteMedication(med.id);
              Navigator.of(dCtx).pop();
            },
            child: const Text(
              '삭제하기',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 오늘 복용해야 하는 약 vs 오늘은 아닌 약(주 1회, 격일 등) 분리!
    final visibleMeds = _state.medications
        .where((m) => m.recurrenceSummary != '오늘만' || m.isDueToday)
        .toList();
    final todayMeds = visibleMeds.where((m) => m.isDueToday).toList();
    final otherMeds = visibleMeds.where((m) => !m.isDueToday).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildSlimProgressHeader(),
        const SizedBox(height: 12),

        // 1. 오늘의 복약 카드들
        ...todayMeds.map((med) => _buildMedCard(med)),

        // 2. 오늘은 아니지만 관리 중인 약 (구차한 제목 없이 얇고 조용한 1줄 아이템만 바로 노출!)
        if (otherMeds.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...otherMeds.map((med) => _buildCompactOtherMedCard(med)),
        ],

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: () => _showMedEditModal(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryPurple, width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.white,
            ),
            child: Text(
              '새 복약 추가',
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // 🌟 오늘은 아닌 약들을 위한 극도로 슬림하고 절제된 1줄 미니멀 표시
  Widget _buildCompactOtherMedCard(MedicationItem med) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showMedEditModal(med: med),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${med.name} (${med.recurrenceSummary})',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              med.dosage,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlimProgressHeader() {
    final total = _state.totalDoseSlots;
    final completed = _state.completedDoseSlots;
    final rate = total == 0 ? 0.0 : (completed / total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '오늘 복약',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    total == 0 ? '등록된 약이 없어요' : '$total회 중 $completed회',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: total == 0
                          ? AppColors.textSecondary
                          : AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
              Text(
                total == 0 ? '0%' : '${(rate * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: total == 0
                      ? AppColors.textSecondary
                      : AppColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 6,
              backgroundColor: AppColors.lightLavender,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1약 1카드 구조
  Widget _buildMedCard(MedicationItem med) {
    final isAsNeeded = med.recurrenceSummary == '필요 시';
    final isAllDone = !isAsNeeded && med.isAllCompleted;
    final isSkipped = med.skipReason != null;
    final now = DateTime.now();
    final visibleDoseEntries = med.doseSlots.asMap().entries.where((entry) {
      if (!isAsNeeded) return true;
      final date = entry.value.takenDate;
      return entry.value.isCompleted &&
          date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSkipped ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: med.isExpanded
              ? AppColors.primaryPurple.withValues(alpha: 0.35)
              : AppColors.divider.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🌿 PRD 5.1절 건너뜀 안심 배너
          if (isSkipped)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '이번 복용을 건너뛰었어요 · 다음 복용에 집중해요',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _state.toggleMedExpanded(med.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isAllDone
                          ? AppColors.successBg
                          : (med.isPrescription
                                ? AppColors.lightLavender
                                : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication,
                      size: 19,
                      color: isAllDone
                          ? AppColors.successGreen
                          : (med.isPrescription
                                ? AppColors.primaryPurple
                                : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              med.name,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightLavender,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                med.recurrenceSummary,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (med.durationSummary != med.recurrenceSummary &&
                                med.recurrenceSummary != '오늘만')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  med.durationSummary,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (med.isPrescription)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warmBrown.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '처방',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.warmBrown,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // 회차별 슬롯
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: visibleDoseEntries
                              .where((entry) {
                                // 필요 시 약은 복용 전 예정 회차를 표시하지 않고,
                                // 실제 복용한 회차만 이력으로 보여준다.
                                return !isAsNeeded ||
                                    entry.value.isCompleted ||
                                    entry.value.isSkipped;
                              })
                              .map((entry) {
                                final idx = entry.key;
                                final slot = entry.value;
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (!slot.isCompleted &&
                                          !slot.isSkipped) {
                                        final todayMeds = _state.medications
                                            .where((m) => m.isDueToday)
                                            .toList();
                                        final wasAllMedsDoneBefore =
                                            todayMeds.isNotEmpty &&
                                            todayMeds.every(
                                              (m) => m.isAllCompleted,
                                            );
                                        _state.completeSlot(med.id, idx);
                                        final isAllMedsDoneNow =
                                            todayMeds.isNotEmpty &&
                                            todayMeds.every(
                                              (m) => m.isAllCompleted,
                                            );

                                        if (!wasAllMedsDoneBefore &&
                                            isAllMedsDoneNow) {
                                          // 🎉 오늘 하루 먹어야 하는 모든 복약 100% 올클리어! 축하 오버레이 팝업 등장!
                                          HagomCelebrationOverlay.show(
                                            context,
                                            assetPath:
                                                AppAssets.medsAllDoneWebp,
                                            title: '오늘 복약 모두 완료!',
                                            subtitle:
                                                '정말 대단해요! 오늘 복약을 전부 챙기셨어요.',
                                          );
                                        } else {
                                          final toast =
                                              HagomDialogue.getRandomMedToast(
                                                '${med.name} ${slot.label}',
                                              );
                                          CelebrationToast.show(
                                            context,
                                            title: toast['title']!,
                                            message: toast['message']!,
                                          );
                                        }
                                      } else {
                                        _showSlotActionSheet(med, idx, slot);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: slot.isCompleted
                                            ? AppColors.completedBg
                                            : (slot.isSkipped
                                                  ? const Color(0xFFF9FAFB)
                                                  : const Color(0xFFF3F4F6)),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: slot.isCompleted
                                              ? AppColors.completedBorder
                                              : (slot.isSkipped
                                                    ? AppColors.divider
                                                          .withValues(
                                                            alpha: 0.3,
                                                          )
                                                    : AppColors.divider),
                                        ),
                                      ),
                                      child: Text(
                                        slot.isSkipped
                                            ? '${slot.label} 건너뜀'
                                            : (slot.isCompleted
                                                  ? '${slot.label} ${slot.takenTime?.split(' ').last ?? slot.scheduledTime?.split(' ').last ?? ''}'
                                                        .trim()
                                                  : '${slot.label} ${slot.scheduledTime?.split(' ').last ?? ''}'
                                                        .trim()),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11.0,
                                          fontWeight: slot.isCompleted
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: slot.isCompleted
                                              ? AppColors.completedText
                                              : (slot.isSkipped
                                                    ? AppColors.textMuted
                                                          .withValues(
                                                            alpha: 0.6,
                                                          )
                                                    : AppColors.textPrimary),
                                          decoration: slot.isSkipped
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 🔒 [우측 완전 고정 액션 버튼 (76x32dp)]:
                  GestureDetector(
                    onTap: () {
                      if (!isAllDone) {
                        final todayMeds = _state.medications
                            .where((m) => m.isDueToday)
                            .toList();
                        final wasAllMedsDoneBefore =
                            todayMeds.isNotEmpty &&
                            todayMeds.every((m) => m.isAllCompleted);
                        _state.completeNextSlot(med.id);
                        final isAllMedsDoneNow =
                            todayMeds.isNotEmpty &&
                            todayMeds.every((m) => m.isAllCompleted);

                        if (!wasAllMedsDoneBefore && isAllMedsDoneNow) {
                          // 🎉 오늘 하루 먹어야 하는 모든 복약 100% 올클리어! 축하 오버레이 팝업 등장!
                          HagomCelebrationOverlay.show(
                            context,
                            assetPath: AppAssets.medsAllDoneWebp,
                            title: '오늘 복약 모두 완료!',
                            subtitle: '정말 대단해요! 오늘 복약을 전부 챙기셨어요.',
                          );
                        } else {
                          final toast = HagomDialogue.getRandomMedToast(
                            med.name,
                          );
                          CelebrationToast.show(
                            context,
                            title: toast['title']!,
                            message: toast['message']!,
                          );
                        }
                      } else {
                        // 이미 모든 회차가 완료된 상태에서 탭했을 때 토스트에서 바로 마지막 회차 되돌리기 지원!
                        CelebrationToast.show(
                          context,
                          title: '오늘 복용을 모두 마쳤어요',
                          message: '${med.name} 약을 이미 잘 챙겨 드셨어요.',
                          actionLabel: '되돌리기',
                          onAction: () {
                            _state.cancelLastCompletedSlot(med.id);
                            CelebrationToast.show(
                              context,
                              title: '복약 되돌림',
                              message: '${med.name} 마지막 회차 복약을 되돌렸어요.',
                            );
                          },
                        );
                      }
                    },
                    child: SizedBox(
                      width: 76,
                      height: 32,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isAllDone
                              ? AppColors.completedBg
                              : AppColors.primaryPurple,
                          borderRadius: BorderRadius.circular(8),
                          border: isAllDone
                              ? Border.all(color: AppColors.completedBorder)
                              : null,
                        ),
                        child: Text(
                          isAllDone ? '완료' : '지금 복용',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isAllDone
                                ? AppColors.completedText
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 카드 본문 탭 시 펼쳐지는 상세 옵션
          if (med.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showMedEditModal(med: med),
                    child: Text(
                      '정보 수정',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 🌟 [건너뛰기] 버튼 복원 (남은 다음 회차 핀셋 건너뜀)
                  if (!isAsNeeded && !isAllDone && med.nextPendingSlot != null)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showSkipConfirmDialog(med),
                      child: Text(
                        '${med.nextPendingSlot!.label} 건너뛰기',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
