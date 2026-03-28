import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // Para compartir por WhatsApp

// Utilidades y Modelos
import 'package:blackcuack_studio/src/core/utils/video_creator.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/core/persistence/project_storage.dart';

// Importación de tu servicio funcional
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart'; 

// Widgets Refactorizados
import 'package:blackcuack_studio/src/features/gallery/presentation/widgets/camera_viewer.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/widgets/camera_controls.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/widgets/camera_timeline.dart';

class CameraPage extends StatefulWidget {
  final QuackProject? projectToLoad; 
  const CameraPage({super.key, this.projectToLoad});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  List<CameraDescription>? cameras;
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
      if (capturedPhotos.isNotEmpty) lastCapturedPhoto = capturedPhotos.last;
    }
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      controller = CameraController(cameras![0], ResolutionPreset.high);
      await controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // --- LÓGICA DE CAPTURA Y REPRODUCCIÓN ---
  Future<void> _takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return;
    try {
      final XFile file = await controller!.takePicture();
      setState(() {
        lastCapturedPhoto = file;
        capturedPhotos.add(file); 
        selectedIndex = null; 
      });
    } catch (e) { print("Error captura: $e"); }
  }

  void _playSequence() async {
    if (capturedPhotos.isEmpty) return;
    setState(() { isPlaying = true; previewIndex = 0; selectedIndex = null; });
    for (int i = 0; i < capturedPhotos.length; i++) {
      if (!mounted || !isPlaying) break;
      setState(() => previewIndex = i);
      await Future.delayed(Duration(milliseconds: (1000 / fps).round()));
    }
    await Future.delayed(const Duration(seconds: 1));
    if (mounted && isPlaying) _stopPlayback();
  }

  void _stopPlayback() => setState(() => isPlaying = false);

  // --- EXPORTACIÓN (AJUSTADA AL NUEVO VIDEOCREATOR) ---
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("COCINANDO TU QUACK", style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFC1FFFE))),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: progress, color: const Color(0xFFBC87FE)),
                const SizedBox(height: 10),
                Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );

    try {
      // Llamamos al export que ahora devuelve un String?
      final String? videoPath = await VideoCreator.export(
        capturedPhotos.map((x) => x.path).toList(), 
        fps,
        onProgress: (val) => updateProgressDialog?.call(val),
      );

      if (mounted) Navigator.pop(context); // Cerrar cargador

      // Si estamos en móvil y hay ruta, compartimos
      if (!kIsWeb && videoPath != null) {
        await Share.shareXFiles([XFile(videoPath)], text: '¡Mira mi animación en Blackcuack Studio! 🦆');
      }
      // En Web no hacemos nada extra aquí porque el VideoCreator ya dispara la descarga del GIF
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Error exportando: $e");
    }
  }

  // --- AJUSTES Y GUARDADO ---
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(child: Text("VELOCIDAD (FPS)", style: TextStyle(color: Color(0xFFC1FFFE), fontFamily: 'LuckiestGuy', fontSize: 16))),
              Row(
                children: [
                  Expanded(child: Slider(value: fps, min: 1, max: 24, divisions: 23, activeColor: const Color(0xFFBC87FE), onChanged: (v) {
                    setModalState(() => fps = v);
                    setState(() => fps = v);
                  })),
                  Text("${fps.round()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 30),
              const Center(child: Text("PAPEL CEBOLLA", style: TextStyle(color: Color(0xFFC1FFFE), fontFamily: 'LuckiestGuy', fontSize: 16))),
              Row(
                children: [
                  const Text("SIN OPACIDAD", style: TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'Lexend')),
                  Expanded(child: Slider(value: onionOpacity, min: 0.0, max: 1.0, activeColor: const Color(0xFFC1FFFE), onChanged: (v) {
                    setModalState(() => onionOpacity = v);
                    setState(() => onionOpacity = v);
                  })),
                  const Text("TRANSPARENTE", style: TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'Lexend')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (capturedPhotos.isEmpty) return;
    if (isEditing) {
      final updated = QuackProject(
        id: widget.projectToLoad!.id,
        name: widget.projectToLoad!.name,
        photoPaths: capturedPhotos.map((x) => x.path).toList(),
        date: DateTime.now(),
      );
      await ProjectStorage.saveProject(updated);
      await _projectService.saveProject(updated);
      if (mounted) Navigator.pop(context);
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
        title: const Text("¡NOMBRA TU QUACK!", style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFBC87FE))),
        content: TextField(controller: nameController, autofocus: true, style: const TextStyle(color: Colors.white)),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
                final nuevo = QuackProject(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  photoPaths: capturedPhotos.map((x) => x.path).toList(),
                  date: DateTime.now(),
                );
                await ProjectStorage.saveProject(nuevo);
                await _projectService.saveProject(nuevo);
                if (mounted) { Navigator.pop(context); Navigator.pop(context); Navigator.pop(context); }
              }
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraViewer(
            controller: controller!,
            showGrid: showGrid,
            isPlaying: isPlaying,
            lastCapturedPhoto: lastCapturedPhoto,
            onionOpacity: onionOpacity,
            selectedIndex: selectedIndex,
            capturedPhotos: capturedPhotos,
          ),

          if (!isPlaying)
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ),
                  Column(
                    children: [
                      CameraControls(
                        isEditing: isEditing,
                        showGrid: showGrid,
                        onToggleGrid: () => setState(() => showGrid = !showGrid),
                        onShowSettings: _showSettings,
                        onExport: _exportVideo,
                        onSave: _saveChanges,
                        onTakePhoto: _takePhoto,
                        onPlay: _playSequence,
                        onUndo: () {
                          setState(() {
                            if (selectedIndex != null) {
                              capturedPhotos.removeAt(selectedIndex!);
                              selectedIndex = null;
                            } else {
                              capturedPhotos.removeLast();
                            }
                            lastCapturedPhoto = capturedPhotos.isEmpty ? null : capturedPhotos.last;
                          });
                        },
                        selectedIndex: selectedIndex,
                        hasPhotos: capturedPhotos.isNotEmpty,
                      ),
                      CameraTimeline(
                        capturedPhotos: capturedPhotos,
                        selectedIndex: selectedIndex,
                        onPhotoTap: (index) => setState(() => selectedIndex = index),
                      ),
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

  Widget _buildCinemaMode() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(child: kIsWeb ? Image.network(capturedPhotos[previewIndex].path) : Image.file(File(capturedPhotos[previewIndex].path))),
          Positioned(bottom: 50, left: 0, right: 0, child: IconButton(icon: const Icon(Icons.stop_circle, color: Colors.red, size: 80), onPressed: _stopPlayback)),
        ],
      ),
    );
  }
}