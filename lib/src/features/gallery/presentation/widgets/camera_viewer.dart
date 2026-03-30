import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';
import 'package:blackcuack_studio/src/features/auth/data/group_service.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

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
    // 🦆 DETECTAR SI ES EDICIÓN
    final bool isEditing = widget.projectToLoad != null;

    final TextEditingController nameController = TextEditingController(
      text: isEditing ? widget.projectToLoad!.name : "",
    );
    final TextEditingController artistController = TextEditingController(
      text: isEditing ? widget.projectToLoad!.artistName : "",
    );

    final ProjectService projectService = ProjectService();

    // Estado inicial del modal
    String? selectedGroupCode = isEditing
        ? widget.projectToLoad!.workshopCode
        : null;
    bool isPublished = isEditing ? widget.projectToLoad!.isPublished : false;

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
            "🚀 FINALIZAR QUACK",
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
                  readOnly: isEditing,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  artistController,
                  "NOMBRE DEL ARTISTA",
                  Icons.person,
                  readOnly: isEditing,
                ),
                const SizedBox(height: 20),

                // --- SELECTOR DE GRUPOS EN TIEMPO REAL CON VALIDACIÓN ---
                StreamBuilder<QuerySnapshot>(
                  stream: _groupService.getMyGroupsStream(),
                  builder: (context, snapshot) {
                    bool hasGroups =
                        snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    var groups = hasGroups ? snapshot.data!.docs : [];

                    // 🔥 PROTECCIÓN CONTRA PANTALLA ROJA:
                    // Si el código guardado no existe en los grupos actuales, lo reseteamos a null
                    if (selectedGroupCode != null && hasGroups) {
                      bool exists = groups.any(
                        (g) =>
                            (g.data() as Map<String, dynamic>)['code'] ==
                            selectedGroupCode,
                      );
                      if (!exists) {
                        selectedGroupCode = null;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: hasGroups
                              ? const Color(0xFFC1FFFE).withOpacity(0.2)
                              : Colors.orangeAccent.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (!hasGroups)
                            const Text(
                              "⚠️ Únete a un grupo primero para compartir con tus amigos.",
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            )
                          else
                            DropdownButton<String>(
                              value: selectedGroupCode,
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: const Color(0xFF1A1A1A),
                              hint: const Text(
                                "SELECCIONAR GRUPO",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              items: groups.map((g) {
                                final data = g.data() as Map<String, dynamic>;
                                return DropdownMenuItem(
                                  value: data['code'].toString(),
                                  child: Text(
                                    data['name'].toString().toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: 'Lexend',
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setModalState(() => selectedGroupCode = val),
                            ),

                          const Divider(color: Colors.white10),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              "COMPARTIR CON EL GRUPO",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontFamily: 'Lexend',
                              ),
                            ),
                            value: isPublished,
                            activeColor: const Color(0xFFBC87FE),
                            onChanged: (hasGroups && selectedGroupCode != null)
                                ? (val) =>
                                      setModalState(() => isPublished = val)
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
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
                      content: Text("¡Ponle nombre a tu obra! 🦆"),
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
                      id: isEditing
                          ? widget.projectToLoad!.id
                          : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      artistName: artistController.text,
                      photoPaths: widget.capturedPhotos
                          .map((f) => f.path)
                          .toList(),
                      date: DateTime.now(),
                      isPublished: isPublished,
                      workshopCode: selectedGroupCode,
                    ),
                  );
                  if (context.mounted) {
                    Navigator.pop(context); // Cierra loading
                    Navigator.pop(context); // Cierra modal
                    Navigator.pop(context); // Vuelve al Home
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
    IconData icon, {
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(
        color: readOnly ? Colors.white38 : Colors.white,
        fontFamily: 'Lexend',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 10),
        prefixIcon: Icon(
          icon,
          color: readOnly ? Colors.white12 : const Color(0xFFBC87FE),
          size: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFBC87FE)),
        ),
        filled: readOnly,
        fillColor: readOnly ? Colors.black12 : Colors.transparent,
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
