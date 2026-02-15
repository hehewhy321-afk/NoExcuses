import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/secure_storage.dart';
import '../../design/theme.dart';
import '../../services/convex_service.dart';

/// Admin screen — manage API keys, limits, and view stats.
/// Requires email/password login via Convex.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _authenticated = false;
  bool _loginLoading = false;
  String _loginError = '';

  // Login fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Admin fields
  final _groqKeyController = TextEditingController();
  final _cerebrasKeyController = TextEditingController();
  final _groqModelController = TextEditingController();
  final _cerebrasModelController = TextEditingController();
  String _primaryProvider = 'groq';
  int _maxReminderTimes = 3;
  bool _loadingConfig = true;

  // Stats
  int _totalUsers = 0;
  int _totalDevices = 0;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _groqKeyController.dispose();
    _cerebrasKeyController.dispose();
    _groqModelController.dispose();
    _cerebrasModelController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    final savedEmail = await SecureStorage.read(AppConstants.keyAdminEmail);
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() => _authenticated = true);
      _loadAdminData();
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _loginError = 'Enter email and password');
      return;
    }

    setState(() {
      _loginLoading = true;
      _loginError = '';
    });

    try {
      final result = await ConvexService.mutation('adminAuth:login', {
        'email': email,
        'password': password,
      });

      if (result != null && result['value']?['success'] == true) {
        await SecureStorage.write(AppConstants.keyAdminEmail, email);
        setState(() {
          _authenticated = true;
          _loginLoading = false;
        });
        _loadAdminData();
      } else {
        setState(() {
          _loginError = result?['value']?['error'] ?? 'Invalid credentials';
          _loginLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loginError = 'Connection failed. Check your internet.';
        _loginLoading = false;
      });
    }
  }

  Future<void> _loadAdminData() async {
    setState(() => _loadingConfig = true);

    try {
      // 1. Load from local cache first for instant feedback
      final cachedGroq = await SecureStorage.read(AppConstants.keyGroqApiKey);
      final cachedCerebras = await SecureStorage.read(
        AppConstants.keyCerebrasApiKey,
      );
      final cachedProvider = await SecureStorage.read(
        AppConstants.keyPrimaryAiProvider,
      );
      final cachedMaxRem = await SecureStorage.read('max_reminder_times');

      final cachedGroqModel =
          await SecureStorage.read(AppConstants.keyGroqModel) ??
          AppConstants.defaultGroqModel;
      final cachedCerebrasModel =
          await SecureStorage.read(AppConstants.keyCerebrasModel) ??
          AppConstants.defaultCerebrasModel;

      if (mounted) {
        setState(() {
          _groqKeyController.text = cachedGroq ?? '';
          _cerebrasKeyController.text = cachedCerebras ?? '';
          _groqModelController.text = cachedGroqModel;
          _cerebrasModelController.text = cachedCerebrasModel;
          _primaryProvider = cachedProvider ?? 'groq';
          _maxReminderTimes = int.tryParse(cachedMaxRem ?? '3') ?? 3;
        });
      }

      // 2. Load from Convex in a single batch call
      final configResult = await ConvexService.getAllConfigs();
      final statsResult = await ConvexService.getStats();

      if (mounted && configResult != null) {
        final configs = configResult['value'] as Map<String, dynamic>? ?? {};
        setState(() {
          if (configs.containsKey('groq_api_key')) {
            _groqKeyController.text = configs['groq_api_key'].toString();
          }
          if (configs.containsKey('cerebras_api_key')) {
            _cerebrasKeyController.text = configs['cerebras_api_key']
                .toString();
          }
          if (configs.containsKey('primary_ai_provider')) {
            _primaryProvider = configs['primary_ai_provider'].toString();
          }
          if (configs.containsKey('groq_model')) {
            _groqModelController.text = configs['groq_model'].toString();
          }
          if (configs.containsKey('cerebras_model')) {
            _cerebrasModelController.text = configs['cerebras_model']
                .toString();
          }
          if (configs.containsKey('max_reminder_times')) {
            _maxReminderTimes =
                int.tryParse(configs['max_reminder_times'].toString()) ?? 3;
          }

          final stats = statsResult?['value'] as Map<String, dynamic>? ?? {};
          _totalUsers = stats['totalUsers'] ?? 0;
          _totalDevices = stats['totalDevices'] ?? 0;
          _loadingConfig = false;
        });

        // Update local cache with fresh values from server
        _updateLocalCache();
      } else {
        if (mounted) setState(() => _loadingConfig = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingConfig = false);
    }
  }

  Future<void> _updateLocalCache() async {
    await SecureStorage.write(
      AppConstants.keyGroqApiKey,
      _groqKeyController.text,
    );
    await SecureStorage.write(
      AppConstants.keyCerebrasApiKey,
      _cerebrasKeyController.text,
    );
    await SecureStorage.write(
      AppConstants.keyGroqModel,
      _groqModelController.text,
    );
    await SecureStorage.write(
      AppConstants.keyCerebrasModel,
      _cerebrasModelController.text,
    );
    await SecureStorage.write(
      AppConstants.keyPrimaryAiProvider,
      _primaryProvider,
    );
    await SecureStorage.write(
      AppConstants.keyMaxReminderTimes,
      _maxReminderTimes.toString(),
    );
    // Force cache refresh by setting timestamp to 0
    await SecureStorage.write(AppConstants.keyCachedKeysTime, '0');
  }

  Future<void> _saveConfig(String key, String value) async {
    await ConvexService.setConfig(key, value);
    // Also update local cache immediately
    if (key == 'groq_api_key') {
      await SecureStorage.write(AppConstants.keyGroqApiKey, value);
    } else if (key == 'cerebras_api_key') {
      await SecureStorage.write(AppConstants.keyCerebrasApiKey, value);
    } else if (key == 'primary_ai_provider') {
      await SecureStorage.write(AppConstants.keyPrimaryAiProvider, value);
    } else if (key == AppConstants.keyMaxReminderTimes) {
      await SecureStorage.write(AppConstants.keyMaxReminderTimes, value);
    }

    // Force cache refresh
    await SecureStorage.write(AppConstants.keyCachedKeysTime, '0');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$key saved!'),
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _logout() async {
    await SecureStorage.delete(AppConstants.keyAdminEmail);
    setState(() => _authenticated = false);
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.accentLight, AppTheme.warning],
          ).createShader(bounds),
          child: const Text(
            'Admin Panel',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_authenticated)
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
            ),
        ],
      ),
      body: _authenticated ? _buildAdminPanel() : _buildLoginForm(),
    );
  }

  Widget _buildLoginForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                size: 48,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Admin Login',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with your admin credentials',
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 32),

            // Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock_outline, size: 20),
              ),
              onSubmitted: (_) => _login(),
            ),

            if (_loginError.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.destructive,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loginError,
                        style: const TextStyle(
                          color: AppTheme.destructive,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loginLoading ? null : _login,
                child: _loginLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPanel() {
    if (_loadingConfig) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  Icons.people_rounded,
                  'Users',
                  '$_totalUsers',
                  AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  Icons.devices_rounded,
                  'Devices',
                  '$_totalDevices',
                  AppTheme.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // API Keys Section
          _buildSectionTitle('API Keys', Icons.key_rounded),
          const SizedBox(height: 12),

          // Groq
          _buildKeyField(
            label: 'Groq API Key',
            controller: _groqKeyController,
            onSave: () => _saveConfig('groq_api_key', _groqKeyController.text),
          ),
          const SizedBox(height: 12),

          // Cerebras
          _buildKeyField(
            label: 'Cerebras API Key',
            controller: _cerebrasKeyController,
            onSave: () =>
                _saveConfig('cerebras_api_key', _cerebrasKeyController.text),
          ),

          const SizedBox(height: 24),

          // Models Section
          _buildSectionTitle('AI Models', Icons.smart_toy_rounded),
          const SizedBox(height: 12),

          _buildKeyField(
            label: 'Groq Model',
            hint: AppConstants.defaultGroqModel,
            controller: _groqModelController,
            obscure: false,
            onSave: () => _saveConfig('groq_model', _groqModelController.text),
          ),
          const SizedBox(height: 12),
          _buildKeyField(
            label: 'Cerebras Model',
            hint: AppConstants.defaultCerebrasModel,
            controller: _cerebrasModelController,
            obscure: false,
            onSave: () =>
                _saveConfig('cerebras_model', _cerebrasModelController.text),
          ),

          const SizedBox(height: 24),

          // Provider Selection
          _buildSectionTitle('Primary Provider', Icons.auto_awesome_rounded),
          const SizedBox(height: 12),
          _buildProviderSelector(),

          const SizedBox(height: 24),

          // Reminder Limits
          _buildSectionTitle('Reminder Limits', Icons.alarm_rounded),
          const SizedBox(height: 12),
          _buildReminderLimitControl(),

          const SizedBox(height: 32),

          // Save All
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saveAll,
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Save All Settings',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onSave,
    String? hint,
    bool obscure = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: hint ?? 'Enter value',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onSave,
                icon: const Icon(Icons.save_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.accentColor.withValues(alpha: 0.15),
                  foregroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _buildProviderChip('Groq', 'groq')),
          const SizedBox(width: 12),
          Expanded(child: _buildProviderChip('Cerebras', 'cerebras')),
        ],
      ),
    );
  }

  Widget _buildProviderChip(String label, String value) {
    final isSelected = _primaryProvider == value;
    return GestureDetector(
      onTap: () => setState(() => _primaryProvider = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withValues(alpha: 0.2)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.accentLight : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderLimitControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Max Reminder Times',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              Text(
                '$_maxReminderTimes',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.accentColor,
              inactiveTrackColor: AppTheme.surfaceElevated,
              thumbColor: AppTheme.accentColor,
              overlayColor: AppTheme.accentColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _maxReminderTimes.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _maxReminderTimes = v.round()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAll() async {
    setState(() => _loadingConfig = true);

    try {
      final configs = <Map<String, String>>[];
      // ALWAYS include keys so they can be cleared if empty
      configs.add({'key': 'groq_api_key', 'value': _groqKeyController.text});
      configs.add({
        'key': 'cerebras_api_key',
        'value': _cerebrasKeyController.text,
      });
      configs.add({'key': 'groq_model', 'value': _groqModelController.text});
      configs.add({
        'key': 'cerebras_model',
        'value': _cerebrasModelController.text,
      });
      configs.add({'key': 'primary_ai_provider', 'value': _primaryProvider});
      configs.add({
        'key': 'max_reminder_times',
        'value': _maxReminderTimes.toString(),
      });

      // Single batched call
      final success = await ConvexService.batchSetConfigs(configs);

      if (success) {
        // Update local cache
        await _updateLocalCache();

        if (mounted) {
          setState(() => _loadingConfig = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('All settings saved! ✅'),
              backgroundColor: AppTheme.surfaceElevated,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        throw Exception('Server returned error');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingConfig = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings. ❌')),
        );
      }
    }
  }
}
