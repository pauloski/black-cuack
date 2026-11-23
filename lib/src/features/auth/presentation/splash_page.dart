import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    Future.delayed(const Duration(seconds: 2), _goToLogin);
  }

  void _goToLogin() {
    if (mounted && !_didNavigate) {
      _didNavigate = true;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final duckSize = (size.shortestSide * 0.45).clamp(160.0, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Center(
        child: Lottie.asset(
          'assets/lottie/blacky.json',
          controller: _controller,
          width: duckSize,
          height: duckSize,
          fit: BoxFit.contain,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..repeat();
          },
        ),
      ),
    );
  }
}
