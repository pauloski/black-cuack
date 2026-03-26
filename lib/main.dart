import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Importamos las opciones generadas por FlutterFire
import 'firebase_options.dart'; 

// Importa tu página de login
import 'package:blackcuack_studio/src/features/auth/presentation/login_page.dart';

void main() async {
  // 1. Asegura que los bindings de Flutter estén listos para procesos async
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Firebase usando el archivo que ya tienes en tu carpeta lib
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
      
      // Aplicamos tu Design System: The Kinetic Canvas
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E0E0E), // Fondo Materia Oscura
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC1FFFE),   // Cian Neón
          secondary: Color(0xFFBC87FE), // Púrpura Vibrante
          tertiary: Color(0xFFF3FFCA),  // Verde Lima (IA)
          surface: Color(0xFF1A1A1A),   // Paneles
        ),
        
        // Configuración de textos y fuentes de marca
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFFC1FFFE), 
            fontWeight: FontWeight.bold, 
            fontFamily: 'LuckiestGuy'
          ),
          bodyMedium: TextStyle(
            color: Color(0xFFADAAAA), 
            fontFamily: 'Lexend'
          ),
        ),
      ),
      
      // La puerta de entrada es tu página de Login
      home: const LoginPage(),
    );
  }
}