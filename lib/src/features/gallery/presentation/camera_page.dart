import 'dart:io';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/utils/video_creator.dart';
import 'package:gallery_saver/gallery_saver.dart';

// Importaciones de tus modelos y persistencia
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/core/persistence/project_storage.dart';
import 'package:blackcuack_studio/src/features/gallery/data/project_service.dart';

class CameraPage extends StatefulWidget {
  final QuackProject? projectToLoad; 
  const CameraPage({super.key, this.projectToLoad});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  
  // Instancia única del servicio
  final ProjectService _projectService = ProjectService(); 
  
  // --- ESTADO ---
  List<XFile> capturedPhotos = []; 
  XFile? lastCapturedPhoto; 
  double onionOpacity = 0.3;
  double fps = 12.0; 
  bool showGrid = false; 
  bool isPlaying = false; 
  int previewIndex = 0; 
  int? selectedIndex; 

  bool get isEditing => widget.projectToLoad != null;

  @override
  void initState() {
    super.initState();
    _initCamera();
    if (isEditing) {
      capturedPhotos = widget.projectToLoad!.photoPaths.map((path) => XFile(path)).toList();
      if (capturedPhotos.isNotEmpty) {
        lastCapturedPhoto = capturedPhotos.last;
      }
    }
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      controller = CameraController(cameras![0], ResolutionPreset.high);
      await controller!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return;
    try {
      final XFile file = await controller!.takePicture();
      setState(() {
        lastCapturedPhoto = file;
        capturedPhotos.add(file); 
        selectedIndex = null; 
      });
    } catch (e) { print("Error: $e"); }
  }

  void _playSequence() async {
    if (capturedPhotos.isEmpty) return;
    setState(() { 
      isPlaying = true; 
      previewIndex = 0; 
      selectedIndex = null; 
    });

    for (int i = 0; i < capturedPhotos.length; i++) {
      if (!mounted || !isPlaying) break;
      setState(() => previewIndex = i);
      await Future.delayed(Duration(milliseconds: (1000 / fps).round()));
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted && isPlaying) {
      _stopPlayback();
    }
  }

  void _stopPlayback() {
    setState(() => isPlaying = false);
  }

  Future<void> _exportVideo() async {
    if (capturedPhotos.isEmpty) return;
    double progress = 0;
    void Function(double)? updateProgressDialog; 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          updateProgressDialog = (val) => setDialogState(() => progress = val);
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFFBC87FE), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("COCINANDO TU QUACK", 
                  style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFC1FFFE))),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  color: const Color(0xFFBC87FE),
                ),
                const SizedBox(height: 10),
                Text("${(progress * 100).toInt()}%", 
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );

    try {
      await VideoCreator.export(
        capturedPhotos.map((x) => x.path).toList(),
        fps,
        onProgress: (val) {
          if (updateProgressDialog != null) updateProgressDialog!(val);
        },
      );
      if (mounted) Navigator.pop(context); 
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("AJUSTES DE CÁMARA", style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFC1FFFE), fontSize: 20)),
                  const SizedBox(height: 20),
                  _buildSettingRow(Icons.opacity, "CEBOLLA", onionOpacity, (v) {
                    setModalState(() => onionOpacity = v);
                    setState(() => onionOpacity = v);
                  }),
                  const SizedBox(height: 20),
                  _buildSettingRow(Icons.speed, "VELOCIDAD (${fps.toInt()} FPS)", fps / 24, (v) {
                    double newFps = (v * 24).clamp(1, 24);
                    setModalState(() => fps = newFps);
                    setState(() => fps = newFps);
                  }, minLabel: "1", maxLabel: "24"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (capturedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Toma algunas fotos primero!")),
      );
      return;
    }

    if (isEditing) {
      final updatedProject = QuackProject(
        id: widget.projectToLoad!.id,
        name: widget.projectToLoad!.name,
        photoPaths: capturedPhotos.map((xfile) => xfile.path).toList(),
        date: DateTime.now(),
      );

      await ProjectStorage.saveProject(updatedProject);
      await _projectService.saveProject(updatedProject); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Cambios sincronizados!")),
        );
        Navigator.pop(context);
      }
    } else {
      _showNameDialog();
    }
  }
