import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';

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
    if (capturedPhotos.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'CAPTURA TU PRIMER FRAME',
            style: TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'Lexend'),
          ),
        ),
      );
    }

    return Container(
      height: 96,
      margin: const EdgeInsets.only(bottom: 10, top: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: capturedPhotos.length + 1,
        itemBuilder: (context, index) {
          // "+" placeholder at end
          if (index == capturedPhotos.length) {
            return Container(
              margin: const EdgeInsets.only(right: 6),
              width: 58,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded, color: Colors.white24, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            );
          }

          final isSelected = index == selectedIndex;
          final String path = capturedPhotos[index].path;

          return GestureDetector(
            onTap: () => onPhotoTap(isSelected ? null : index),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              width: 58,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.white10,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 8, spreadRadius: 1)]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _buildImage(path),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 9,
                      color: isSelected ? AppColors.primary : Colors.white38,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http') || kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.white10,
          child: const Icon(Icons.sync, color: Colors.white24, size: 20),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, color: Colors.white24),
    );
  }
}
