import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  
  // --- ESTADO ---
  List<XFile> capturedPhotos = []; 
  XFile? lastCapturedPhoto; 
  double onionOpacity = 0.3;
  double fps = 12.0; 
  bool showGrid = false; 
  bool isPlaying = false; 
  int previewIndex = 0; 

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      controller = CameraController(cameras![0], ResolutionPreset.high);
      await controller!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return;
    try {
      final XFile file = await controller!.takePicture();
      setState(() {
        lastCapturedPhoto = file;
        capturedPhotos.add(file); 
      });
    } catch (e) { print("Error: $e"); }
  }

  void _playSequence() async {
    if (capturedPhotos.isEmpty) return;
    setState(() { isPlaying = true; previewIndex = 0; });

    for (int i = 0; i < capturedPhotos.length; i++) {
      if (!mounted || !isPlaying) break;
      setState(() => previewIndex = i);
      await Future.delayed(Duration(milliseconds: (1000 / fps).round()));
    }
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => isPlaying = false);
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("AJUSTES DE CÁMARA", style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFC1FFFE), fontSize: 20)),
                  const SizedBox(height: 20),
                  _buildSettingRow(Icons.opacity, "CEBOLLA", onionOpacity, (v) {
                    setModalState(() => onionOpacity = v);
                    setState(() => onionOpacity = v);
                  }),
                  const SizedBox(height: 20),
                  _buildSettingRow(Icons.speed, "VELOCIDAD (${fps.toInt()} FPS)", fps / 24, (v) {
                    double newFps = (v * 24).clamp(1, 24);
                    setModalState(() => fps = newFps);
                    setState(() => fps = newFps);
                  }, minLabel: "1", maxLabel: "24"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingRow(IconData icon, String label, double value, Function(double) onChanged, {String minLabel = "0", String maxLabel = "1"}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Lexend', color: Colors.white, fontSize: 12)),
        Row(
          children: [
            Icon(icon, color: const Color(0xFFBC87FE), size: 20),
            Expanded(
              child: Slider(
                value: value,
                activeColor: const Color(0xFFBC87FE),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFFC1FFFE))));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CÁMARA (Contenedor limitado)
          Center(
            child: AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: Stack(
                children: [
                  CameraPreview(controller!),
                  // GRID LIMITADA AL FRAME
                  if (showGrid && !isPlaying)
                    Positioned.fill(
                      child: CustomPaint(painter: GridPainter()),
                    ),
                  // EFECTO CEBOLLA LIMITADO AL FRAME
                  if (lastCapturedPhoto != null && !isPlaying)
                    Opacity(
                      opacity: onionOpacity,
                      child: kIsWeb 
                          ? Image.network(lastCapturedPhoto!.path, fit: BoxFit.cover) 
                          : Image.file(File(lastCapturedPhoto!.path), fit: BoxFit.cover),
                    ),
                ],
              ),
            ),
          ),

          // 2. INTERFAZ ERGONÓMICA
          if (!isPlaying)
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón de salir (Solo arriba para no estorbar)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ),
                  ),

                  // PARTE INFERIOR: Botones de función cerca del pulgar
                  Column(
                    children: [
                      // BOTONES DE HERRAMIENTAS (Grid y Ajustes)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: Icon(Icons.grid_4x4, color: showGrid ? const Color(0xFFC1FFFE) : Colors.white),
                                onPressed: () => setState(() => showGrid = !showGrid),
                              ),
                            ),
                            const SizedBox(width: 15),
                            CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(icon: const Icon(Icons.tune, color: Colors.white), onPressed: _showSettings),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTimeline(),
                      _buildActionButtons(),
                    ],
                  ),
                ],
              ),
            ),

          // 3. MODO CINE
          if (isPlaying) _buildCinemaMode(),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 15),
      child: capturedPhotos.isEmpty 
        ? const Center(child: Text("LISTO PARA EL QUACK", style: TextStyle(color: Colors.white24, fontSize: 10)))
        : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: capturedPhotos.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 6),
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: index == capturedPhotos.length - 1 ? const Color(0xFFC1FFFE) : Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: kIsWeb ? Image.network(capturedPhotos[index].path, fit: BoxFit.cover) : Image.file(File(capturedPhotos[index].path), fit: BoxFit.cover),
                ),
              );
            },
          ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.undo, color: Color(0xFFFF4D4D), size: 30), onPressed: () {
            if (capturedPhotos.isNotEmpty) {
              setState(() { capturedPhotos.removeLast(); lastCapturedPhoto = capturedPhotos.isEmpty ? null : capturedPhotos.last; });
            }
          }),
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              height: 75, width: 75,
              decoration: const BoxDecoration(color: Color(0xFFFF4D4D), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 15)]),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 35),
            ),
          ),
          IconButton(icon: const Icon(Icons.play_circle_fill, color: Color(0xFFC1FFFE), size: 50), onPressed: _playSequence),
        ],
      ),
    );
  }

  Widget _buildCinemaMode() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(child: kIsWeb ? Image.network(capturedPhotos[previewIndex].path) : Image.file(File(capturedPhotos[previewIndex].path))),
          Positioned(top: 50, left: 0, right: 0, child: Center(child: Text("${previewIndex + 1} / ${capturedPhotos.length} @ ${fps.toInt()} FPS", style: const TextStyle(fontFamily: 'Lexend', color: Color(0xFFC1FFFE))))),
          Positioned(bottom: 40, left: 0, right: 0, child: Center(child: IconButton(icon: const Icon(Icons.stop_circle, color: Color(0xFFFF4D4D), size: 70), onPressed: () => setState(() => isPlaying = false)))),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1.2;
    // Líneas Verticales
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    // Líneas Horizontales
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}