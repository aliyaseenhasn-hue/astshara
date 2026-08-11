import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  String _selectedSound = 'default';

  @override
  void initState() { super.initState(); _loadSettings(); }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _selectedSound = prefs.getString('notification_sound') ?? 'default');
  }

  void _saveSound(String sound) {
    NotificationService.setNotificationSound(sound);
    setState(() => _selectedSound = sound);
    NotificationService.showNotification(title: 'تم تغيير النغمة', body: 'تم تطبيق نغمة الإشعارات الجديدة');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sounds = [('الافتراضي','default'), ('نغمة قانونية 1','legal_1'), ('نغمة هادئة','calm'), ('تنبيه عاجل','urgent')];
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('إعدادات الإشعارات')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
        Text('التنبيهات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scheme.onSurface)),
        const SizedBox(height: 6),
        Text('خصص طريقة وصول التنبيهات إليك.', style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        _SectionCard(title: 'نغمة التنبيه', child: Column(children: sounds.map((sound) => RadioListTile<String>(contentPadding: EdgeInsets.zero, title: Text(sound.$1), value: sound.$2, groupValue: _selectedSound, onChanged: (value) { if (value != null) _saveSound(value); }, activeColor: scheme.primary)).toList())),
        const SizedBox(height: 16),
        _SectionCard(title: 'خيارات الجهاز', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.vibration_rounded, color: scheme.primary), title: const Text('الاهتزاز'), subtitle: Text('يتحكم به إعدادات الجهاز', style: TextStyle(color: scheme.onSurfaceVariant)), trailing: const Icon(Icons.check_circle_outline_rounded))),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(elevation: 0, color: scheme.surfaceContainerLowest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: scheme.outlineVariant)), child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)), const SizedBox(height: 6), child])));
  }
}
