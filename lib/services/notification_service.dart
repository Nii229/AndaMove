// ============================================================
// AndaMove — Notification Service
// File: lib/services/notification_service.dart
//
// Wraps flutter_local_notifications for scheduling trip reminders.
// Call NotificationService.init() once from main.dart.
// Call NotificationService.scheduleTripReminder() when user
// confirms an upcoming trip.
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialised = false;

  // ── Initialise once from main.dart ──────────────────────
  static Future<void> init() async {
    if (_initialised) return;
    if (kIsWeb) {
      // flutter_local_notifications is not supported on web.
      _initialised = true;
      return;
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialised = true;
  }

  // ── Schedule a 15-minute-before reminder ────────────────
  static Future<void> scheduleTripReminder({
    required String tripId,
    required String tripName,
    required DateTime tripDate,
    required int startHour,
    required int startMinute,
  }) async {
    if (kIsWeb) return; // local notifications unsupported on web
    if (!_initialised) await init();

    final tripStart = tz.TZDateTime(
      tz.local,
      tripDate.year,
      tripDate.month,
      tripDate.day,
      startHour,
      startMinute,
    );

    final reminderTime = tripStart.subtract(const Duration(minutes: 15));

    final now = tz.TZDateTime.now(tz.local);
    if (reminderTime.isBefore(now)) return;

    final notifId = tripId.hashCode.abs() % 100000;

    const androidDetails = AndroidNotificationDetails(
      'trip_reminders',
      'Trip Reminders',
      channelDescription: 'Reminds you to leave for your trip',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id: notifId,
      title: '🌴 Time to head out!',
      body: '$tripName starts in 15 minutes. Have a great trip!',
      scheduledDate: reminderTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ── Cancel a previously scheduled reminder ───────────────
  static Future<void> cancelTripReminder(String tripId) async {
    if (kIsWeb || !_initialised) return;
    final notifId = tripId.hashCode.abs() % 100000;
    await _plugin.cancel(id: notifId);
  }

  // ── Cancel all scheduled reminders ───────────────────────
  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialised) return;
    await _plugin.cancelAll();
  }
}
