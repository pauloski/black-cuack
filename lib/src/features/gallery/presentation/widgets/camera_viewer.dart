import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class CameraViewer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          children: [
            // 1. La Cámara en vivo
            CameraPreview(controller),

            // 2. La Rejilla (Grid)
            if (showGrid && !isPlaying)
              Positioned.fill(child: CustomPaint(painter: GridPainter())),

            // 3. Papel Cebolla (Onion Skin)
            if (lastCapturedPhoto != null && !isPlaying && selectedIndex == null)
              Opacity(
                opacity: onionOpacity,
                child: kIsWeb 
                    ? Image.network(lastCapturedPhoto!.path, fit: BoxFit.cover) 
                    : Image.file(File(lastCapturedPhoto!.path), fit: BoxFit.cover),
              ),

            // 4. Ver foto seleccionada del Timeline
            if (selectedIndex != null)
              Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
                child: kIsWeb 
                    ? Image.network(capturedPhotos[selectedIndex!].path, fit: BoxFit.contain) 
                    : Image.file(File(capturedPhotos[selectedIndex!].path), fit: BoxFit.contain),
              ),
          ],
        ),
      ),
    );
  }
}

// Movimos el GridPainter aquí para limpiar el archivo principal
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}