import 'package:flutter/material.dart';

class CameraControls extends StatelessWidget {
  final bool isEditing;
  final bool showGrid;
  final VoidCallback onToggleGrid;
  final VoidCallback onShowSettings;
  final VoidCallback onExport;
  final VoidCallback onSave; // Esta es la que disparará el nuevo modal
  final VoidCallback onTakePhoto;
  final VoidCallback onPlay;
  final VoidCallback onUndo;
  final int? selectedIndex;
  final bool hasPhotos;

  const CameraControls({
    super.key,
    required this.isEditing,
    required this.showGrid,
    required this.onToggleGrid,
    required this.onShowSettings,
    required this.onExport,
    required this.onSave,
    required this.onTakePhoto,
    required this.onPlay,
    required this.onUndo,
    this.selectedIndex,
    required this.hasPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- BOTONES SUPERIORES (CONFIGURACIÓN) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _circleBtn(
                icon: Icons.grid_4x4,
                onTap: onToggleGrid,
                active: showGrid,
                tooltip: "Rejilla",
              ),
              const SizedBox(width: 12),
              _circleBtn(
                icon: Icons.tune,
                onTap: onShowSettings,
                tooltip: "Ajustes",
              ),
              const SizedBox(width: 12),
              _circleBtn(
                icon: Icons.ios_share,
                onTap: onExport,
                color: const Color(0xFFBC87FE),
                tooltip: "Exportar",
              ),
              const SizedBox(width: 12),
              // ✅ BOTÓN DE GUARDAR: Ahora tiene un efecto visual más fuerte
              _circleBtn(
                icon: isEditing ? Icons.save : Icons.check,
                onTap: hasPhotos ? onSave : () {}, // Solo funciona si hay fotos
                color: const Color(0xFFC1FFFE),
                active: true, // Lo mantenemos activo para que resalte
                tooltip: "Finalizar Quack",
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // --- PANEL DE CAPTURA Y ACCIÓN ---
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón Deshacer / Eliminar
              IconButton(
                icon: Icon(
                  selectedIndex != null ? Icons.delete_forever : Icons.undo,
                  color: const Color(0xFFFF4D4D),
                  size: selectedIndex != null ? 35 : 30,
                ),
                onPressed: hasPhotos ? onUndo : null,
              ),

              // Disparador (Cámara)
              GestureDetector(
                onTap: onTakePhoto,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D4D),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4D4D).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),

              // Botón Play
              IconButton(
                icon: Icon(
                  Icons.play_circle_fill,
                  color: hasPhotos ? const Color(0xFFC1FFFE) : Colors.white10,
                  size: 55,
                ),
                onPressed: hasPhotos ? onPlay : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    bool active = false,
    String? tooltip,
  }) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: active ? color : Colors.black54,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: active ? Colors.black : color, size: 20),
        onPressed: onTap,
      ),
    );
  }
}
