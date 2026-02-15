import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design/theme.dart';
import '../../services/roast_history_service.dart';

/// Screen showing all past roasts as flashcards.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<RoastEntry> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await RoastHistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppTheme.surfaceDark,
            flexibleSpace: FlexibleSpaceBar(
              title: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.accentLight, AppTheme.accentColor],
                ).createShader(bounds),
                child: const Text(
                  'Roast History',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              if (_history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Clear all',
                  onPressed: _confirmClear,
                ),
            ],
          ),

          // Content
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_history.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 64,
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No roasts yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate your first roast to see it here',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildRoastCard(index),
                  childCount: _history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoastCard(int index) {
    final entry = _history[index];
    final timeStr = _formatTime(entry.timestamp);
    final isNotification = entry.source == 'notification';

    return Dismissible(
      key: ValueKey('${entry.timestamp.toIso8601String()}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.destructive.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.destructive),
      ),
      onDismissed: (_) async {
        await RoastHistoryService.deleteRoast(index);
        _loadHistory();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: entry.text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Roast copied!'),
                  backgroundColor: AppTheme.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source badge + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isNotification
                              ? AppTheme.warning.withValues(alpha: 0.15)
                              : AppTheme.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNotification
                                  ? Icons.notifications_rounded
                                  : Icons.touch_app_rounded,
                              size: 12,
                              color: isNotification
                                  ? AppTheme.warning
                                  : AppTheme.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isNotification ? 'Reminder' : 'Manual',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isNotification
                                    ? AppTheme.warning
                                    : AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Roast text
                  Text(
                    entry.text,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (entry.provider != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'via ${entry.provider}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
          'This will delete all your roast history permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await RoastHistoryService.clearHistory();
              _loadHistory();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppTheme.destructive),
            ),
          ),
        ],
      ),
    );
  }
}
