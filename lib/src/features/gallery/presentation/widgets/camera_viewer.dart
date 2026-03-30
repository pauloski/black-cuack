import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

class CameraViewer extends StatefulWidget {
  // 👈 Cambiado a StatefulWidget
  final CameraController controller;
  final bool showGrid;
  final bool isPlaying;
  final XFile? lastCapturedPhoto;
  final double onionOpacity;
  final int? selectedIndex;
  final List<XFile> capturedPhotos;

  const CameraViewer({
    super.key,
    required this.controller,
    required this.showGrid,
    required this.isPlaying,
    this.lastCapturedPhoto,
    required this.onionOpacity,
    this.selectedIndex,
    required this.capturedPhotos,
  });

  @override
  State<CameraViewer> createState() => CameraViewerState();
}

// 🦆 Esta clase es la que el "cable" de la CameraPage va a buscar
class CameraViewerState extends State<CameraViewer> {
  // 🚀 FUNCIÓN PARA MOSTRAR EL MODAL DE GUARDADO CURADO
  void showSaveDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController artistController = TextEditingController();
    bool isPublished = false;
    final ProjectService projectService = ProjectService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFBC87FE), width: 1),
          ),
          title: const Text(
            "🚀 ¡FINALIZAR QUACK!",
            style: TextStyle(
              fontFamily: 'LuckiestGuy',
              color: Color(0xFFC1FFFE),
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  nameController,
                  "TÍTULO DEL PROYECTO",
                  Icons.title,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  artistController,
                  "NOMBRE DEL ARTISTA",
                  Icons.person,
                ),
                const SizedBox(height: 10),

                SwitchListTile(
                  title: const Text(
                    "COMPARTIR EN LA CHARCA",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Lexend',
                    ),
                  ),
                  subtitle: const Text(
                    "Tus amigos podrán verlo en el taller",
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                  value: isPublished,
                  activeColor: const Color(0xFFBC87FE),
                  onChanged: (val) => setModalState(() => isPublished = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CANCELAR",
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBC87FE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    artistController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("¡Ponle nombre a tu obra y al artista! 🦆"),
                    ),
                  );
                  return;
                }

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC1FFFE)),
                  ),
                );

                try {
                  await projectService.saveProject(
                    QuackProject(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      artistName: artistController.text,
                      photoPaths: widget.capturedPhotos
                          .map((f) => f.path)
                          .toList(), // 👈 widget.
                      date: DateTime.now(),
                      isPublished: isPublished,
                      workshopCode: "TALLER_TEST",
                    ),
                  );
                  if (context.mounted) {
                    Navigator.pop(context); // Quitar loading
                    Navigator.pop(context); // Quitar modal
                    Navigator.pop(context); // Volver a la Home
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text(
                "GUARDAR",
                style: TextStyle(
                  fontFamily: 'LuckiestGuy',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontFamily: 'Lexend'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFFBC87FE), size: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFBC87FE)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: widget.controller.value.aspectRatio, // 👈 widget.
        child: Stack(
          children: [
            CameraPreview(widget.controller), // 👈 widget.
            if (widget.showGrid && !widget.isPlaying)
              Positioned.fill(child: CustomPaint(painter: GridPainter())),
            if (widget.lastCapturedPhoto != null &&
                !widget.isPlaying &&
                widget.selectedIndex == null)
              Opacity(
                opacity: widget.onionOpacity,
                child: kIsWeb
                    ? Image.network(
                        widget.lastCapturedPhoto!.path,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(widget.lastCapturedPhoto!.path),
                        fit: BoxFit.cover,
                      ),
              ),
            if (widget.selectedIndex != null)
              Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
                child: kIsWeb
                    ? Image.network(
                        widget.capturedPhotos[widget.selectedIndex!].path,
                        fit: BoxFit.contain,
                      )
                    : Image.file(
                        File(widget.capturedPhotos[widget.selectedIndex!].path),
                        fit: BoxFit.contain,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

// GridPainter se mantiene igual fuera de la clase
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
