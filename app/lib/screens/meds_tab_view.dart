import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/medication_item.dart';
import '../state/app_state_manager.dart';
import '../constants/hagom_dialogue.dart';
import '../widgets/celebration_toast.dart';
import '../widgets/app_time_picker.dart';
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

    String recurrenceType = isEditing ? med.recurrenceSummary : '매일';
    if (recurrenceType.contains('시간')) {
      recurrenceType = '시간 간격';
    } else if (recurrenceType.contains('간격')) {
      recurrenceType = '며칠 간격';
    }
    final intervalCtrl = TextEditingController(
      text: isEditing && med.recurrenceSummary.contains('일 간격')
          ? med.recurrenceSummary.replaceAll(RegExp(r'[^0-9]'), '')
          : '',
    );
    final hourIntervalCtrl = TextEditingController(
      text: isEditing && med.recurrenceSummary.contains('시간')
          ? (RegExp(r'(\d+)시간').firstMatch(med.recurrenceSummary)?.group(1) ?? '')
          : '',
    );
    final minIntervalCtrl = TextEditingController(
      text: isEditing && med.recurrenceSummary.contains('분')
          ? (RegExp(r'(\d+)분').firstMatch(med.recurrenceSummary)?.group(1) ?? '')
          : '',
    );

    List<DoseSlot> currentSlots = isEditing
        ? med.doseSlots.map((s) => DoseSlot(
            label: s.label,
            scheduledTime: s.scheduledTime,
            isCompleted: s.isCompleted,
            takenTime: s.takenTime,
          )).toList()
        : [];

    bool isOngoing = isEditing ? (med.durationSummary == '계속 복용') : true;
    final durationDaysCtrl = TextEditingController(
      text: isEditing && med.durationSummary.contains('일간')
          ? med.durationSummary.replaceAll(RegExp(r'[^0-9]'), '')
          : '',
    );
    final List<String> selectedRepeatDays = isEditing ? List.from(med.repeatDays) : [];
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
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, -4)),
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
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentStep == 1 ? '1단계: 기본 정보 입력' : '2단계: 복용 시간 및 주기 설정',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: dosageCtrl,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: '용량 및 복용법',
                        hintText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
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
                        const Text('의사 처방 필수 약물 (알림 상시 작동)', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (isEditing) ...[
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.neutralDark),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _confirmDeleteMed(med);
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline, color: AppColors.neutralDark, size: 17),
                                SizedBox(width: 4),
                                Text('삭제', style: TextStyle(color: AppColors.neutralDark, fontWeight: FontWeight.bold, fontSize: 13)),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('복용 시간 설정 ➔', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ================= [2단계: 복용 시간 및 주기] =================
                  if (currentStep == 2) ...[
                    // 1. 복용 주기 (매일, 오늘만, N일마다, N시간마다, 필요 시)
                    const Text('복용 주기', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: ['매일', '특정 요일', '며칠 간격', '시간 간격', '오늘만', '필요 시'].map((type) {
                        final isSel = recurrenceType == type;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(type),
                          selected: isSel,
                          selectedColor: AppColors.lightLavender,
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.primaryPurple : AppColors.textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11.5,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                recurrenceType = type;
                                if (type == '시간 간격') {
                                  final intervalH = int.tryParse(hourIntervalCtrl.text) ?? 8;
                                  final totalDoses = (24 / intervalH).floor();
                                  currentSlots = List.generate(totalDoses, (i) {
                                    return DoseSlot(
                                      label: '${i + 1}회차',
                                      scheduledTime: i == 0 ? '첫 복용 시각' : '${intervalH * i}시간 뒤',
                                    );
                                  });
                                } else {
                                  currentSlots.removeWhere((s) => s.label.contains('회차'));
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
                    if (recurrenceType == '특정 요일') ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['월', '화', '수', '목', '금', '토', '일'].map((day) {
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
                                color: isDaySel ? AppColors.lightLavender : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDaySel ? AppColors.primaryPurple : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isDaySel ? FontWeight.bold : FontWeight.w500,
                                  color: isDaySel ? AppColors.primaryPurple : AppColors.textSecondary,
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('일마다 1회 복용', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
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
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('시간', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
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
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('분마다 복용', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 🌟 첫 복용 예정 시간만 설정받기 (나머지 회차는 복용 시점에 동적 계산!)
                      Row(
                        children: [
                          const Text('첫 복용 예정 시각', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const Spacer(),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.divider),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final time = await AppTimePicker.show(
                                context,
                                initialTime: const TimeOfDay(hour: 8, minute: 0),
                                title: '첫 복용 예정 시각',
                              );
                              if (time != null) {
                                final period = time.period == DayPeriod.am ? '오전' : '오후';
                                final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                                final min = time.minute.toString().padLeft(2, '0');
                                final timeStr = '$period $hour:$min';
                                setModalState(() {
                                  if (currentSlots.isNotEmpty) {
                                    currentSlots[0].scheduledTime = timeStr;
                                  } else {
                                    currentSlots.add(DoseSlot(label: '1회차', scheduledTime: timeStr));
                                  }
                                });
                              }
                            },
                            child: Text(
                              currentSlots.isNotEmpty ? (currentSlots[0].scheduledTime ?? '오전 8:00') : '오전 8:00',
                              style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // 2. 일반 복용 시간대 슬롯 선택 (시간 간격일 때는 숨김!)
                    if (recurrenceType != '필요 시' && recurrenceType != '시간 간격') ...[
                      const Text('복용 시간대 선택', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...['아침', '점심', '저녁', '취침 전'].map((label) {
                            final existingIdx = currentSlots.indexWhere((s) => s.label == label);
                            final isSel = existingIdx != -1;
                            return FilterChip(
                              showCheckmark: false, // 🌟 체크 표시 완전 제거하여 버튼 크기 덜컹거림 원천 차단!
                              label: Text(label),
                              selected: isSel,
                              selectedColor: AppColors.primaryPurple.withOpacity(0.2),
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                color: isSel ? AppColors.primaryPurple : AppColors.textPrimary,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (sel) async {
                                if (sel) {
                                  final time = await AppTimePicker.show(
                                    context,
                                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                                    title: '$label 알림 시각 설정',
                                  );
                                  String finalTime = _state.routineTimes[label] ?? '오전 8:00';
                                  if (time != null) {
                                    final period = time.period == DayPeriod.am ? '오전' : '오후';
                                    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                                    final min = time.minute.toString().padLeft(2, '0');
                                    finalTime = '$period $hour:$min';
                                    _state.routineTimes[label] = finalTime;
                                  }
                                  setModalState(() {
                                    currentSlots.add(DoseSlot(label: label, scheduledTime: finalTime));
                                  });
                                } else {
                                  setModalState(() {
                                    currentSlots.removeAt(existingIdx);
                                  });
                                }
                              },
                            );
                          }),
                          // 커스텀 시간대 슬롯들
                          ..._state.customTimeSlots.map((customLabel) {
                            final existingIdx = currentSlots.indexWhere((s) => s.label == customLabel);
                            final isSel = existingIdx != -1;
                            return Container(
                              margin: const EdgeInsets.only(right: 6, bottom: 6),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primaryPurple.withOpacity(0.15) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel ? AppColors.primaryPurple.withOpacity(0.5) : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      if (!isSel) {
                                        final time = await AppTimePicker.show(
                                          context,
                                          initialTime: const TimeOfDay(hour: 8, minute: 0),
                                          title: '$customLabel 알림 시각 설정',
                                        );
                                        String? finalTime;
                                        if (time != null) {
                                          final period = time.period == DayPeriod.am ? '오전' : '오후';
                                          final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                                          final min = time.minute.toString().padLeft(2, '0');
                                          finalTime = '$period $hour:$min';
                                          _state.routineTimes[customLabel] = finalTime;
                                        }
                                        setModalState(() {
                                          currentSlots.add(DoseSlot(label: customLabel, scheduledTime: finalTime));
                                        });
                                      } else {
                                        setModalState(() {
                                          currentSlots.removeAt(existingIdx);
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Text(
                                        customLabel,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                          color: isSel ? AppColors.primaryPurple : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        currentSlots.removeWhere((s) => s.label == customLabel);
                                        _state.removeCustomTimeSlot(customLabel);
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 6, left: 2, top: 4, bottom: 4),
                                      child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          // [+ 기타] 추가 버튼 (다른 필터 칩들과 동일한 크기/디자인 적용)
                          FilterChip(
                            showCheckmark: false,
                            avatar: const Icon(Icons.add, size: 14, color: AppColors.primaryPurple),
                            label: const Text('기타'),
                            selected: false,
                            labelStyle: const TextStyle(fontSize: 11.5, color: AppColors.primaryPurple),
                            onSelected: (_) async {
                              final textCtrl = TextEditingController();
                              final name = await showDialog<String>(
                                context: context,
                                builder: (dCtx) {
                                  return AlertDialog(
                                    title: const Text('새로운 복약 시점 추가', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    content: TextField(
                                      controller: textCtrl,
                                      autofocus: true,
                                      decoration: const InputDecoration(hintText: ''),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(dCtx).pop(), child: const Text('취소')),
                                      ElevatedButton(onPressed: () => Navigator.of(dCtx).pop(textCtrl.text.trim()), child: const Text('추가')),
                                    ],
                                  );
                                },
                              );
                              if (name != null && name.isNotEmpty) {
                                _state.addCustomTimeSlot(name);
                                final time = await AppTimePicker.show(
                                  context,
                                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                                  title: '$name 알림 시각 설정',
                                );
                                String? finalTime;
                                if (time != null) {
                                  final period = time.period == DayPeriod.am ? '오전' : '오후';
                                  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                                  final min = time.minute.toString().padLeft(2, '0');
                                  finalTime = '$period $hour:$min';
                                  _state.routineTimes[name] = finalTime;
                                }
                                setModalState(() {
                                  currentSlots.add(DoseSlot(label: name, scheduledTime: finalTime));
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 등록된 회차 목록 표시 (시간 간격 약물은 첫 복용 시각만 위에 표시하므로 숨김!)
                      if (currentSlots.isNotEmpty && recurrenceType != '시간 간격')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: currentSlots.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final slot = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    Text('${slot.label}: ', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    Text(slot.scheduledTime ?? '시각 미지정', style: const TextStyle(fontSize: 11.5, color: AppColors.primaryPurple)),
                                    const Spacer(),
                                    TextButton(
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                      onPressed: () async {
                                        final time = await AppTimePicker.show(
                                          context,
                                          initialTime: TimeOfDay.now(),
                                          title: '${slot.label} 알림 예정 시각 변경',
                                        );
                                        if (time != null) {
                                          final period = time.period == DayPeriod.am ? '오전' : '오후';
                                          final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                                          final min = time.minute.toString().padLeft(2, '0');
                                          setModalState(() {
                                            slot.scheduledTime = '$period $hour:$min';
                                          });
                                        }
                                      },
                                      child: const Text('시각 변경', style: TextStyle(fontSize: 11)),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
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
                      const Text('복용 기간', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ChoiceChip(
                            showCheckmark: false,
                            label: const Text('계속 꾸준히'),
                            selected: isOngoing,
                            selectedColor: AppColors.lightLavender,
                            labelStyle: TextStyle(
                              color: isOngoing ? AppColors.primaryPurple : AppColors.textPrimary,
                              fontSize: 11.5,
                              fontWeight: isOngoing ? FontWeight.bold : FontWeight.normal,
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
                              color: !isOngoing ? AppColors.primaryPurple : AppColors.textPrimary,
                              fontSize: 11.5,
                              fontWeight: !isOngoing ? FontWeight.bold : FontWeight.normal,
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
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('일간 복용', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
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
                              side: const BorderSide(color: AppColors.neutralDark),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _confirmDeleteMed(med);
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline, color: AppColors.neutralDark, size: 17),
                                SizedBox(width: 4),
                                Text('삭제', style: TextStyle(color: AppColors.neutralDark, fontWeight: FontWeight.bold, fontSize: 13)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: AppColors.divider),
                          ),
                          child: const Text('이전', style: TextStyle(color: AppColors.textSecondary)),
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
                                  recurrenceSummary = selectedRepeatDays.isEmpty ? '매일' : '매주 ${selectedRepeatDays.join(",")}요일';
                                } else if (recurrenceType == '며칠 간격') {
                                  final n = intervalCtrl.text.trim().isEmpty ? '2' : intervalCtrl.text.trim();
                                  recurrenceSummary = '$n일 간격';
                                } else if (recurrenceType == '필요 시') {
                                  recurrenceSummary = '필요 시';
                                } else if (recurrenceType == '시간 간격') {
                                  final h = int.tryParse(hourIntervalCtrl.text.trim()) ?? 0;
                                  final m = int.tryParse(minIntervalCtrl.text.trim()) ?? 0;
                                  if (h > 0 && m > 0) {
                                    recurrenceSummary = '$h시간 $m분 간격';
                                  } else if (h > 0) {
                                    recurrenceSummary = '$h시간 간격';
                                  } else {
                                    recurrenceSummary = '${m > 0 ? m : 30}분 간격';
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
                                  final days = durationDaysCtrl.text.trim().isEmpty ? '7' : durationDaysCtrl.text.trim();
                                  durationSummary = '$days일간';
                                }

                                if (recurrenceType == '시간 간격') {
                                  // 🌟 시간 간격 약물: 처음에 여러 회차를 미리 만들지 않고, 1회차(첫 복용 예정 시각)만 생성!
                                  final firstTime = currentSlots.isNotEmpty ? currentSlots[0].scheduledTime : '오전 8:00';
                                  currentSlots = [
                                    DoseSlot(label: '1회차', scheduledTime: firstTime),
                                  ];
                                } else if (currentSlots.isEmpty) {
                                  currentSlots.add(DoseSlot(label: '복용', scheduledTime: null));
                                }
                                if (isEditing) {
                                  _state.updateMedication(
                                    id: med.id,
                                    name: nameCtrl.text.trim(),
                                    dosage: dosageCtrl.text.trim().isEmpty ? '1정' : dosageCtrl.text.trim(),
                                    doseSlots: currentSlots,
                                    recurrenceSummary: recurrenceSummary,
                                    durationSummary: durationSummary,
                                    isPrescription: isPrescription,
                                    repeatDays: recurrenceType == '특정 요일' ? selectedRepeatDays : [],
                                  );
                                } else {
                                  _state.addMedication(
                                    name: nameCtrl.text.trim(),
                                    dosage: dosageCtrl.text.trim().isEmpty ? '1정' : dosageCtrl.text.trim(),
                                    doseSlots: currentSlots,
                                    recurrenceSummary: recurrenceSummary,
                                    durationSummary: durationSummary,
                                    isPrescription: isPrescription,
                                    repeatDays: recurrenceType == '특정 요일' ? selectedRepeatDays : [],
                                  );
                                }
                                Navigator.of(ctx).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                isEditing ? '수정 내용 저장' : '약 추가 완료',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, -4)),
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
                    child: const Icon(Icons.check_circle, size: 18, color: AppColors.successGreen),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${med.name} · ${slot.label} 복용 완료됨',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '기록된 복용 시각: ${slot.takenTime ?? slot.scheduledTime ?? "확인됨"}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.successGreen, fontWeight: FontWeight.w600),
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
                leading: const Icon(Icons.access_time, color: AppColors.primaryPurple, size: 22),
                title: const Text('복용 시간 수정하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('실제로 먹은 정확한 시간으로 변경합니다', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final time = await AppTimePicker.show(
                    context,
                    initialTime: TimeOfDay.now(),
                    title: '${slot.label} 실제 복용 시각 변경',
                  );
                  if (time != null) {
                    final period = time.period == DayPeriod.am ? '오전' : '오후';
                    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                    final min = time.minute.toString().padLeft(2, '0');
                    _state.updateSlotTakenTime(med.id, slotIndex, '$period $hour:$min');
                  }
                },
              ),

              const SizedBox(height: 4),

              // 2. 이 회차만 복약 취소 버튼 (완료된 경우)
              if (slot.isCompleted)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.undo, color: AppColors.warmBrown, size: 22),
                  title: const Text('이 회차만 복약 취소하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warmBrown)),
                  subtitle: const Text('점심/저녁 등 다른 회차는 그대로 유지됩니다', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
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
                  leading: const Icon(Icons.refresh, color: AppColors.primaryPurple, size: 22),
                  title: const Text('건너뜀 복구하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                  subtitle: const Text('다시 복용 대기 상태로 되돌립니다', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
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
                  child: const Text('닫기', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text('$slotName 복약 건너뛰기', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('\'${med.name} ($slotName)\' 복용을 건너뛸까요?\n\n건너뛴 복용은 실패가 아니에요. 무리하지 않고 다음 복용에 집중하면 충분해요 🌿'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warmBrown),
            onPressed: () {
              Navigator.of(dCtx).pop();
              _state.skipNextSlot(med.id);
              CelebrationToast.show(
                context,
                title: '이번 복용을 건너뛰었어요 🌿',
                message: '자책하지 마세요. 다음 복용에 편안하게 집중하면 충분해요 :)',
              );
            },
            child: const Text('건너뛰기 확정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  void _confirmDeleteMed(MedicationItem med) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('복약 항목 삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('\'${med.name}\' 약을 목록에서 완전히 삭제할까요?\n지금까지의 복용 체크 기록도 함께 정리됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neutralDark),
            onPressed: () {
              _state.deleteMedication(med.id);
              Navigator.of(dCtx).pop();
            },
            child: const Text('삭제하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 오늘 복용해야 하는 약 vs 오늘은 아닌 약(주 1회, 격일 등) 분리!
    final todayMeds = _state.medications.where((m) => m.isDueToday).toList();
    final otherMeds = _state.medications.where((m) => !m.isDueToday).toList();

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
            child: const Text(
              '새 복약 추가',
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => _showMedEditModal(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryPurple, width: 1.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.white,
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
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
        border: Border.all(color: AppColors.divider.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                  const Text(
                    '오늘 복약',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$total회 중 $completed회',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
              Text(
                '${(rate * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  // 1약 1카드 구조
  Widget _buildMedCard(MedicationItem med) {
    final isAllDone = med.isAllCompleted;
    final isSkipped = med.skipReason != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSkipped ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: med.isExpanded ? AppColors.primaryPurple.withOpacity(0.35) : AppColors.divider.withOpacity(0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
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
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 13, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    '이번 복용을 건너뛰었어요 · 다음 복용에 집중해요',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                          : (med.isPrescription ? AppColors.lightLavender : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication,
                      size: 19,
                      color: isAllDone
                          ? AppColors.successGreen
                          : (med.isPrescription ? AppColors.primaryPurple : AppColors.textSecondary),
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
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.lightLavender,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                med.recurrenceSummary,
                                style: const TextStyle(fontSize: 9.5, color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                med.durationSummary,
                                style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (med.isPrescription)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.warmBrown.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '처방',
                                  style: TextStyle(fontSize: 9.5, color: AppColors.warmBrown, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // 회차별 슬롯
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: med.doseSlots.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final slot = entry.value;
                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (!slot.isCompleted && !slot.isSkipped) {
                                    _state.completeSlot(med.id, idx);
                                    final toast = HagomDialogue.getRandomMedToast('${med.name} ${slot.label}');
                                    CelebrationToast.show(
                                      context,
                                      title: toast['title']!,
                                      message: toast['message']!,
                                    );
                                  } else {
                                    _showSlotActionSheet(med, idx, slot);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: slot.isCompleted
                                        ? AppColors.completedBg
                                        : (slot.isSkipped ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6)),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: slot.isCompleted
                                          ? AppColors.completedBorder
                                          : (slot.isSkipped ? AppColors.divider.withOpacity(0.3) : AppColors.divider),
                                    ),
                                  ),
                                  child: Text(
                                    slot.isSkipped
                                        ? '${slot.label} 건너뜀'
                                        : (slot.isCompleted
                                            ? '${slot.label} ${slot.takenTime?.split(' ').last ?? slot.scheduledTime?.split(' ').last ?? ''}'.trim()
                                            : '${slot.label} ${slot.scheduledTime?.split(' ').last ?? ''}'.trim()),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      fontWeight: slot.isCompleted ? FontWeight.bold : FontWeight.w500,
                                      color: slot.isCompleted
                                          ? AppColors.completedText
                                          : (slot.isSkipped ? AppColors.textMuted.withOpacity(0.6) : AppColors.textPrimary),
                                      decoration: slot.isSkipped ? TextDecoration.lineThrough : null, // 🌿 건너뛴 회차는 취소선 + 흐린 텍스트로 덜 눈에 띄게!
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 🔒 [우측 완전 고정 액션 버튼 (76x32dp)]:
                  GestureDetector(
                    onTap: () {
                      if (!isAllDone) {
                        _state.completeNextSlot(med.id);
                        final toast = HagomDialogue.getRandomMedToast(med.name);
                        CelebrationToast.show(
                          context,
                          title: toast['title']!,
                          message: toast['message']!,
                        );
                      } else {
                        // 이미 모든 회차가 완료된 상태에서 탭했을 때 토스트에서 바로 마지막 회차 되돌리기 지원!
                        CelebrationToast.show(
                          context,
                          title: '오늘 복용을 모두 마쳤어요 ✨',
                          message: '${med.name} 약을 이미 잘 챙겨 드셨어요.',
                          actionLabel: '되돌리기',
                          onAction: () {
                            _state.cancelLastCompletedSlot(med.id);
                            CelebrationToast.show(
                              context,
                              title: '복약 되돌림 🌿',
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
                          border: isAllDone ? Border.all(color: AppColors.completedBorder) : null,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showMedEditModal(med: med),
                    child: const Text('정보 수정', style: TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  if (med.completedSlotsCount > 0)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _state.revertMedication(med.id),
                      child: const Text('되돌리기', style: TextStyle(color: AppColors.warmBrown, fontSize: 12, fontWeight: FontWeight.w600)),
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