void _showNameDialog() {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFC1FFFE), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "¡NOMBRA TU QUACK!",
          style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFBC87FE)),
          textAlign: TextAlign.center,
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'Lexend'),
          decoration: const InputDecoration(
            hintText: "Ej: Mi Pato Aventurero",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC1FFFE))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.redAccent, fontFamily: 'Lexend')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC1FFFE)),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                // 1. Mostrar pantalla de carga (evita que parezca colgado)
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC1FFFE)),
                  ),
                );

                final nuevoProyecto = QuackProject(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  photoPaths: capturedPhotos.map((xfile) => xfile.path).toList(),
                  date: DateTime.now(),
                );

                try {
                  // 2. Guardar localmente
                  await ProjectStorage.saveProject(nuevoProyecto);
                  
                  // 3. Subir a la nube (Storage + Firestore)
                  await _projectService.saveProject(nuevoProyecto); 

                  if (mounted) {
                    Navigator.pop(context); // Quita el cargador
                    Navigator.pop(context); // Cierra el diálogo de nombre
                    Navigator.pop(context); // Vuelve a la Home
                  }
                } catch (e) {
                  if (mounted) Navigator.pop(context); // Quita el cargador si hay error
                  print("Error al guardar: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error al subir a la nube: $e")),
                  );
                }
              }
            },
            child: const Text("GUARDAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Lexend')),
          ),
        ],
      ),
    );
  }
 
  Widget _buildSettingRow(IconData icon, String label, double value, Function(double) onChanged, {String minLabel = "0", String maxLabel = "1"}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Lexend', color: Colors.white, fontSize: 12)),
        Row(
          children: [
            Icon(icon, color: const Color(0xFFBC87FE), size: 20),
            Expanded(
              child: Slider(
                value: value,
                activeColor: const Color(0xFFBC87FE),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFFC1FFFE))));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: Stack(
                children: [
                  CameraPreview(controller!),
                  if (showGrid && !isPlaying)
                    Positioned.fill(child: CustomPaint(painter: GridPainter())),
                  if (lastCapturedPhoto != null && !isPlaying && selectedIndex == null)
                    Opacity(
                      opacity: onionOpacity,
                      child: kIsWeb 
                          ? Image.network(lastCapturedPhoto!.path, fit: BoxFit.cover) 
                          : Image.file(File(lastCapturedPhoto!.path), fit: BoxFit.cover),
                    ),
                  if (selectedIndex != null)
                    Container(
                      color: Colors.black,
                      width: double.infinity, height: double.infinity,
                      child: kIsWeb 
                          ? Image.network(capturedPhotos[selectedIndex!].path, fit: BoxFit.contain) 
                          : Image.file(File(capturedPhotos[selectedIndex!].path), fit: BoxFit.contain),
                    ),
                ],
              ),
            ),
          ),

          if (!isPlaying)
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ),
                  ),

                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: Icon(Icons.grid_4x4, color: showGrid ? const Color(0xFFC1FFFE) : Colors.white),
                                onPressed: () => setState(() => showGrid = !showGrid),
                              ),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(icon: const Icon(Icons.tune, color: Colors.white), onPressed: _showSettings),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              backgroundColor: const Color(0xFFBC87FE).withOpacity(0.2),
                              child: IconButton(
                                icon: const Icon(Icons.ios_share, color: Color(0xFFBC87FE)),
                                onPressed: _exportVideo,
                              ),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              backgroundColor: const Color(0xFFC1FFFE).withOpacity(0.2),
                              child: IconButton(
                                icon: Icon(isEditing ? Icons.save : Icons.check, color: const Color(0xFFC1FFFE)),
                                onPressed: _saveChanges,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTimeline(),
                      _buildActionButtons(),
                    ],
                  ),
                ],
              ),
            ),

          if (isPlaying) _buildCinemaMode(),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 15),
      child: capturedPhotos.isEmpty 
        ? const Center(child: Text("LISTO PARA EL QUACK", style: TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'Lexend')))
        : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: capturedPhotos.length,
            itemBuilder: (context, index) {
              final isCurrentSelected = index == selectedIndex;
              final isLast = index == capturedPhotos.length - 1;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = isCurrentSelected ? null : index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrentSelected 
                          ? const Color(0xFFBC87FE) 
                          : (isLast && selectedIndex == null ? const Color(0xFFC1FFFE) : Colors.white10),
                      width: isCurrentSelected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: kIsWeb ? Image.network(capturedPhotos[index].path, fit: BoxFit.cover) : Image.file(File(capturedPhotos[index].path), fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              selectedIndex != null ? Icons.delete_forever : Icons.undo,
              color: const Color(0xFFFF4D4D), 
              size: selectedIndex != null ? 35 : 30
            ), 
            onPressed: () {
              if (capturedPhotos.isEmpty) return;
              if (selectedIndex != null) {
                setState(() {
                  capturedPhotos.removeAt(selectedIndex!);
                  selectedIndex = null;
                  lastCapturedPhoto = capturedPhotos.isEmpty ? null : capturedPhotos.last;
                });
              } else {
                setState(() { 
                  capturedPhotos.removeLast(); 
                  lastCapturedPhoto = capturedPhotos.isEmpty ? null : capturedPhotos.last; 
                });
              }
            }
          ),
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              height: 75, width: 75,
              decoration: const BoxDecoration(color: Color(0xFFFF4D4D), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 15)]),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 35),
            ),
          ),
          IconButton(icon: const Icon(Icons.play_circle_fill, color: Color(0xFFC1FFFE), size: 50), onPressed: _playSequence),
        ],
      ),
    );
  }

  Widget _buildCinemaMode() {
    return GestureDetector(
      onTap: _stopPlayback,
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Center(
              child: kIsWeb 
                ? Image.network(capturedPhotos[previewIndex].path, fit: BoxFit.contain) 
                : Image.file(File(capturedPhotos[previewIndex].path), fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${previewIndex + 1}/${capturedPhotos.length}",
                  style: const TextStyle(color: Colors.white24, fontSize: 12, fontFamily: 'Lexend'),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.5,
                  child: IconButton(
                    icon: const Icon(Icons.stop_circle, color: Color(0xFFFF4D4D), size: 80),
                    onPressed: _stopPlayback,
                  ),
                ),
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
    final paint = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}