import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:blackcuack_studio/src/core/config/repositories.dart';
import 'package:blackcuack_studio/src/core/utils/frame_codec.dart'
    show aspectValue;
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

/// Modo proyección (HDU13): pantalla completa, **sin controles**, en bucle.
/// Reproduce uno o varios proyectos en secuencia. Tocar la pantalla sale.
class ProjectionPage extends StatefulWidget {
  final List<QuackProject> projects;
  final double fps;
  const ProjectionPage({super.key, required this.projects, this.fps = 12});

  @override
  State<ProjectionPage> createState() => _ProjectionPageState();
}

class _ProjectionPageState extends State<ProjectionPage> {
  final List<Uint8List> _frames = [];
  int _i = 0;
  bool _loading = true;
  bool _showHint = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  Future<void> _load() async {
    for (final p in widget.projects) {
      _frames.addAll(await projectRepository.loadFrames(p.id));
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (_frames.isNotEmpty) {
      _timer = Timer.periodic(
        Duration(milliseconds: (1000 / widget.fps).round()),
        (_) => setState(() => _i = (_i + 1) % _frames.length),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: _loading
                  ? const CircularProgressIndicator(
                      color: Color(0xFFFFB800), strokeWidth: 2)
                  : _frames.isEmpty
                      ? const Text('Sin cuadros',
                          style: TextStyle(color: Colors.white24))
                      : AspectRatio(
                          aspectRatio: aspectValue(widget.projects.isNotEmpty
                              ? widget.projects.first.aspect
                              : '9:16'),
                          child: ClipRect(
                            child: Image.memory(_frames[_i],
                                key: ValueKey(_i),
                                fit: BoxFit.cover,
                                gaplessPlayback: true),
                          ),
                        ),
            ),
            if (_showHint && !_loading)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Toca para salir',
                        style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Lexend',
                            fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
