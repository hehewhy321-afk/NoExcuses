import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../core/secure_storage.dart';
import '../../design/theme.dart';
import '../../design/motion.dart';
import '../../services/ai_service.dart';
import '../../services/roast_history_service.dart';
import '../../services/notification_service.dart';

/// Roast screen — shows AI-generated roasts as flashcards.
class RoastScreen extends StatefulWidget {
  final String? initialRoast;
  const RoastScreen({super.key, this.initialRoast});

  @override
  State<RoastScreen> createState() => _RoastScreenState();
}

class _RoastScreenState extends State<RoastScreen>
    with SingleTickerProviderStateMixin {
  String _roastText = '';
  String _displayText = '';
  bool _loading = false;
  bool _typing = false;
  String? _provider;
  Timer? _typeTimer;
  late AnimationController _cardController;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _cardScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: AppMotion.bounce),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: AppMotion.emphasizedDecelerate,
      ),
    );

    if (widget.initialRoast != null) {
      _showRoast(widget.initialRoast!, 'Notification');
      // Save notification roast to history when viewed
      _saveHistoryEntry(widget.initialRoast!, 'Notification', 'notification');
    } else {
      _generateRoast();
    }
  }

  Future<void> _saveHistoryEntry(
    String text,
    String? provider,
    String source,
  ) async {
    await RoastHistoryService.addRoast(
      text: text,
      provider: provider,
      source: source,
    );
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _generateRoast() async {
    setState(() {
      _loading = true;
      _roastText = '';
      _displayText = '';
      _typing = false;
    });

    _cardController.reset();

    final vibesRaw = await SecureStorage.read(AppConstants.keyVibes) ?? '';
    final vibes = vibesRaw.isNotEmpty
        ? vibesRaw.split(',')
        : ['procrastinator'];
    final language =
        await SecureStorage.read(AppConstants.keyLanguage) ?? 'English';

    final result = await AiService.generateRoast(vibes, language);

    if (!mounted) return;

    if (result.success) {
      await RoastHistoryService.addRoast(
        text: result.message,
        provider: result.provider,
        source: 'manual',
      );
      _showRoast(result.message, result.provider);
    } else if (result.isOffline) {
      final fallback = NotificationService.getRandomFallback(language);
      await RoastHistoryService.addRoast(
        text: fallback,
        provider: 'Offline',
        source: 'manual',
      );
      _showRoast(fallback, 'Offline');
    } else {
      setState(() {
        _loading = false;
        _roastText = result.message;
        _displayText = result.message;
      });
    }
  }

  void _showRoast(String text, String? provider) {
    setState(() {
      _loading = false;
      _roastText = text;
      _displayText = '';
      _provider = provider;
      _typing = true;
    });

    _cardController.forward();

    // Typewriter effect
    int charIndex = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(AppMotion.typewriter, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex < text.length) {
        setState(() {
          _displayText = text.substring(0, charIndex + 1);
        });
        charIndex++;
      } else {
        timer.cancel();
        setState(() => _typing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.accentLight, Color(0xFFEC4899)],
          ).createShader(bounds),
          child: const Text(
            'Reality Check',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),

              // Flashcard
              if (_loading) _buildLoadingCard() else _buildFlashcard(),

              const Spacer(),

              // Actions
              if (!_loading && _roastText.isNotEmpty && !_typing) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(Icons.copy_rounded, 'Copy', () {
                      Clipboard.setData(ClipboardData(text: _roastText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Copied! Now go share the pain 🔥',
                          ),
                          backgroundColor: AppTheme.surfaceElevated,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 16),
                    _buildActionButton(Icons.share_rounded, 'Share', () {
                      Clipboard.setData(ClipboardData(text: _roastText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Copied to clipboard for sharing!',
                          ),
                          backgroundColor: AppTheme.surfaceElevated,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Generate button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading || _typing ? null : _generateRoast,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _loading
                            ? Icons.hourglass_top_rounded
                            : Icons.local_fire_department_rounded,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _loading
                            ? 'Cooking your roast...'
                            : 'Generate Another 🔥',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlimited • No daily limit',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceCard, AppTheme.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppTheme.accentColor),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Summoning your roast...',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard() {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScale.value,
          child: Opacity(opacity: _cardOpacity.value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceCard,
              AppTheme.surfaceElevated,
              AppTheme.surfaceCard.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.15),
              blurRadius: 60,
              spreadRadius: -15,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Skull icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Text('💀', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 20),
            // Roast text
            Text(
              _displayText.isEmpty ? '...' : _displayText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
            if (_typing) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    AppTheme.accentColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
            if (!_typing && _provider != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Powered by $_provider',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentLight.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
