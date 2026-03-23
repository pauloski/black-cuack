import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MIS QUACKS',
          style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFC1FFFE)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFBC87FE)),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¡Hola, Artista!',
              style: TextStyle(
                fontFamily: 'Barriecito',
                fontSize: 28,
                color: Color(0xFFBC87FE),
              ),
            ),
            const SizedBox(height: 20),
            QuackButton(
              text: '+ NUEVO PROYECTO',
              onPressed: () {
                print("Creando nuevo stop-motion...");
              },
            ),
            const SizedBox(height: 40),
            const Text(
              'RECIENTES',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: const [
                  QuackCard(
                    title: "Mi primer Pato",
                    date: "Hace 2 horas",
                    borderColor: Color(0xFFC1FFFE),
                  ),
                  QuackCard(
                    title: "Caos Creativo",
                    date: "Ayer",
                    borderColor: Color(0xFFBC87FE),
                  ),
                  QuackCard(
                    title: "Stop Motion 1",
                    date: "15 Mar",
                    borderColor: Color(0xFFF3FFCA),
                  ),
                  QuackCard(
                    title: "Prueba Ruido",
                    date: "10 Mar",
                    borderColor: Color(0xFFC1FFFE),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}