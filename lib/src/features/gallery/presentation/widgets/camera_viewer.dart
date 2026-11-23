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
  /// Relación del MARCO del proyecto (9:16 → 0.5625, 16:9 → 1.777). El visor se
  /// recorta a este aspecto (cover), así se ve exactamente lo que se captura y
  /// exporta, sin bandas negras. Si es null, cae al aspecto del sensor.
  final double? frameAspect;
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
    this.frameAspect,
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

  /// Vista previa que CUBRE el marco de recorte `bw`×`bh` (no la pantalla): la
  /// zona del marco muestra EXACTAMENTE el recorte central al aspecto del
  /// proyecto —lo que se captura y con lo que calza el papel cebolla— y el
  /// excedente del sensor se derrama (atenuado) fuera del marco, recortado por
  /// el Stack. Así el visor se llena todo lo posible sin mentir sobre el encuadre.
  Widget _coveredPreview(double bw, double bh) {
    final camAspect = widget.controller.value.aspectRatio;
    // Escala que hace que el sensor cubra el marco (BoxFit.cover sobre bw×bh).
    final double scale = (bw / camAspect) > bh ? (bw / camAspect) : bh;
    final double pw = camAspect * scale;
    final double ph = scale;
    return OverflowBox(
      maxWidth: pw,
      maxHeight: ph,
      child: SizedBox(
        width: pw,
        height: ph,
        child: CameraPreview(widget.controller),
      ),
    );
  }

  /// Contenido que vive DENTRO del marco de recorte (lo que se captura y
  /// exporta): cuadrícula, papel cebolla y el cuadro seleccionado. Alineado al
  /// marco del proyecto, recortado a él.
  Widget _cropContent(double frameAspect) {
    return Center(
      child: AspectRatio(
        aspectRatio: frameAspect,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.showGrid && !widget.isPlaying)
                Positioned.fill(child: CustomPaint(painter: GridPainter())),
              // Papel cebolla: más reciente encima, más antiguo abajo.
              if (widget.onionLayers > 0 &&
                  widget.capturedPhotos.isNotEmpty &&
                  !widget.isPlaying &&
                  widget.selectedIndex == null)
                for (int i = widget.onionLayers - 1; i >= 0; i--)
                  if (widget.capturedPhotos.length - 1 - i >= 0)
                    _buildOnionLayer(
                      widget
                          .capturedPhotos[widget.capturedPhotos.length - 1 - i],
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Marco del proyecto (9:16 / 16:9); fallback al aspecto del sensor.
    final double frameAspect =
        widget.frameAspect ?? widget.controller.value.aspectRatio;
    // Pantalla completa: la cámara se derrama por todo el visor; un atenuado
    // marca la zona que realmente se captura (el marco del proyecto, centrado).
    return LayoutBuilder(
      builder: (context, c) {
        // Marco de recorte = relación del proyecto, lo más grande que quepa.
        double bw = c.maxWidth;
        double bh = c.maxHeight;
        if (bw / bh > frameAspect) {
          bw = bh * frameAspect;
        } else {
          bh = bw / frameAspect;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            // 1) Cámara: cubre el marco; el excedente del sensor se derrama.
            Center(child: _coveredPreview(bw, bh)),
            // 2) Atenúa lo que queda FUERA del marco de recorte.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CaptureMaskPainter(
                    aspect: frameAspect,
                    dim: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            // 3) Contenido dentro del marco (cuadrícula, cebolla, seleccionado).
            _cropContent(frameAspect),
            // 4) Borde del marco de recorte.
            Center(
              child: AspectRatio(
                aspectRatio: frameAspect,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Pinta un velo oscuro sobre todo MENOS el marco de recorte centrado (la zona
/// que se captura queda clara; el resto, atenuado). El marco tiene la relación
/// del proyecto y se centra en el visor.
class _CaptureMaskPainter extends CustomPainter {
  final double aspect;
  final Color dim;
  _CaptureMaskPainter({required this.aspect, required this.dim});

  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width;
    double h = size.height;
    if (w / h > aspect) {
      w = h * aspect; // más ancho que el marco → limitar ancho
    } else {
      h = w / aspect; // más alto que el marco → limitar alto
    }
    final rect = Rect.fromLTWH(
        (size.width - w) / 2, (size.height - h) / 2, w, h);
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = dim);
  }

  @override
  bool shouldRepaint(covariant _CaptureMaskPainter old) =>
      old.aspect != aspect || old.dim != dim;
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
