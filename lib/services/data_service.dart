import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';

class DataService {
  static const String _key = 'dars_pro_students_v2';
  static List<Student> _students = [];
  static List<Function()> _listeners = [];

  static void addListener(Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  static void _notify() {
    for (final l in _listeners) l();
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final list = jsonDecode(data) as List;
      _students = list.map((s) => Student.fromJson(s)).toList();
    }
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_students.map((s) => s.toJson()).toList());
    await prefs.setString(_key, data);
  }

  static List<Student> get students => List.unmodifiable(_students);

  static Future<void> addStudent(Student student) async {
    _students.add(student);
    await _save();
    _notify();
  }

  static Future<void> updateStudent(Student student) async {
    final idx = _students.indexWhere((s) => s.id == student.id);
    if (idx >= 0) {
      _students[idx] = student;
      await _save();
      _notify();
    }
  }

  static Future<void> deleteStudent(String id) async {
    _students.removeWhere((s) => s.id == id);
    await _save();
    _notify();
  }

  static Future<void> setLessonStatus(String studentId, String date, String time, String status) async {
    final s = _students.firstWhere((s) => s.id == studentId);
    s.history.removeWhere((h) => h.date == date && h.time == time);
    s.history.add(LessonHistory(date: date, time: time, status: status));
    await _save();
    _notify();
  }

  static Future<void> removeLessonStatus(String studentId, String date, String time) async {
    final s = _students.firstWhere((s) => s.id == studentId);
    s.history.removeWhere((h) => h.date == date && h.time == time);
    await _save();
    _notify();
  }

  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  static int getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays;
    return ((dayOfYear + startOfYear.weekday - 1) / 7).ceil();
  }

  static bool isOddWeek() {
    return getWeekNumber(DateTime.now()) % 2 == 1;
  }

  static List<Schedule> getEffectiveSchedule(Student student) {
    final alt = student.altSchedule;
    if (alt == null || !alt.enabled) return student.schedule;
    if (isOddWeek()) {
      final result = List<Schedule>.from(student.schedule);
      if (result.isNotEmpty) {
        result[0] = Schedule(day: alt.day, time: alt.time);
      }
      return result;
    }
    return student.schedule;
  }

  static List<MapEntry<Student, String>> getLessonsForDay(int dayIndex) {
    final result = <MapEntry<Student, String>>[];
    for (final s in _students) {
      for (final sc in getEffectiveSchedule(s)) {
        if (sc.day == dayIndex) {
          result.add(MapEntry(s, sc.time));
        }
      }
    }
    result.sort((a, b) => a.value.compareTo(b.value));
    return result;
  }
}
