import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- IMPORTACIONES DE PÁGINAS ---
import 'package:blackcuack_studio/src/features/auth/presentation/splash_page.dart';
import 'package:blackcuack_studio/src/features/auth/presentation/login_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/profile_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/home_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/my_groups_page.dart';

// ✅ LLAVE MAESTRA DE NAVEGACIÓN GLOBAL
// Esta llave permite controlar el Navigator desde cualquier parte del código sin depender del "context"
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      // ✅ VINCULACIÓN DE LA LLAVE
      navigatorKey: navigatorKey,

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

      // Definimos la ruta inicial explícitamente para mayor orden
      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/my_groups': (context) => const MyGroupsPage(),
      },
    );
  }
}
