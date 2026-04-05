import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_colors.dart';

class SafetyPrefsScreen extends StatefulWidget {
  const SafetyPrefsScreen({super.key});

  @override
  State<SafetyPrefsScreen> createState() => _SafetyPrefsScreenState();
}

class _SafetyPrefsScreenState extends State<SafetyPrefsScreen> {
  bool _silentSos = false;
  bool _confirmBeforeSend = true;
  bool _recordAudio = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _silentSos = prefs.getBool('silentSos') ?? false;
      _confirmBeforeSend = prefs.getBool('confirmBeforeSend') ?? true;
      _recordAudio = prefs.getBool('recordAudio') ?? true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Preferences')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Alert Behavior',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_off_outlined),
                    title: const Text('Silent SOS'),
                    subtitle: const Text('Send alerts without visual feedback'),
                    value: _silentSos,
                    onChanged: (value) {
                      setState(() => _silentSos = value);
                      _saveBool('silentSos', value);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.timer_outlined),
                    title: const Text('Confirmation Delay'),
                    subtitle: const Text('Add a 3-second delay before sending'),
                    value: _confirmBeforeSend,
                    onChanged: (value) {
                      setState(() => _confirmBeforeSend = value);
                      _saveBool('confirmBeforeSend', value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recording',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.mic_none_rounded),
                title: const Text('Record Audio'),
                subtitle: const Text('Automatically record 20s of audio when SOS is triggered'),
                value: _recordAudio,
                onChanged: (value) {
                  setState(() => _recordAudio = value);
                  _saveBool('recordAudio', value);
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Audio recordings are securely uploaded and only accessible to your emergency contacts.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
