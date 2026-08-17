class PwaNotificationService {
  static bool get supported => false;

  static Future<bool> enable() async => false;

  static Future<bool> disable() async => true;
}
