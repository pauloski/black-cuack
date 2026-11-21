import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/config/repositories.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/projection_page.dart';

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
  double _fps = 10.0;
  final double _maxFps = 24.0;
  final double _minFps = 2.0;

  // Cuadros locales (bytes). Si está vacío, el proyecto es de nube (URLs).
  List<Uint8List> _frames = [];
  bool _loading = true;

  int get _frameCount =>
      _frames.isNotEmpty ? _frames.length : widget.project.photoPaths.length;

  @override
  void initState() {
    super.initState();
    _loadFrames();
  }

  Future<void> _loadFrames() async {
    final frames = await projectRepository.loadFrames(widget.project.id);
    if (!mounted) return;
    setState(() {
      _frames = frames;
      _loading = false;
    });
    _startAnimation();
  }

  void _startAnimation() {
    _timer?.cancel();
    if (_frameCount == 0) return;
    _timer = Timer.periodic(Duration(milliseconds: (1000 / _fps).round()), (
      timer,
    ) {
      if (mounted && _isPlaying) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _frameCount;
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
          // 🎞️ EL PROYECTOR
          Center(
            child: _loading
                ? const CircularProgressIndicator(
                    color: Color(0xFFFFB800), strokeWidth: 2)
                : _frameCount == 0
                    ? const Text("Sin fotos",
                        style: TextStyle(color: Colors.white24))
                    : _frames.isNotEmpty
                        ? Image.memory(
                            _frames[_currentFrame],
                            key: ValueKey(_currentFrame),
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          )
                        : Image.network(
                            photos[_currentFrame],
                            key: ValueKey(photos[_currentFrame]),
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
          ),

          // 🎭 INTERFAZ (UI)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeader(), // Arriba
                _buildBottomSection(), // Abajo (Info + Controles)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.project.name.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFFB800),
                  fontFamily: 'Lexend',
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
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
            tooltip: 'Proyectar',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProjectionPage(projects: [widget.project]))),
          ),
        ],
      ),
    );
  }

  // ✅ ESTA ES LA FUNCIÓN QUE FALTABA
  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info flotando a la derecha
          Align(alignment: Alignment.centerRight, child: _buildInfoBadge()),
          const SizedBox(height: 15),
          // Controles de reproducción
          _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildInfoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        "${_fps.round()} FPS | FOTO: ${_currentFrame + 1}/$_frameCount",
        style: const TextStyle(
          color: Color(0xFFFFB800),
          fontFamily: 'Lexend',
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 35),
          color: _fps > _minFps ? Colors.white60 : Colors.white10,
          onPressed: _fps > _minFps
              ? () {
                  setState(() => _fps -= 2);
                  _startAnimation();
                }
              : null,
        ),
        const SizedBox(width: 30),
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
        const SizedBox(width: 30),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 35),
          color: _fps < _maxFps ? Colors.white60 : Colors.white10,
          onPressed: _fps < _maxFps
              ? () {
                  setState(() => _fps += 2);
                  _startAnimation();
                }
              : null,
        ),
      ],
    );
  }
}
