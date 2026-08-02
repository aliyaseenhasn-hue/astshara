import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(
      {required String title, required String body}) async {
    // جلب نغمة الإشعار المختارة من الإعدادات المحلية
    final prefs = await SharedPreferences.getInstance();
    final soundType = prefs.getString('notification_sound') ?? 'default';

    // تشغيل الصوت المخصص إذا لم يكن افتراضياً
    if (soundType != 'default') {
      await _playCustomSound(soundType);
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'law_connect_channel',
      'إشعارات استشارة',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> _playCustomSound(String soundName) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$soundName.mp3'));
    } catch (e) {
      // إذا فشل تشغيل الصوت المخصص، سيعمل صوت النظام الافتراضي
    }
  }

  static Future<void> setNotificationSound(String soundName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', soundName);
  }
}
