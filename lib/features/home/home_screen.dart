import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/secure_storage.dart';
import '../../design/theme.dart';
import '../../design/motion.dart';
import '../../services/roast_history_service.dart';
import '../roast/roast_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  List<String> _vibes = [];
  String _language = 'English';
  List<String> _reminderTimes = [];
  int _totalRoasts = 0;
  String? _lastRoast;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final vibes = await SecureStorage.readList(AppConstants.keyVibes);
    final language =
        await SecureStorage.read(AppConstants.keyLanguage) ?? 'English';
    final times = await SecureStorage.readList(AppConstants.keyReminderTimes);
    final total = await RoastHistoryService.totalRoasts();
    final history = await RoastHistoryService.getHistory();

    if (mounted) {
      setState(() {
        _vibes = vibes;
        _language = language;
        _reminderTimes = times;
        _totalRoasts = total;
        _lastRoast = history.isNotEmpty ? history.first.text : null;
      });
    }
  }

  String _getNextReminder() {
    if (_reminderTimes.isEmpty) return 'No reminders set';

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    TimeOfDay? next;
    int minDiff = 24 * 60;

    for (final timeStr in _reminderTimes) {
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final timeMinutes = h * 60 + m;

      int diff = timeMinutes - nowMinutes;
      if (diff <= 0) diff += 24 * 60;

      if (diff < minDiff) {
        minDiff = diff;
        next = TimeOfDay(hour: h, minute: m);
      }
    }

    if (next == null) return 'No reminders set';

    final hours = minDiff ~/ 60;
    final minutes = minDiff % 60;

    if (hours > 0) {
      return '${next.format(context)} (in ${hours}h ${minutes}m)';
    }
    return '${next.format(context)} (in ${minutes}m)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Header
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.accentLight, Color(0xFFEC4899)],
                ).createShader(bounds),
                child: Text(
                  'Reality Check',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your daily dose of brutal truth ☠️',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),

              const SizedBox(height: 28),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppTheme.warning,
                      label: 'TOTAL ROASTS',
                      value: '$_totalRoasts',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.notifications_active_rounded,
                      iconColor: AppTheme.success,
                      label: 'REMINDERS',
                      value: '${_reminderTimes.length} set',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Next Reminder Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.alarm_rounded,
                        color: AppTheme.warning,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEXT ROAST',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.textMuted,
                                  letterSpacing: 1,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _getNextReminder(),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Identity Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.surfaceCard,
                      AppTheme.accentColor.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.psychology_rounded,
                          color: AppTheme.accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'YOUR IDENTITY',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.accentColor,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _language,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.accentLight,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _vibes
                          .map(
                            (vibe) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                vibe,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.textPrimary),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),

              // Last Roast Preview
              if (_lastRoast != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.destructive.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('💀', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'LAST ROAST',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.textMuted,
                                  letterSpacing: 1,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _lastRoast!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Bottom RELOCATED: Generate Roast CTA
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Center(
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (c, a1, a2) => const RoastScreen(),
                          transitionsBuilder: AppMotion.buildPageTransition,
                          transitionDuration: AppMotion.medium,
                        ),
                      );
                      _loadData();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFFEC4899),
                            Color(0xFFF43F5E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.4),
                            blurRadius: 25,
                            spreadRadius: -5,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🔥', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 12),
                          Text(
                            'GENERATE ROAST',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.double_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
