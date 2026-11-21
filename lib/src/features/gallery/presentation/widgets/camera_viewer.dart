import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackcuack_studio/src/core/config/cloud_access.dart';
import 'package:blackcuack_studio/src/features/auth/data/group_service.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

class CameraViewer extends StatefulWidget {
  final CameraController controller;
  final bool showGrid;
  final bool isPlaying;
  final XFile? lastCapturedPhoto;
  final double onionOpacity;
  final int onionLayers;
  final int? selectedIndex;
  final List<XFile> capturedPhotos;
  final QuackProject? projectToLoad;
  final Future<void> Function({
    required String name,
    required String artist,
    bool isPublished,
    String? groupCode,
  })? onSave;

  const CameraViewer({
    super.key,
    required this.controller,
    required this.showGrid,
    required this.isPlaying,
    this.lastCapturedPhoto,
    required this.onionOpacity,
    this.onionLayers = 1,
    this.selectedIndex,
    required this.capturedPhotos,
    this.projectToLoad,
    this.onSave,
  });

  @override
  State<CameraViewer> createState() => CameraViewerState();
}

class CameraViewerState extends State<CameraViewer> {
  final GroupService _groupService = GroupService();

  void showSaveDialog(BuildContext context, {String? initialName}) {
    final bool isEditing = widget.projectToLoad != null;
    final nameController = TextEditingController(
      text: isEditing
          ? widget.projectToLoad!.name
          : (initialName != null && initialName != 'Mi Animación'
              ? initialName
              : ""),
    );
    final artistController = TextEditingController(
      text: isEditing ? widget.projectToLoad!.artistName : "",
    );
    String? selectedGroupCode = isEditing
        ? widget.projectToLoad!.workshopCode
        : null;
    bool isPublished = isEditing ? widget.projectToLoad!.isPublished : false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            "GUARDAR ANIMACIÓN",
            style: TextStyle(
              fontFamily: 'Lexend',
              color: Color(0xFFFFB800),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  nameController,
                  "TÍTULO",
                  Icons.title,
                  readOnly: isEditing,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  artistController,
                  "ARTISTA",
                  Icons.person,
                  readOnly: isEditing,
                ),
                const SizedBox(height: 20),
                if (hasCloudAccount) ...[
                  _buildGroupSelector(
                    selectedGroupCode,
                    (val) => setModalState(() => selectedGroupCode = val),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "COMPARTIR EN GRUPO",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    value: isPublished,
                    activeThumbColor: const Color(0xFFBC87FE),
                    onChanged: (val) => setModalState(() => isPublished = val),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            color: Colors.white38, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Compartir en grupo es una función colaborativa: "
                            "necesitas conexión y una cuenta.",
                            style:
                                TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBC87FE),
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;

                Navigator.pop(context); // Cierra diálogo texto

                // Guardado local (sin Firebase). El compartir en grupo solo
                // viaja si hay cuenta de nube real (ver más abajo el gate).
                final canCloud = hasCloudAccount;
                widget.onSave?.call(
                  name: nameController.text.trim(),
                  artist: artistController.text.trim(),
                  isPublished: canCloud && isPublished,
                  groupCode: canCloud ? selectedGroupCode : null,
                );
              },
              child: const Text(
                "GUARDAR",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSelector(String? selected, Function(String?) onChange) {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupService.getMyGroupsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            "No tienes grupos activos",
            style: TextStyle(fontSize: 11, color: Colors.white24),
          );
        }

        return DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: const Text("SELECCIONAR GRUPO", style: TextStyle(fontSize: 12)),
          underline: Container(height: 1, color: Colors.white10),
          dropdownColor: const Color(0xFF1A1A1A),
          // ✅ CORRECCIÓN AQUÍ: Forzamos el mapeo a DropdownMenuItem<String>
          items: snapshot.data!.docs.map<DropdownMenuItem<String>>((g) {
            final data = g.data() as Map<String, dynamic>;
            final String code = data['code']?.toString() ?? "";
            final String name = data['name']?.toString() ?? "Sin nombre";
            return DropdownMenuItem<String>(
              value: code,
              child: Text(
                name.toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChange,
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFFBC87FE)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildOnionLayer(XFile photo, double opacity) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: kIsWeb
          ? Image.network(photo.path, fit: BoxFit.cover)
          : Image.file(File(photo.path), fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: widget.controller.value.aspectRatio,
        child: Stack(
          children: [
            CameraPreview(widget.controller),
            if (widget.showGrid && !widget.isPlaying)
              Positioned.fill(child: CustomPaint(painter: GridPainter())),
            // Multi-layer onion skin: más reciente encima, más antiguo abajo
            if (widget.onionLayers > 0 &&
                widget.capturedPhotos.isNotEmpty &&
                !widget.isPlaying &&
                widget.selectedIndex == null)
              for (int i = widget.onionLayers - 1; i >= 0; i--)
                if (widget.capturedPhotos.length - 1 - i >= 0)
                  _buildOnionLayer(
                    widget.capturedPhotos[widget.capturedPhotos.length - 1 - i],
                    // i=0 → capa más reciente (opacidad completa)
                    // i=1 → capa anterior (50%)
                    // i=2 → capa más antigua (25%)
                    widget.onionOpacity * [1.0, 0.5, 0.25][i],
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

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * i / 3, 0),
        Offset(size.width * i / 3, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
