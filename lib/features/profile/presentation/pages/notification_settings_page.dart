import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  String _selectedSound = 'default';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSound = prefs.getString('notification_sound') ?? 'default';
    });
  }

  void _saveSound(String sound) {
    NotificationService.setNotificationSound(sound);
    setState(() => _selectedSound = sound);

    // تجربة الصوت عند الاختيار
    NotificationService.showNotification(
      title: 'تم تغيير النغمة',
      body: 'سماع صوت الإشعارات الجديد',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الإشعارات')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.p20),
        children: [
          const Text('اختر نغمة التنبيه:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSoundTile('الافتراضي', 'default'),
          _buildSoundTile('نغمة قانونية 1', 'legal_1'),
          _buildSoundTile('نغمة هادئة', 'calm'),
          _buildSoundTile('تنبيه عاجل', 'urgent'),
          const Divider(height: 40),
          const ListTile(
            title: Text('الاهتزاز'),
            trailing: Switch(value: true, onChanged: null),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundTile(String title, String value) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      // ignore: deprecated_member_use
      groupValue: _selectedSound,
      // ignore: deprecated_member_use
      onChanged: (val) => val != null ? _saveSound(val) : null,
      activeColor: AppColors.primary,
    );
  }
}
