import 'package:flutter/material.dart';

import '../cache/cache_manager.dart';
import '../theme/app_theme.dart';

/// Banner shown when displaying stale/cached data.
/// Shows cache age and offers a tap-to-retry action.
class OfflineBanner extends StatelessWidget {
  final String cacheKey;
  final VoidCallback onRetry;

  const OfflineBanner({
    super.key,
    required this.cacheKey,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cache = CacheManager();
    final age = cache.getAge(cacheKey);

    return GestureDetector(
      onTap: onRetry,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        color: AppTheme.amber500.withValues(alpha: 0.15),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, size: 14, color: AppTheme.amber500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '\u26A0\uFE0F Offline \u2014 showing data from ${_formatAge(age)}',
                style: const TextStyle(
                  color: AppTheme.amber500,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(Icons.refresh, size: 14, color: AppTheme.amber500),
          ],
        ),
      ),
    );
  }

  String _formatAge(Duration? age) {
    if (age == null) return 'cache';
    if (age.inMinutes < 1) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }
}
