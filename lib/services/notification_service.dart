import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../core/constants.dart';

/// Callback for handling notification taps.
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {}

/// Manages local scheduled notifications.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static final _random = Random();

  /// Stream controller for notification taps.
  static final StreamController<String?> _onNotificationTap =
      StreamController<String?>.broadcast();

  /// Stream of notification payloads.
  static Stream<String?> get onNotificationTap => _onNotificationTap.stream;

  static String? pendingPayload;

  /// Initialize the notification system.
  static Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        pendingPayload = response.payload;
        _onNotificationTap.add(response.payload);
      },
    );
  }

  /// Request notification permissions (Android 13+).
  static Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;

    final granted = await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();

    return granted ?? false;
  }

  /// Schedule daily reminders with actual roast texts.
  /// [roastTexts] should have the same length as [times], or null for fallback.
  static Future<void> scheduleReminders(
    List<TimeOfDay> times, {
    List<String>? roastTexts,
    String language = 'English',
  }) async {
    await _plugin.cancelAll();

    for (int i = 0; i < times.length; i++) {
      final time = times[i];
      final scheduledDate = _nextInstanceOfTime(time.hour, time.minute);

      // Use pre-generated roast text or fallback
      final body = (roastTexts != null && i < roastTexts.length)
          ? roastTexts[i]
          : getRandomFallback(language);

      await _plugin.zonedSchedule(
        i,
        AppConstants.notificationTitle,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            channelDescription: AppConstants.notificationChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: AppConstants.notificationTitle,
            ),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'roast_$i|$body',
      );
    }
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Get the next instance of the given time from now.
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Check and consume pending payload from notification tap.
  static String? consumePendingPayload() {
    final payload = pendingPayload;
    pendingPayload = null;
    return payload;
  }

  /// Get a random fallback message for offline mode.
  static String getRandomFallback(String language) {
    final fallbacks = language == 'Nepali'
        ? AppConstants.fallbackRoastsNepali
        : AppConstants.fallbackRoastsEnglish;
    return fallbacks[_random.nextInt(fallbacks.length)];
  }
}
