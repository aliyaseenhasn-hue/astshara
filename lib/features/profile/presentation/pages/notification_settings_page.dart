import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/pwa_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  String _selectedSound = 'default';
  bool _pwaNotificationsEnabled = false;
  bool _pwaBusy = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    var pwaEnabled = prefs.getBool('pwa_notifications_enabled') ?? false;

    if (kIsWeb && PwaNotificationService.supported) {
      // The browser subscription is the source of truth. This also repairs
      // stale local preference state after reinstall/clearing site data.
      final browserEnabled = await PwaNotificationService.isEnabled();
      pwaEnabled = browserEnabled;
      await prefs.setBool('pwa_notifications_enabled', browserEnabled);
    }

    if (mounted) {
      setState(() {
        _selectedSound = prefs.getString('notification_sound') ?? 'default';
        _pwaNotificationsEnabled = pwaEnabled;
      });
    }
  }

  void _saveSound(String sound) {
    NotificationService.setNotificationSound(sound);
    setState(() => _selectedSound = sound);
    NotificationService.showNotification(title: 'تم تغيير النغمة', body: 'تم تطبيق نغمة الإشعارات الجديدة');
  }

  Future<void> _togglePwaNotifications(bool enabled) async {
    if (!kIsWeb || _pwaBusy) return;
    setState(() => _pwaBusy = true);
    try {
      final success = enabled
          ? await PwaNotificationService.enable()
          : await PwaNotificationService.disable();

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                enabled
                    ? 'تعذر تفعيل إشعارات الويب. إذا كان الإذن مرفوضاً من المتصفح، فعّله من إعدادات الموقع ثم أعد المحاولة.'
                    : 'تعذر إيقاف إشعارات الويب. حاول مرة أخرى.',
              ),
            ),
          );
        }
        return;
      }

      final browserEnabled = enabled && await PwaNotificationService.isEnabled();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pwa_notifications_enabled', browserEnabled);
      if (mounted) setState(() => _pwaNotificationsEnabled = browserEnabled);

      if (enabled && !browserEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يكتمل تفعيل إشعارات المتصفح. تحقق من إذن الإشعارات ثم أعد المحاولة.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إعداد إشعارات الويب. تحقق من إذن المتصفح ثم أعد المحاولة.')),
        );
      }
    } finally {
      if (mounted) setState(() => _pwaBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sounds = <({String label, String value})>[
      (label: 'الافتراضي', value: 'default'),
      (label: 'نغمة قانونية 1', value: 'legal_1'),
      (label: 'نغمة هادئة', value: 'calm'),
      (label: 'تنبيه عاجل', value: 'urgent'),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(title: const Text('إعدادات الإشعارات')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [scheme.primaryContainer, scheme.surfaceContainerHighest]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(17)), child: Icon(Icons.notifications_active_rounded, color: scheme.primary, size: 28)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('التنبيهات', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: scheme.onPrimaryContainer)),
                  const SizedBox(height: 5),
                  Text('خصص طريقة وصول التنبيهات إليك.', style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: .78), height: 1.45)),
                ])),
              ]),
            ),
            const SizedBox(height: 18),
            if (kIsWeb) ...[
              _SectionCard(
                title: 'إشعارات التطبيق على الهاتف',
                icon: Icons.phone_android_rounded,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _pwaNotificationsEnabled,
                  onChanged: _pwaBusy ? null : _togglePwaNotifications,
                  activeColor: scheme.onPrimary,
                  activeTrackColor: scheme.primary,
                  inactiveThumbColor: scheme.outline,
                  inactiveTrackColor: scheme.surfaceContainerHighest,
                  title: Row(children: [
                    Expanded(child: Text(_pwaNotificationsEnabled ? 'إشعارات PWA مفعّلة' : 'إشعارات PWA', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface))),
                    if (_pwaBusy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  ]),
                  subtitle: Text(_pwaNotificationsEnabled ? 'تم السماح بالإشعارات وتسجيل اشتراك هذا المتصفح.' : 'استقبال إشعارات الطلبات والرسائل حتى عند تشغيل التطبيق في الخلفية، حسب دعم المتصفح.', style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4)),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _SectionCard(title: 'نغمة التنبيه', icon: Icons.music_note_rounded, child: RadioGroup<String>(groupValue: _selectedSound, onChanged: (value) { if (value != null) _saveSound(value); }, child: Column(children: sounds.map((sound) => RadioListTile<String>(contentPadding: EdgeInsets.zero, activeColor: scheme.primary, title: Text(sound.label, style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface)), value: sound.value)).toList()))),
            const SizedBox(height: 14),
            _SectionCard(title: 'خيارات الجهاز', icon: Icons.phone_android_rounded, child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.vibration_rounded, color: scheme.primary), title: Text('الاهتزاز', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)), subtitle: Text('يتحكم به إعدادات الجهاز', style: TextStyle(color: scheme.onSurfaceVariant)), trailing: Icon(Icons.check_circle_rounded, color: scheme.primary))),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: scheme.outlineVariant)),
      child: Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 20, color: scheme.primary)), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: scheme.onSurface))]),
        const SizedBox(height: 8),
        child,
      ])),
    );
  }
}
