import 'package:uuid/uuid.dart';

class Schedule {
  final int day; // 0=Monday, 6=Sunday
  final String time; // "09:00"

  Schedule({required this.day, required this.time});

  Map<String, dynamic> toJson() => {'day': day, 'time': time};

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      Schedule(day: json['day'], time: json['time']);
}

class AltSchedule {
  final int day;
  final String time;
  final bool enabled;

  AltSchedule({required this.day, required this.time, this.enabled = false});

  Map<String, dynamic> toJson() => {'day': day, 'time': time, 'enabled': enabled};

  factory AltSchedule.fromJson(Map<String, dynamic> json) =>
      AltSchedule(day: json['day'] ?? 0, time: json['time'] ?? '20:00', enabled: json['enabled'] ?? false);
}

class LessonHistory {
  final String date; // "2024-1-15"
  final String time;
  final String status; // 'done' or 'skipped'

  LessonHistory({required this.date, required this.time, required this.status});

  Map<String, dynamic> toJson() => {'date': date, 'time': time, 'status': status};

  factory LessonHistory.fromJson(Map<String, dynamic> json) =>
      LessonHistory(date: json['date'], time: json['time'], status: json['status']);
}

class Student {
  final String id;
  String name;
  List<Schedule> schedule;
  AltSchedule? altSchedule;
  int reminderMinutes;
  int pricePerLesson; // narx per dars
  int? monthlyPrice; // oylik narx
  String paymentType; // 'per_lesson' or 'monthly' or 'both'
  List<LessonHistory> history;
  String? telegramId;
  String? note;

  Student({
    String? id,
    required this.name,
    required this.schedule,
    this.altSchedule,
    this.reminderMinutes = 5,
    this.pricePerLesson = 0,
    this.monthlyPrice,
    this.paymentType = 'per_lesson',
    List<LessonHistory>? history,
    this.telegramId,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        history = history ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'schedule': schedule.map((s) => s.toJson()).toList(),
        'altSchedule': altSchedule?.toJson(),
        'reminderMinutes': reminderMinutes,
        'pricePerLesson': pricePerLesson,
        'monthlyPrice': monthlyPrice,
        'paymentType': paymentType,
        'history': history.map((h) => h.toJson()).toList(),
        'telegramId': telegramId,
        'note': note,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        name: json['name'],
        schedule: (json['schedule'] as List).map((s) => Schedule.fromJson(s)).toList(),
        altSchedule: json['altSchedule'] != null ? AltSchedule.fromJson(json['altSchedule']) : null,
        reminderMinutes: json['reminderMinutes'] ?? 5,
        pricePerLesson: json['pricePerLesson'] ?? 0,
        monthlyPrice: json['monthlyPrice'],
        paymentType: json['paymentType'] ?? 'per_lesson',
        history: (json['history'] as List).map((h) => LessonHistory.fromJson(h)).toList(),
        telegramId: json['telegramId'],
        note: json['note'],
      );

  String? getStatusForDate(String date, String time) {
    final h = history.where((h) => h.date == date && h.time == time).toList();
    return h.isNotEmpty ? h.first.status : null;
  }

  int getDoneCountForMonth(int year, int month) {
    return history.where((h) {
      final parts = h.date.split('-');
      return int.parse(parts[0]) == year && int.parse(parts[1]) == month && h.status == 'done';
    }).length;
  }

  int getSkippedCountForMonth(int year, int month) {
    return history.where((h) {
      final parts = h.date.split('-');
      return int.parse(parts[0]) == year && int.parse(parts[1]) == month && h.status == 'skipped';
    }).length;
  }
}
