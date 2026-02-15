import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/device_id.dart';
import '../../core/secure_storage.dart';
import '../../design/theme.dart';
import '../../design/motion.dart';
import '../../services/notification_service.dart';
import '../../services/convex_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Vibes
  final Set<String> _selectedVibes = {};
  final _customVibeController = TextEditingController();

  // Language
  String _language = 'English';

  // Reminder times
  final List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];

  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _customVibeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: AppMotion.medium,
        curve: AppMotion.emphasizedDecelerate,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: AppMotion.medium,
        curve: AppMotion.emphasizedDecelerate,
      );
    }
  }

  Future<void> _complete() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      // Request notification permissions
      await NotificationService.requestPermissions();

      // Save to secure storage
      await SecureStorage.writeList(
        AppConstants.keyVibes,
        _selectedVibes.toList(),
      );
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
      await SecureStorage.writeBool(AppConstants.keyOnboarded, true);

      // Schedule notifications
      await NotificationService.scheduleReminders(_reminderTimes);

      // Backup to Convex (fire & forget)
      final deviceId = await DeviceId.get();
      ConvexService.saveProfile(
        deviceId: deviceId,
        vibes: _selectedVibes.toList(),
        language: _language,
        reminderTimes: _reminderTimes
            .map(
              (t) =>
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
            )
            .toList(),
      );

      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Setup failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index <= _currentPage
                            ? AppTheme.accentColor
                            : AppTheme.surfaceElevated,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildVibesPage(),
                  _buildLanguagePage(),
                  _buildReminderPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PAGE 0: Welcome
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Skull emoji with glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentColor.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Center(
              child: Text('💀', style: TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Reality Check',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            'Your AI mentor that doesn\'t sugarcoat.\nBrutal honesty. Real growth.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Let\'s Go'),
            ),
          ),
        ],
      ),
    );
  }

  // PAGE 1: Vibes
  Widget _buildVibesPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Define Your Vibes',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Who are you? Pick your identities so we can roast you properly.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Suggested vibes chips
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...AppConstants.suggestedVibes.map((vibe) {
                        final selected = _selectedVibes.contains(vibe);
                        return FilterChip(
                          label: Text(vibe),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                if (_selectedVibes.length <
                                    AppConstants.maxVibes) {
                                  _selectedVibes.add(vibe);
                                }
                              } else {
                                _selectedVibes.remove(vibe);
                              }
                            });
                          },
                          selectedColor: AppTheme.accentColor.withValues(
                            alpha: 0.3,
                          ),
                          checkmarkColor: AppTheme.accentLight,
                          avatar: selected ? null : null,
                        );
                      }),
                      // Custom vibes
                      ..._selectedVibes
                          .where(
                            (v) => !AppConstants.suggestedVibes.contains(v),
                          )
                          .map((vibe) {
                            return FilterChip(
                              label: Text(vibe),
                              selected: true,
                              onSelected: (_) {
                                setState(() => _selectedVibes.remove(vibe));
                              },
                              selectedColor: AppTheme.accentColor.withValues(
                                alpha: 0.3,
                              ),
                              checkmarkColor: AppTheme.accentLight,
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() => _selectedVibes.remove(vibe));
                              },
                            );
                          }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Custom vibe input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customVibeController,
                          decoration: const InputDecoration(
                            hintText: 'Add custom vibe...',
                          ),
                          onSubmitted: (_) => _addCustomVibe(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addCustomVibe,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppTheme.accentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom actions
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                TextButton(onPressed: _previousPage, child: const Text('Back')),
                const Spacer(),
                Text(
                  '${_selectedVibes.length}/${AppConstants.maxVibes}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedVibes.isNotEmpty ? _nextPage : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addCustomVibe() {
    final text = _customVibeController.text.trim();
    if (text.isNotEmpty && _selectedVibes.length < AppConstants.maxVibes) {
      setState(() {
        _selectedVibes.add(text.toLowerCase());
        _customVibeController.clear();
      });
    }
  }

  // PAGE 2: Language
  Widget _buildLanguagePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Choose Language',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Which language should we roast you in?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 48),

          _buildLanguageOption('English', '🇺🇸', 'Get roasted in English'),
          const SizedBox(height: 16),
          _buildLanguageOption('Nepali', '🇳🇵', 'नेपालीमा roast पाउनुहोस्'),

          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: _previousPage, child: const Text('Back')),
              ElevatedButton(onPressed: _nextPage, child: const Text('Next')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String lang, String emoji, String subtitle) {
    final selected = _language == lang;
    return GestureDetector(
      onTap: () => setState(() => _language = lang),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? AppTheme.accentColor.withValues(alpha: 0.15)
              : AppTheme.surfaceCard,
          border: Border.all(
            color: selected ? AppTheme.accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.accentColor),
          ],
        ),
      ),
    );
  }

  // PAGE 3: Reminders
  Widget _buildReminderPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Set Reminders',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'When should we hit you with reality? (1-3 times daily)',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          // Reminder time cards
          Expanded(
            child: ListView(
              children: [
                ...List.generate(_reminderTimes.length, (index) {
                  final time = _reminderTimes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.alarm,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        title: Text(
                          time.format(context),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppTheme.textPrimary),
                        ),
                        subtitle: Text(
                          'Reminder ${index + 1}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () => _pickTime(index),
                            ),
                            if (_reminderTimes.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppTheme.destructive,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _reminderTimes.removeAt(index),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Add reminder button
                if (_reminderTimes.length < AppConstants.maxReminderTimes)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _reminderTimes.add(
                            const TimeOfDay(hour: 12, minute: 0),
                          );
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Reminder'),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom actions
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                TextButton(onPressed: _previousPage, child: const Text('Back')),
                const Spacer(),
                ElevatedButton(
                  onPressed: _saving ? null : _complete,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Start Getting Roasted'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (picked != null) {
      setState(() => _reminderTimes[index] = picked);
    }
  }
}
