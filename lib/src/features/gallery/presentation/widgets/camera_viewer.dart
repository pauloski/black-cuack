import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackcuack_studio/src/features/auth/data/group_service.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/core/utils/quack_save_helper.dart';

class CameraViewer extends StatefulWidget {
  final CameraController controller;
  final bool showGrid;
  final bool isPlaying;
  final XFile? lastCapturedPhoto;
  final double onionOpacity;
  final int? selectedIndex;
  final List<XFile> capturedPhotos;
  final QuackProject? projectToLoad;

  const CameraViewer({
    super.key,
    required this.controller,
    required this.showGrid,
    required this.isPlaying,
    this.lastCapturedPhoto,
    required this.onionOpacity,
    this.selectedIndex,
    required this.capturedPhotos,
    this.projectToLoad,
  });

  @override
  State<CameraViewer> createState() => CameraViewerState();
}

class CameraViewerState extends State<CameraViewer> {
  final GroupService _groupService = GroupService();

  void showSaveDialog(BuildContext context) {
    final bool isEditing = widget.projectToLoad != null;
    final nameController = TextEditingController(
      text: isEditing ? widget.projectToLoad!.name : "",
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
            "🚀 FINALIZAR QUACK",
            style: TextStyle(
              fontFamily: 'LuckiestGuy',
              color: Color(0xFFC1FFFE),
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
                  activeColor: const Color(0xFFBC87FE),
                  onChanged: (val) => setModalState(() => isPublished = val),
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

                QuackSaveHelper.saveAndExit(
                  project: QuackProject(
                    id: isEditing
                        ? widget.projectToLoad!.id
                        : DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    artistName: artistController.text.trim(),
                    photoPaths: widget.capturedPhotos
                        .map((f) => f.path)
                        .toList(),
                    date: DateTime.now(),
                    isPublished: isPublished,
                    workshopCode: selectedGroupCode,
                  ),
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

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
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
