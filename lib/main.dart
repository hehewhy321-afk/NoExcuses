import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/secure_storage.dart';
import 'core/constants.dart';
import 'design/theme.dart';
import 'services/notification_service.dart';
import 'services/ai_service.dart';
import 'services/convex_service.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/app_shell.dart';
import 'features/roast/roast_screen.dart';
import 'design/motion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // System UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize notifications
  await NotificationService.init();

  // Check if onboarded
  final onboarded = await SecureStorage.readBool(AppConstants.keyOnboarded);

  runApp(ProviderScope(child: RealityCheckApp(initiallyOnboarded: onboarded)));
}

class RealityCheckApp extends StatefulWidget {
  final bool initiallyOnboarded;
  const RealityCheckApp({super.key, required this.initiallyOnboarded});

  @override
  State<RealityCheckApp> createState() => _RealityCheckAppState();
}

class _RealityCheckAppState extends State<RealityCheckApp> {
  late bool _onboarded;
  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();
    _onboarded = widget.initiallyOnboarded;

    if (_onboarded) {
      // Pre-generate roasts for scheduled notifications
      _preGenerateRoasts();
    }

    // Check if app was opened from a notification (cold start)
    _checkNotificationLaunch();

    // Listen for notification taps while app is running
    _notificationSub = NotificationService.onNotificationTap.listen((payload) {
      if (payload != null && mounted) {
        _handleNotificationPayload(payload);
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  /// Pre-generate roasts for all scheduled reminder times.
  /// Runs once per day to populate notifications with actual roast content.
  Future<void> _preGenerateRoasts() async {
    // Load dynamic max reminder times from Convex
    try {
      final maxRemResult = await ConvexService.getConfig('max_reminder_times');
      final maxRem = int.tryParse(maxRemResult?['value']?.toString() ?? '');
      if (maxRem != null) AppConstants.maxReminderTimes = maxRem;
    } catch (_) {}

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastPregenDate = await SecureStorage.read(
      AppConstants.keyLastPregenDate,
    );

    if (lastPregenDate == today) return; // Already done today

    try {
      final vibesRaw = await SecureStorage.read(AppConstants.keyVibes) ?? '';
      final vibes = vibesRaw.isNotEmpty
          ? vibesRaw.split(',')
          : ['procrastinator'];
      final language =
          await SecureStorage.read(AppConstants.keyLanguage) ?? 'English';
      final timeStrs = await SecureStorage.readList(
        AppConstants.keyReminderTimes,
      );

      if (timeStrs.isEmpty) return;

      final List<String> roastTexts = [];

      for (int i = 0; i < timeStrs.length; i++) {
        final result = await AiService.generateRoast(
          vibes,
          language,
          source: 'reminder',
        );

        if (result.success) {
          roastTexts.add(result.message);
        } else {
          roastTexts.add(NotificationService.getRandomFallback(language));
        }
      }

      // Parse times and reschedule notifications with actual roast content
      final times = timeStrs.map((t) {
        final parts = t.split(':');
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }).toList();

      await NotificationService.scheduleReminders(
        times,
        roastTexts: roastTexts,
        language: language,
      );

      // Save pre-gen date and roasts
      await SecureStorage.write(AppConstants.keyLastPregenDate, today);
      await SecureStorage.write(
        AppConstants.keyPregenRoasts,
        jsonEncode(roastTexts),
      );
    } catch (_) {
      // Fail silently — notifications will use fallback text
    }
  }

  Future<void> _checkNotificationLaunch() async {
    final rawPayload = NotificationService.consumePendingPayload();
    if (rawPayload != null && _onboarded && mounted) {
      _handleNotificationPayload(rawPayload);
    }
  }

  void _handleNotificationPayload(String rawPayload) {
    if (!_onboarded) return;

    // Payload format: "roast_i|Actual Roast Text"
    String roastText = rawPayload;
    if (rawPayload.contains('|')) {
      roastText = rawPayload.split('|').last;
    }

    // Navigate to roast screen
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (c, a1, a2) => RoastScreen(initialRoast: roastText),
            transitionsBuilder: AppMotion.buildPageTransition,
            transitionDuration: AppMotion.medium,
          ),
        );
      }
    });
  }

  void _completeOnboarding() {
    setState(() => _onboarded = true);
    _preGenerateRoasts();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reality Check',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _onboarded
          ? const AppShell()
          : OnboardingScreen(onComplete: _completeOnboarding),
    );
  }
}
