import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos el fondo oscuro de tu marca
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Título con tu fuente LuckiestGuy
              const Text(
                'READY TO\nQUACK?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'LuckiestGuy',
                  fontSize: 56, // Un poco más grande para impacto
                  color: Color(0xFFC1FFFE),
                  height: 0.9,
                ),
              ),
              
              const SizedBox(height: 15),
              
              // 2. Subtítulo con Barriecito
              const Text(
                'Make some noise, creative chaos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Barriecito',
                  fontSize: 22,
                  color: Color(0xFFBC87FE),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // 3. Tu nuevo componente de texto (Limpio y reutilizable)
              const QuackTextField(
                hintText: 'CÓDIGO DE TALLER',
              ),
              
              const SizedBox(height: 25),
              
              // 4. Tu nuevo botón con sombra "Pop" (Limpio y reutilizable)
           QuackButton(
  text: '¡ENTRAR!',
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  },
),
            ],
          ),
        ),
      ),
    );
  }
}