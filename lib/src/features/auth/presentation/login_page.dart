import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título con LuckiestGuy
              const Text(
                'READY TO\nQUACK?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'LuckiestGuy',
                  fontSize: 48,
                  color: Color(0xFFC1FFFE),
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              // Subtítulo con Barriecito
              const Text(
                'Make some noise, creative chaos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Barriecito',
                  fontSize: 20,
                  color: Color(0xFFBC87FE),
                ),
              ),
              const SizedBox(height: 50),
              // Campo de texto para el código (Estilo Lexend)
              TextField(
                decoration: InputDecoration(
                  hintText: 'CÓDIGO DE TALLER',
                  hintStyle: const TextStyle(fontFamily: 'Lexend', color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
                style: const TextStyle(fontFamily: 'Lexend', color: Colors.white),
              ),
              const SizedBox(height: 20),
              // Botón Principal
              ElevatedButton(
                onPressed: () {
                  // Lógica de entrada
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC1FFFE),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  '¡ENTRAR!',
                  style: TextStyle(
                    fontFamily: 'LuckiestGuy',
                    color: Color(0xFF0E0E0E),
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}