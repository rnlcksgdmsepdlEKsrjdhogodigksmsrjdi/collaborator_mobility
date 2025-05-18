import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
      print('🔔 알림 초기화 함수 호출됨: ${DateTime.now()}');
    }
  }

  static Future<void> initialize() async {
    try {
      print('🕒 타임존 초기화 시작');
      tz.initializeTimeZones();
      print('✅ 타임존 초기화 완료');

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'reservation_channel',
        '예약 알림',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      );

      print('📢 알림 채널 생성 시작');
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      print('✅ 알림 채널 생성 완료');

      await _notificationsPlugin.initialize(settings);
      print('✅ 알림 초기화 완료');

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      print('❌ Notification initialization error: $e');
      rethrow;
    }
  }

  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    int id = 0,
  }) async {
    await _ensureInitialized();

    if (scheduledTime.isBefore(DateTime.now())) {
      print('⚠️ 예약 시간이 이미 지남: $scheduledTime');
      return;
    }

    try {
      print('📅 알림 예약 시작: $title - $scheduledTime');
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reservation_channel',
            '예약 알림',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('✅ 알림 예약 완료');
    } catch (e) {
      print('❌ Notification scheduling error: $e');
      rethrow;
    }
  }

  static Future<void> scheduleUserReservationReminders({
    required String userId,
    required String reservationDate,
    required String reservationTime,
    required String location,
  }) async {
    await _ensureInitialized();
    try {
      print('📌 예약 알림 스케줄링 시작');
      final dateParts = reservationDate.split('-');
      final timeParts = reservationTime.split(':');

      final reservationDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      await _scheduleSingleReminder(
        idSuffix: '${userId}_${reservationDate}_${reservationTime}_2h',
        title: '예약 2시간 전 알림',
        body: '$location 예약 시간이 2시간 남았습니다',
        triggerTime: reservationDateTime.subtract(const Duration(hours: 2)),
      );

      await _scheduleSingleReminder(
        idSuffix: '${userId}_${reservationDate}_${reservationTime}_30m',
        title: '예약 30분 전 알림',
        body: '$location 예약 시간이 30분 남았습니다',
        triggerTime: reservationDateTime.subtract(const Duration(minutes: 30)),
      );
      print('✅ 예약 알림 스케줄링 완료');
    } catch (e) {
      print('❌ Reservation reminder error: $e');
      rethrow;
    }
  }

  static Future<void> _scheduleSingleReminder({
    required String idSuffix,
    required String title,
    required String body,
    required DateTime triggerTime,
  }) async {
    await _ensureInitialized();

    if (triggerTime.isBefore(DateTime.now())) {
      print('⚠️ 트리거 시간이 이미 지남: $triggerTime');
      return;
    }

    try {
      print('📌 단일 알림 예약: $title - $triggerTime');
      await _notificationsPlugin.zonedSchedule(
        idSuffix.hashCode,
        title,
        body,
        tz.TZDateTime.from(triggerTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reservation_reminder_channel',
            '예약 알림',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      print('✅ 단일 알림 예약 완료');
    } catch (e) {
      print('❌ Single reminder scheduling error: $e');
      rethrow;
    }
  }

  static Future<void> cancelUserReservationReminders({
    required String userId,
    required String reservationDate,
    required String reservationTime,
  }) async {
    await _ensureInitialized();
    try {
      print('🗑️ 예약 알림 취소 시작');
      final id2h = '${reservationDate}_${reservationTime}_2h'.hashCode;
      final id30m = '${reservationDate}_${reservationTime}_30m'.hashCode;

      await _notificationsPlugin.cancel(id2h);
      await _notificationsPlugin.cancel(id30m);
      print('✅ 예약 알림 취소 완료');
    } catch (e) {
      print('❌ Notification cancellation error: $e');
      rethrow;
    }
  }
}
