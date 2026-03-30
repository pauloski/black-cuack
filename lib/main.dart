import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- IMPORTACIONES DE PÁGINAS ---
// ✅ Nueva importación del Splash
import 'package:blackcuack_studio/src/features/auth/presentation/splash_page.dart';
import 'package:blackcuack_studio/src/features/auth/presentation/login_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/profile_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("🦆 ¡Quack! Motor de Firebase encendido y conectado.");
  } catch (e) {
    print("⚠️ Error al inicializar Firebase: $e");
  }

  runApp(const BlackCuackApp());
}

class BlackCuackApp extends StatelessWidget {
  const BlackCuackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blackcuack Studio',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC1FFFE),
          secondary: Color(0xFFBC87FE),
          tertiary: Color(0xFFF3FFCA),
          surface: Color(0xFF1A1A1A),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFFC1FFFE),
            fontWeight: FontWeight.bold,
            fontFamily: 'LuckiestGuy',
          ),
          bodyMedium: TextStyle(color: Color(0xFFADAAAA), fontFamily: 'Lexend'),
        ),
      ),

      // ✅ CAMBIO CLAVE: La app ahora arranca en el Splash
      home: const SplashPage(),

      // ✅ RUTAS ACTUALIZADAS
      routes: {
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
