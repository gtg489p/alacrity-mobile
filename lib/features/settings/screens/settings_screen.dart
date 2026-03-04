import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  ConnectionTestResult? _testResult;
  bool _testing = false;

  static const _presets = [
    ('Cloud', 'https://api.alacrity.live'),
    ('LAN', 'http://192.168.0.122:8000'),
    ('Tailscale', 'http://100.65.21.123:8000'),
  ];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    final url = box.get('api_base_url', defaultValue: 'https://api.alacrity.live') as String;
    _urlController = TextEditingController(text: url);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl(String url) async {
    final box = Hive.box('settings');
    await box.put('api_base_url', url);
    ref.invalidate(apiBaseUrlProvider);
    ref.invalidate(dioProvider);
    ref.invalidate(apiClientProvider);
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    await _saveUrl(_urlController.text.trim());
    final api = ref.read(apiClientProvider);
    final result = await api.testConnection();
    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API Connection section
          Text('API Connection', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'API Base URL',
              hintText: 'https://api.alacrity.live',
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _testConnection(),
          ),
          const SizedBox(height: 12),

          // Preset buttons
          Wrap(
            spacing: 8,
            children: _presets
                .map(
                  (p) => ActionChip(
                    label: Text(p.$1),
                    onPressed: () {
                      _urlController.text = p.$2;
                      _saveUrl(p.$2);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),

          // Test Connection button
          FilledButton.icon(
            onPressed: _testing ? null : _testConnection,
            icon: _testing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find),
            label: Text(_testing ? 'Testing...' : 'Test Connection'),
          ),

          // Test result
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            _ConnectionResultCard(result: _testResult!),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Theme section
          Text('Theme', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ],
            selected: {themeMode},
            onSelectionChanged: (selected) {
              ref
                  .read(themeModeNotifierProvider.notifier)
                  .setThemeMode(selected.first);
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // App info
          Text('App Info', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Alacrity Mobile v1.0.0+1',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionResultCard extends StatelessWidget {
  final ConnectionTestResult result;

  const _ConnectionResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: result.success
          ? const Color(0xFF22C55E).withValues(alpha: 0.1)
          : const Color(0xFFEF4444).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: result.success
                  ? Text(
                      'Connected (${result.latencyMs}ms) — ${result.factoryName}',
                      style: theme.textTheme.bodyMedium,
                    )
                  : Text(
                      'Connection failed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFEF4444),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
