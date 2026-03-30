import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

class MoviePlayerPage extends StatefulWidget {
  final QuackProject project;
  const MoviePlayerPage({super.key, required this.project});

  @override
  State<MoviePlayerPage> createState() => _MoviePlayerPageState();
}

class _MoviePlayerPageState extends State<MoviePlayerPage> {
  int _currentFrame = 0;
  bool _isPlaying = true;
  Timer? _timer;
  double _fps = 10.0; // Velocidad estándar para stop-motion infantil

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: (1000 / _fps).round()), (
      timer,
    ) {
      if (mounted && _isPlaying) {
        setState(() {
          _currentFrame =
              (_currentFrame + 1) % widget.project.photoPaths.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.project.photoPaths;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🎞️ EL PROYECTOR (Imagen central)
          Center(
            child: photos.isEmpty
                ? const Text(
                    "No hay fotogramas",
                    style: TextStyle(color: Colors.white24),
                  )
                : kIsWeb
                ? Image.network(photos[_currentFrame], fit: BoxFit.contain)
                : Image.file(File(photos[_currentFrame]), fit: BoxFit.contain),
          ),

          // 🎭 OVERLAY DE CONTROLES
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header con Título
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.name.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFC1FFFE),
                              fontFamily: 'LuckiestGuy',
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "POR: ${widget.project.artistName.toUpperCase()}",
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontFamily: 'Lexend',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Footer con Controles de Cine
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 40,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Bajar velocidad
                      IconButton(
                        icon: const Icon(
                          Icons.fast_rewind,
                          color: Colors.white24,
                        ),
                        onPressed: () =>
                            setState(() => _fps = (_fps > 2) ? _fps - 2 : 2),
                      ),

                      // PLAY / PAUSE GIGANTE
                      GestureDetector(
                        onTap: () => setState(() => _isPlaying = !_isPlaying),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: const Color(0xFFBC87FE),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 40,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      // Subir velocidad
                      IconButton(
                        icon: const Icon(
                          Icons.fast_forward,
                          color: Colors.white24,
                        ),
                        onPressed: () =>
                            setState(() => _fps = (_fps < 24) ? _fps + 2 : 24),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
