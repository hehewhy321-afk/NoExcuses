import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/secure_storage.dart';
import '../../design/theme.dart';
import '../../design/motion.dart';
import '../../services/notification_service.dart';
import '../../services/convex_service.dart';
import '../../services/ai_service.dart';
import '../../core/device_id.dart';
import '../admin/admin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> _vibes = [];
  String _language = 'English';
  List<TimeOfDay> _reminderTimes = [];
  final _customVibeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _customVibeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final vibes = await SecureStorage.readList(AppConstants.keyVibes);
    final language =
        await SecureStorage.read(AppConstants.keyLanguage) ?? 'English';
    final timeStrs = await SecureStorage.readList(
      AppConstants.keyReminderTimes,
    );

    final times = timeStrs.map((t) {
      final parts = t.split(':');
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }).toList();

    if (times.isEmpty) {
      times.add(const TimeOfDay(hour: 9, minute: 0));
    }

    if (mounted) {
      setState(() {
        _vibes = vibes;
        _language = language;
        _reminderTimes = times;
      });
    }
  }

  Future<void> _save() async {
    // Save to local storage
    try {
      await SecureStorage.writeList(AppConstants.keyVibes, _vibes);
      await SecureStorage.write(AppConstants.keyLanguage, _language);
      await SecureStorage.writeList(
        AppConstants.keyReminderTimes,
        _reminderTimes
            .map(
              (t) =>
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
            )
            .toList(),
      );

      // Pre-generate AI roasts for notifications
      final List<String> roasts = [];
      for (int i = 0; i < _reminderTimes.length; i++) {
        try {
          // Generate a real roast for this time slot
          final result = await AiService.generateRoast(_vibes, _language);
          if (result.success) {
            roasts.add(result.message);
          } else {
            roasts.add(NotificationService.getRandomFallback(_language));
          }
        } catch (_) {
          roasts.add(NotificationService.getRandomFallback(_language));
        }
      }

      // Reschedule notifications with real roasts
      await NotificationService.scheduleReminders(
        _reminderTimes,
        roastTexts: roasts,
        language: _language,
      );

      // Backup to Convex
      final deviceId = await DeviceId.get();
      ConvexService.saveProfile(
        deviceId: deviceId,
        vibes: _vibes,
        language: _language,
        reminderTimes: _reminderTimes
            .map(
              (t) =>
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
            )
            .toList(),
      );
    } catch (_) {
      // Fail silently for auto-save
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vibes Section
          _buildSectionHeader('Your Vibes', Icons.local_fire_department),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._vibes.map(
                      (vibe) => Chip(
                        label: Text(vibe),
                        onDeleted: () {
                          setState(() => _vibes.remove(vibe));
                          _save();
                        },
                        deleteIconColor: AppTheme.textMuted,
                        backgroundColor: AppTheme.surfaceElevated,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customVibeController,
                        decoration: const InputDecoration(
                          hintText: 'Add vibe...',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addVibe(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addVibe,
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap suggested vibes to add:',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppConstants.suggestedVibes
                      .where((v) => !_vibes.contains(v))
                      .take(8)
                      .map(
                        (vibe) => GestureDetector(
                          onTap: () {
                            if (_vibes.length < AppConstants.maxVibes) {
                              setState(() => _vibes.add(vibe));
                              _save();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.textMuted.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '+ $vibe',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Language Section
          _buildSectionHeader('Language', Icons.language),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: RadioGroup<String>(
              groupValue: _language,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _language = v);
                  _save();
                }
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('🇺🇸 English'),
                    value: 'English',
                    activeColor: AppTheme.accentColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('🇳🇵 Nepali'),
                    value: 'Nepali',
                    activeColor: AppTheme.accentColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Reminder Times Section
          _buildSectionHeader('Reminder Times', Icons.alarm),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ...List.generate(_reminderTimes.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: AppTheme.accentColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _reminderTimes[i].format(context),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: AppTheme.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_reminderTimes.length > 1) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: AppTheme.destructive,
                            ),
                            onPressed: () {
                              setState(() => _reminderTimes.removeAt(i));
                              _save();
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (_reminderTimes.length < AppConstants.maxReminderTimes)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _reminderTimes.add(
                          const TimeOfDay(hour: 12, minute: 0),
                        );
                      });
                      _save();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Time'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // App Info
          Center(
            child: GestureDetector(
              onLongPress: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => const AdminScreen(),
                    transitionsBuilder: AppMotion.buildPageTransition,
                    transitionDuration: AppMotion.medium,
                  ),
                );
              },
              child: Column(
                children: [
                  Text(
                    'NoExcuses v1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Developed by Saif Ali',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'github.com/hehewhy321-afk',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Made with 🔥 for you',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  void _addVibe() {
    final text = _customVibeController.text.trim();
    if (text.isNotEmpty && _vibes.length < AppConstants.maxVibes) {
      setState(() {
        _vibes.add(text.toLowerCase());
        _customVibeController.clear();
      });
      _save();
    }
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (picked != null) {
      setState(() => _reminderTimes[index] = picked);
      _save();
    }
  }
}
