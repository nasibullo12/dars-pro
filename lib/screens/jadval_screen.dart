import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';

class JadvalScreen extends StatefulWidget {
  const JadvalScreen({super.key});

  @override
  State<JadvalScreen> createState() => _JadvalScreenState();
}

class _JadvalScreenState extends State<JadvalScreen> {
  late int _selDay;
  final _days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  final _fullDays = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];

  @override
  void initState() {
    super.initState();
    final d = DateTime.now().weekday - 1; // 0=Monday
    _selDay = d > 6 ? 6 : d;
    DataService.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DataService.removeListener(_refresh);
    super.dispose();
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  String _dateKeyForDay(int dayIndex) {
    final now = DateTime.now();
    final todayWeekday = now.weekday - 1;
    final diff = dayIndex - todayWeekday;
    final target = now.add(Duration(days: diff));
    return '${target.year}-${target.month}-${target.day}';
  }

  int _toMin(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday - 1;
    final lessons = DataService.getLessonsForDay(_selDay);
    final dateKey = _dateKeyForDay(_selDay);
    final oddWeek = DataService.isOddWeek();
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Day tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 7,
              itemBuilder: (ctx, i) {
                final cnt = DataService.getLessonsForDay(i).length;
                final isToday = i == today;
                final isSel = i == _selDay;
                return GestureDetector(
                  onTap: () => setState(() => _selDay = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.orange : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isToday && !isSel ? AppTheme.orange.withOpacity(0.4) : Colors.transparent),
                    ),
                    child: Text(
                      cnt > 0 && !isSel ? '${_days[i]} $cnt' : _days[i],
                      style: TextStyle(
                        color: isSel ? Colors.black : (cnt > 0 ? AppTheme.textColor : AppTheme.muted),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Today indicator
          if (_selDay == today)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'BUGUN — ${oddWeek ? "Toq" : "Juft"} hafta',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    _fullDays[_selDay].toUpperCase(),
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),

          // Lessons
          Expanded(
            child: lessons.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text('${_fullDays[_selDay]} uchun dars yo\'q',
                            style: const TextStyle(color: AppTheme.muted, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: lessons.length,
                    itemBuilder: (ctx, i) {
                      final entry = lessons[i];
                      final student = entry.key;
                      final time = entry.value;
                      final status = student.getStatusForDate(dateKey, time);
                      final diff = _toMin(time) - nowMin;
                      final isSoon = _selDay == today && status == null && diff <= student.reminderMinutes && diff >= 0;
                      final isDone = status == 'done';
                      final isSkip = status == 'skipped';
                      final hasAlt = student.altSchedule?.enabled == true;

                      String? subText;
                      Color subColor = AppTheme.muted;
                      if (_selDay == today && status == null) {
                        if (isSoon) {
                          subText = diff == 0 ? 'Hozir boshlanadi!' : '$diff daqiqada';
                          subColor = AppTheme.orange;
                        } else if (diff > 0 && diff < 120) {
                          subText = '$diff daqiqadan keyin';
                        }
                      } else if (isDone) {
                        final cnt = student.history.where((h) => h.status == 'done').length;
                        subText = "✓ O'tildi • Jami: $cnt ta";
                        subColor = AppTheme.green;
                      } else if (isSkip) {
                        subText = '✗ Qoldirildi';
                        subColor = AppTheme.red;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(
                            i == 0 ? 14 : i == lessons.length - 1 ? 14 : 4,
                          ),
                          border: Border(
                            left: BorderSide(
                              color: isDone ? AppTheme.green : isSkip ? AppTheme.red : isSoon ? AppTheme.orange : AppTheme.blue,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Opacity(
                          opacity: isDone || isSkip ? 0.5 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 56,
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -1,
                                      color: isDone || isSkip ? AppTheme.muted : AppTheme.textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              student.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                decoration: isDone ? TextDecoration.lineThrough : null,
                                                color: isDone || isSkip ? AppTheme.muted : AppTheme.textColor,
                                              ),
                                            ),
                                          ),
                                          if (hasAlt) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.blue.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                oddWeek ? 'Toq' : 'Juft',
                                                style: const TextStyle(color: AppTheme.blue, fontSize: 10, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (subText != null) ...[
                                        const SizedBox(height: 2),
                                        Text(subText, style: TextStyle(color: subColor, fontSize: 12)),
                                      ],
                                    ],
                                  ),
                                ),
                                // Toggle
                                Column(
                                  children: [
                                    Switch(
                                      value: isDone,
                                      onChanged: (_) => _toggleLesson(student, time, dateKey, status),
                                    ),
                                    Text(
                                      isDone ? "O'tildi" : isSkip ? 'Qoldi' : "O'tilmadi",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: isDone ? AppTheme.green : isSkip ? AppTheme.red : AppTheme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _toggleLesson(Student student, String time, String dateKey, String? currentStatus) {
    if (currentStatus == 'done' || currentStatus == 'skipped') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('↺ Qaytarish'),
          content: const Text("O'tilmagan deb belgilash?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor')),
            TextButton(
              onPressed: () {
                DataService.removeLessonStatus(student.id, dateKey, time);
                Navigator.pop(context);
              },
              child: const Text('Ha', style: TextStyle(color: AppTheme.orange)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('📚 ${student.name}'),
          content: Text('$time — dars holati?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor', style: TextStyle(color: AppTheme.muted))),
            TextButton(
              onPressed: () {
                DataService.setLessonStatus(student.id, dateKey, time, 'skipped');
                Navigator.pop(context);
              },
              child: const Text('✗ Qoldirildi', style: TextStyle(color: AppTheme.red)),
            ),
            TextButton(
              onPressed: () {
                DataService.setLessonStatus(student.id, dateKey, time, 'done');
                Navigator.pop(context);
              },
              child: const Text("✓ O'tildi", style: TextStyle(color: AppTheme.green)),
            ),
          ],
        ),
      );
    }
  }
}
