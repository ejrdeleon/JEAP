import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/network/api_config.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';

class ServerSettingsSheet extends StatefulWidget {
  const ServerSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ServerSettingsSheet(),
    );
  }

  @override
  State<ServerSettingsSheet> createState() => _ServerSettingsSheetState();
}

class _ServerSettingsSheetState extends State<ServerSettingsSheet> {
  late TextEditingController _urlCtrl;
  bool _testing = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
      _testSuccess = null;
    });

    final tempUrl = _urlCtrl.text.trim();
    final prevUrl = ApiConfig.baseUrl;
    await ApiConfig.setBaseUrl(tempUrl);

    try {
      final healthy = await AuthService().checkServerHealth();
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testSuccess = healthy;
        _testResult = healthy
            ? 'Server reachable! Status: OK'
            : 'Could not connect to server at this URL.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testSuccess = false;
        _testResult = 'Connection error: $e';
      });
    } finally {
      // Restore previous until user clicks Save
      if (_testSuccess != true) {
        await ApiConfig.setBaseUrl(prevUrl);
      }
    }
  }

  Future<void> _save() async {
    final newUrl = _urlCtrl.text.trim();
    if (newUrl.isEmpty) return;
    await ApiConfig.setBaseUrl(newUrl);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server URL set to: ${ApiConfig.baseUrl}'),
        backgroundColor: AppTheme.statusGreen,
      ),
    );
  }

  Future<void> _reset() async {
    await ApiConfig.resetBaseUrl();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text = ApiConfig.baseUrl;
      _testResult = null;
      _testSuccess = null;
    });
  }

  Future<void> _autoDetect() async {
    setState(() {
      _testing = true;
      _testResult = 'Auto-detecting available server...';
      _testSuccess = null;
    });

    final detected = await ApiConfig.autoDetectServer();
    if (!mounted) return;

    setState(() {
      _testing = false;
      _urlCtrl.text = detected;
      _testSuccess = true;
      _testResult = 'Found responsive server:\n$detected';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Server Environment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset', style: TextStyle(color: AppTheme.jeapPurple)),
                ),
              ],
            ),
            const Text(
              'Select a preset, use auto-detection, or enter the host address of your Laravel API backend.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _testing ? null : _autoDetect,
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('Auto-Detect Server'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.jeapPurple,
                side: const BorderSide(color: AppTheme.jeapPurple),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            ...ApiEnvironment.values.where((e) => e != ApiEnvironment.custom).map((env) {
              final isCurrent = _urlCtrl.text.trim() == env.defaultUrl;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isCurrent ? AppTheme.jeapPurple : AppTheme.borderColor,
                    width: isCurrent ? 1.5 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: isCurrent ? AppTheme.jeapPurple.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      env.label,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent ? AppTheme.jeapPurple : AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      env.defaultUrl,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: AppTheme.jeapPurple, size: 20)
                        : null,
                    onTap: () {
                      setState(() {
                        _urlCtrl.text = env.defaultUrl;
                        _testResult = null;
                        _testSuccess = null;
                      });
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text(
              'Custom API Endpoint',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. http://192.168.1.100:8080/api/v1',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _urlCtrl.clear(),
                ),
              ),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_testSuccess == true ? AppTheme.statusGreen : Colors.redAccent)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess == true ? Icons.check_circle_outline : Icons.error_outline,
                      color: _testSuccess == true ? AppTheme.statusGreen : Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testSuccess == true ? AppTheme.statusGreen : Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _testing ? null : _testConnection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.jeapPurple,
                      side: const BorderSide(color: AppTheme.jeapPurple),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.jeapPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Save & Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
