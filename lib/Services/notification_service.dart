import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/course.dart';
import 'TimeConverter.dart';
import 'course_storage.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool get isSupported => !kIsWeb;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized || !isSupported) return;

    try {
      tz.initializeTimeZones();
      // usually utc is find as said that one stackoverflow user
      final String timeZoneName = 'UTC';
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      print('Notification initialization error (expected on web): $e');
      // Continue without notifications on unsupported platforms
    }
  }

  // Request notification permissions (especially for iOS)
  static Future<bool> requestPermissions() async {
    if (!isSupported) return false;

    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      return true;
    } catch (e) {
      print('Permission request error (expected on web): $e');
      return false;
    }
  }

  // Schedule notifications for a course
  static Future<void> scheduleCourseNotifications(Course course) async {
    if (!isSupported) return;

    try {
      await initialize();

      final isRamadanMode = await CourseStorage.isRamadanMode();
      final timeSlot = isRamadanMode && !course.isFriday()
          ? TimeConverter.convertToRamadan(course.timeSlot, course.isFriday())
          : course.timeSlot;

      final times = TimeConverter.parseTimeSlot(timeSlot);
      final startTime = times['start']!;

      // Schedule for each day of the week
      for (final day in course.days) {
        // 30 minutes before
        await _scheduleWeeklyNotification(
          id: '${course.id}_${day}_30'.hashCode,
          title: 'Class Starting Soon',
          body: '${course.name} starts in 30 minutes',
          day: day,
          time: startTime.subtract(const Duration(minutes: 30)),
        );

        // 15 minutes before
        await _scheduleWeeklyNotification(
          id: '${course.id}_${day}_15'.hashCode,
          title: 'Class Starting Very Soon',
          body: '${course.name} starts in 15 minutes',
          day: day,
          time: startTime.subtract(const Duration(minutes: 15)),
        );
      }
    } catch (e) {
      print('Error scheduling notifications (expected on web): $e');
    }
  }

  // Schedule a weekly notification
  static Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int day,
    required DateTime time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Adjust to the correct day of the week
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the time has passed today, schedule for next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'course_reminders',
          'Course Reminders',
          channelDescription: 'Notifications for upcoming classes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // Cancel notifications for a course
  static Future<void> cancelCourseNotifications(Course course) async {
    if (!isSupported) return;

    try {
      for (final day in course.days) {
        await _notifications.cancel('${course.id}_${day}_30'.hashCode);
        await _notifications.cancel('${course.id}_${day}_15'.hashCode);
      }
    } catch (e) {
      print('Error canceling notifications (expected on web): $e');
    }
  }

  // Reschedule all notifications (e.g., when Ramadan mode is toggled)
  static Future<void> rescheduleAllNotifications() async {
    if (!isSupported) {
      print('Notifications not supported on web');
      return;
    }

    try {
      final courses = await CourseStorage.loadCourses();

      // Cancel all existing notifications
      await _notifications.cancelAll();

      // Reschedule for all courses
      for (final course in courses) {
        await scheduleCourseNotifications(course);
      }
    } catch (e) {
      print('Error rescheduling notifications (expected on web): $e');
    }
  }
}
