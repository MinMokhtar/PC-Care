import 'package:flutter/material.dart';

import '../services/app_mode_service.dart';
import 'connect_pc_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _splashBlue = Color(0xFF29ABE2);

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final mode = await AppModeService().load();
    if (!mounted) return;

    if (mode == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ConnectPcScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _splashBlue,
      body: Center(
        child: Image.asset(
          'assets/icon/app_icon_white.png',
          width: 140,
          height: 140,
        ),
      ),
    );
  }
}
