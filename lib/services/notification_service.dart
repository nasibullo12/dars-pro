import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/student.dart';
import 'data_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);

    // Request permissions
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleAllNotifications(List<Student> students) async {
    await _plugin.cancelAll();
    int id = 0;

    for (final student in students) {
      final schedule = DataService.getEffectiveSchedule(student);
      for (final sc in schedule) {
        final timeParts = sc.time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // Before lesson reminder
        final beforeMinute = minute - student.reminderMinutes;
        final beforeHour = beforeMinute < 0 ? hour - 1 : hour;
        final actualBeforeMinute = beforeMinute < 0 ? 60 + beforeMinute : beforeMinute;

        await _scheduleWeekly(
          id: id++,
          title: '⏰ Dars eslatmasi',
          body: '${student.name} — ${sc.time} da dars boshlanadi (${student.reminderMinutes} daqiqa qoldi)',
          weekday: sc.day + 1, // Flutter uses 1=Monday
          hour: beforeHour,
          minute: actualBeforeMinute,
        );

        // After lesson reminder (45 min after start)
        final afterMinute = (minute + 45) % 60;
        final afterHour = (hour + (minute + 45) ~/ 60) % 24;

        await _scheduleWeekly(
          id: id++,
          title: '📚 Dars tugadimi?',
          body: '${student.name} bilan dars o\'tdimi?',
          weekday: sc.day + 1,
          hour: afterHour,
          minute: afterMinute,
        );
      }
    }
  }

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = _nextWeekday(now, weekday, hour, minute);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'dars_pro_channel',
          'Dars Pro',
          channelDescription: 'Dars eslatmalari',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextWeekday(tz.TZDateTime from, int weekday, int hour, int minute) {
    var scheduled = tz.TZDateTime(tz.local, from.year, from.month, from.day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(from)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> showInstant(String title, String body) async {
    await _plugin.show(
      999,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dars_pro_channel',
          'Dars Pro',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }
}
