import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _waterReminderTask = 'water_reminder';
const String _vitalCheckTask = 'vital_check';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case _waterReminderTask:
        await NotificationService.showWaterReminder();
        break;
      case _vitalCheckTask:
        await NotificationService.showVitalCheckReminder();
        break;
    }
    return Future.value(true);
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _criticalDetails =
      AndroidNotificationDetails(
    'vitalsense_critical',
    'Critical Health Alerts',
    channelDescription: 'Urgent health alerts requiring immediate attention',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    color: Color(0xFFEF4444),
  );

  static const AndroidNotificationDetails _generalDetails =
      AndroidNotificationDetails(
    'vitalsense_general',
    'Health Notifications',
    channelDescription: 'General health reminders and updates',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const AndroidNotificationDetails _waterDetails =
      AndroidNotificationDetails(
    'vitalsense_water',
    'Water Reminders',
    channelDescription: 'Hydration reminders',
    importance: Importance.low,
    priority: Priority.low,
  );

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: iOS),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    await Workmanager().registerPeriodicTask(
      _waterReminderTask,
      _waterReminderTask,
      frequency: const Duration(hours: 5),
      constraints: Constraints(networkType: NetworkType.not_required),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {}

  static Future<void> showCriticalAlert({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _notifications.show(
      id, title, body,
      const NotificationDetails(android: _criticalDetails),
    );
  }

  static Future<void> showWarningAlert({
    required String title,
    required String body,
    int id = 1,
  }) async {
    await _notifications.show(
      id, title, body,
      const NotificationDetails(android: _generalDetails),
    );
  }

  static Future<void> showWaterReminder() async {
    await _notifications.show(
      100,
      '💧 Time to Hydrate!',
      'You haven\'t had water in a while. Drink at least one glass of water now.',
      const NotificationDetails(android: _waterDetails),
    );
  }

  static Future<void> showVitalCheckReminder() async {
    await _notifications.show(
      101,
      '🫀 VitalSense Check-In',
      'Your vitals haven\'t been monitored recently. Tap to check your health status.',
      const NotificationDetails(android: _generalDetails),
    );
  }

  static Future<void> showSOSReceived(String senderName) async {
    await _notifications.show(
      200,
      '🆘 Emergency SOS Nearby!',
      '$senderName needs immediate help! Check the VitalSense app now.',
      const NotificationDetails(android: _criticalDetails),
    );
  }

  static Future<void> showPeriodReminder(int daysUntil) async {
    await _notifications.show(
      300,
      '🌸 Period Reminder',
      daysUntil == 0
          ? 'Your period may start today. Stay prepared!'
          : 'Your period is expected in $daysUntil days.',
      const NotificationDetails(android: _generalDetails),
    );
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
