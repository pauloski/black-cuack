import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class CameraTimeline extends StatelessWidget {
  final List<XFile> capturedPhotos;
  final int? selectedIndex;
  final Function(int?) onPhotoTap;

  const CameraTimeline({
    super.key,
    required this.capturedPhotos,
    this.selectedIndex,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 15),
      child: capturedPhotos.isEmpty
          ? const Center(
              child: Text(
                "LISTO PARA EL QUACK",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontFamily: 'Lexend',
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: capturedPhotos.length,
              itemBuilder: (context, index) {
                final isCurrentSelected = index == selectedIndex;
                final isLast = index == capturedPhotos.length - 1;
                final String path = capturedPhotos[index].path;

                return GestureDetector(
                  onTap: () => onPhotoTap(isCurrentSelected ? null : index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCurrentSelected
                            ? const Color(0xFFBC87FE)
                            : (isLast && selectedIndex == null
                                  ? const Color(0xFFC1FFFE)
                                  : Colors.white10),
                        width: isCurrentSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: _buildImage(path),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // --- FUNCIÓN INTELIGENTE PARA MOSTRAR LA IMAGEN ---
  Widget _buildImage(String path) {
    // 1. Si el path empieza con http, es de la nube (Firebase)
    if (path.startsWith('http') || kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        // Si la imagen falla (la famosa X roja), muestra un icono de carga
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.white10,
          child: const Icon(Icons.sync, color: Colors.white24, size: 20),
        ),
      );
    }

    // 2. Si es móvil y es un archivo local
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image, color: Colors.white24),
    );
  }
}
