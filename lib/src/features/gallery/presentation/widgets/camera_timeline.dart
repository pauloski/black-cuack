import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';

/// Línea de tiempo (HDU3): seleccionar, **reordenar arrastrando**, **duplicar**
/// y **borrar** cuadros. El borrado con deshacer lo maneja la página.
class CameraTimeline extends StatelessWidget {
  final List<XFile> capturedPhotos;
  final int? selectedIndex;
  final Function(int?) onPhotoTap;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(int index)? onDuplicate;
  final void Function(int index)? onDelete;
  /// Relación del proyecto: los thumbnails adoptan esta forma (apaisados en
  /// 16:9, verticales en 9:16) en vez de una caja fija vertical.
  final double frameAspect;

  const CameraTimeline({
    super.key,
    required this.capturedPhotos,
    this.selectedIndex,
    required this.onPhotoTap,
    this.onReorder,
    this.onDuplicate,
    this.onDelete,
    this.frameAspect = 9 / 16,
  });

  @override
  Widget build(BuildContext context) {
    if (capturedPhotos.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('CAPTURA TU PRIMER FRAME',
              style: TextStyle(
                  color: Colors.white24, fontSize: 10, fontFamily: 'Lexend')),
        ),
      );
    }

    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 8, top: 2),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        buildDefaultDragHandles: true,
        itemCount: capturedPhotos.length,
        onReorder: (oldIndex, newIndex) {
          if (onReorder == null) return;
          // ReorderableListView entrega newIndex desplazado si va hacia adelante.
          if (newIndex > oldIndex) newIndex -= 1;
          onReorder!(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final xfile = capturedPhotos[index];
          return Padding(
            key: ValueKey(xfile),
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onPhotoTap(isSelected ? null : index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbnail con la FORMA del proyecto (apaisado en 16:9).
                  SizedBox(
                    height: 48,
                    child: AspectRatio(
                      aspectRatio: frameAspect,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white10,
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: _buildImage(xfile.path),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Row(
                                children: [
                                  _miniBtn(Icons.copy_rounded, AppColors.primary,
                                      () => onDuplicate?.call(index)),
                                  const SizedBox(width: 3),
                                  _miniBtn(Icons.delete_rounded,
                                      AppColors.danger, () => onDelete?.call(index)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('${index + 1}',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 9,
                        color: isSelected ? AppColors.primary : Colors.white38,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 12),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http') || path.startsWith('blob:') || kIsWeb) {
      return Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => Container(
              color: Colors.white10,
              child: const Icon(Icons.sync, color: Colors.white24, size: 20)));
    }
    return Image.file(File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) =>
            const Icon(Icons.broken_image, color: Colors.white24));
  }
}
