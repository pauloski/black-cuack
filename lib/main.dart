import 'package:flutter/material.dart';
// Importa la nueva página arriba
import 'package:blackcuack_studio/src/features/auth/presentation/login_page.dart';

void main() {
  runApp(const BlackcuackApp());
}

class BlackcuackApp extends StatelessWidget {
  const BlackcuackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blackcuack Studio',
      debugShowCheckedModeBanner: false,
      // Aplicamos tu Design System: The Kinetic Canvas
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E0E0E), // Fondo Materia Oscura
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC1FFFE), // Cian Neón
          secondary: Color(0xFFBC87FE), // Púrpura Vibrante
          tertiary: Color(0xFFF3FFCA), // Verde Lima (IA)
          surface: Color(0xFF1A1A1A), // Paneles
        ),
        // Tipografía por defecto (luego podemos importar Lexend)
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFFC1FFFE), fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Color(0xFFADAAAA)), // On surface variant
        ),
      ),
     // home: const SplashPage(),
      home: const LoginPage(),
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí irá tu logo del patito más adelante
            const Icon(Icons.blur_on, size: 100, color: Color(0xFFC1FFFE)),
            const SizedBox(height: 20),
            Text(
              'MAKE SOME NOISE',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 32,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Creative Chaos Activated',
              style: TextStyle(color: Color(0xFFBC87FE), fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}