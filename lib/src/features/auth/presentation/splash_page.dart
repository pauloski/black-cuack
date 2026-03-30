import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 🕹️ Inicializamos el controlador (sin duración, la toma del archivo JSON)
    _controller = AnimationController(vsync: this);

    // 👂 Escuchamos el estado de la animación
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // ✅ CUANDO TERMINE: Saltamos al Login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Siempre limpiar para no gastar memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Center(
        child: Lottie.network(
          'https://assets10.lottiefiles.com/packages/lf20_qp1q7mct.json',
          controller: _controller,
          onLoaded: (composition) {
            // 🎬 Cuando el archivo carga, ajustamos el controlador a su duración real
            _controller.duration = composition.duration;
            _controller.forward(); // Y le damos Play
          },
          width: 300,
          height: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
