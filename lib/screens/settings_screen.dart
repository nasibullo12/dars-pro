import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedSound = 'bell';
  double _volume = 0.7;
  bool _notifEnabled = true;
  String _selectedTheme = 'dark';

  final _sounds = {
    'bell': {'icon': '🔔', 'name': "Qo'ng'iroq", 'desc': 'Klassik signal'},
    'chime': {'icon': '🎵', 'name': 'Chime', 'desc': 'Yumshoq melodiya'},
    'beep': {'icon': '📳', 'name': 'Beep', 'desc': 'Oddiy signal'},
    'ding': {'icon': '✨', 'name': 'Ding', 'desc': 'Yumshoq ding'},
    'alert': {'icon': '🚨', 'name': 'Alert', 'desc': "E'tibor tortuvchi"},
    'soft': {'icon': '🌙', 'name': 'Yumshoq', 'desc': 'Sokin ovoz'},
  };

  final _themes = {
    'dark': {'icon': '🌑', 'name': 'Qorong\'u', 'desc': 'Default'},
    'midnight': {'icon': '🌌', 'name': 'Midnight', 'desc': 'Ko\'k-qora'},
    'forest': {'icon': '🌿', 'name': 'Forest', 'desc': 'Yashil'},
    'sunset': {'icon': '🌅', 'name': 'Sunset', 'desc': 'Issiq ranglar'},
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSound = prefs.getString('sound') ?? 'bell';
      _volume = prefs.getDouble('volume') ?? 0.7;
      _notifEnabled = prefs.getBool('notif') ?? true;
      _selectedTheme = prefs.getString('theme') ?? 'dark';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sound', _selectedSound);
    await prefs.setDouble('volume', _volume);
    await prefs.setBool('notif', _notifEnabled);
    await prefs.setString('theme', _selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications
          _sectionTitle('🔔 BILDIRISHNOMALAR'),
          _card(
            child: Column(
              children: [
                _switchRow("Bildirishnomalar", _notifEnabled, (v) async {
                  setState(() => _notifEnabled = v);
                  await _saveSettings();
                  if (v) {
                    await NotificationService().scheduleAllNotifications(DataService.students);
                  }
                }),
                const Divider(color: AppTheme.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Sinov bildirishnoma', style: TextStyle(fontWeight: FontWeight.w600))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orange.withOpacity(0.15),
                          foregroundColor: AppTheme.orange,
                          elevation: 0,
                        ),
                        onPressed: () => NotificationService().showInstant('⏰ Sinov', 'Dars Pro bildirishnomasi ishlayapti!'),
                        child: const Text('Sinab ko\'r'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sound
          _sectionTitle('🎵 OVOZ TANLASH'),
          ..._sounds.entries.map((e) {
            final key = e.key;
            final s = e.value;
            final isSelected = _selectedSound == key;
            return GestureDetector(
              onTap: () async {
                setState(() => _selectedSound = key);
                await _saveSettings();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? AppTheme.orange : Colors.transparent, width: 2),
                ),
                child: Row(
                  children: [
                    Text(s['icon']!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(s['desc']!, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('✓', style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Volume
          _sectionTitle('🔊 OVOZ BALANDLIGI'),
          _card(
            child: Row(
              children: [
                const Text('🔈'),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0,
                    max: 1,
                    activeColor: AppTheme.orange,
                    inactiveColor: AppTheme.surface2,
                    onChanged: (v) async {
                      setState(() => _volume = v);
                      await _saveSettings();
                    },
                  ),
                ),
                const Text('🔊'),
                const SizedBox(width: 8),
                Text('${(_volume * 100).round()}%', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Theme
          _sectionTitle('🎨 MAVZU (TEMA)'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: _themes.entries.map((e) {
              final key = e.key;
              final t = e.value;
              final isSelected = _selectedTheme == key;
              return GestureDetector(
                onTap: () async {
                  setState(() => _selectedTheme = key);
                  await _saveSettings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${t['name']} tanlandi — keyingi versiyada to'liq ishlaydi"),
                        backgroundColor: AppTheme.surface2,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppTheme.orange : Colors.transparent, width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(t['icon']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(t['desc']!, style: const TextStyle(color: AppTheme.muted, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // About
          _sectionTitle('ℹ️ DASTUR HAQIDA'),
          _card(
            child: Column(
              children: [
                _infoRow('Dastur nomi', 'Dars Pro'),
                const Divider(color: AppTheme.border),
                _infoRow('Versiya', '1.0.0'),
                const Divider(color: AppTheme.border),
                _infoRow("Shogirdlar soni", '${DataService.students.length} ta'),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text, style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
        child: child,
      );

  Widget _switchRow(String label, bool val, Function(bool) onChanged) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Switch(value: val, onChanged: onChanged),
        ],
      );

  Widget _infoRow(String label, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.muted)),
            Text(val, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
