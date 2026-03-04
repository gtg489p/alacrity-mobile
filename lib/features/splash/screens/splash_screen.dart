import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final box = Hive.box('settings');
    final hasUrl = box.containsKey('api_base_url');
    if (hasUrl) {
      context.go('/dashboard');
    } else {
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ALACRITY',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFF97316),
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plant Manager',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
