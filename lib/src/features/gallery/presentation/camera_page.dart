import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

// Utilidades y Modelos
import 'package:blackcuack_studio/src/core/utils/video_creator.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/core/persistence/project_storage.dart';
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

  // ✅ LLAVE MAESTRA para conectar con el Modal del Viewer
  final GlobalKey<CameraViewerState> _cameraViewerKey =
      GlobalKey<CameraViewerState>();

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
      // Cargamos las fotos existentes del proyecto
      capturedPhotos = widget.projectToLoad!.photoPaths
          .map((path) => XFile(path))
          .toList();
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
    } catch (e) {
      print("Error captura: $e");
    }
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
    if (mounted && isPlaying) _stopPlayback();
  }

  void _stopPlayback() => setState(() => isPlaying = false);

  // --- EXPORTACIÓN ---
  Future<void> _exportVideo() async {
    if (capturedPhotos.isEmpty) return;
  }

  // --- CONFIGURACIÓN ---
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  "VELOCIDAD (FPS)",
                  style: TextStyle(
                    color: Color(0xFFC1FFFE),
                    fontFamily: 'LuckiestGuy',
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: fps,
                      min: 1,
                      max: 24,
                      divisions: 23,
                      activeColor: const Color(0xFFBC87FE),
                      onChanged: (v) {
                        setModalState(() => fps = v);
                        setState(() => fps = v);
                      },
                    ),
                  ),
                  Text(
                    "${fps.round()}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  "PAPEL CEBOLLA",
                  style: TextStyle(
                    color: Color(0xFFC1FFFE),
                    fontFamily: 'LuckiestGuy',
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                children: [
                  const Text(
                    "SIN OPACIDAD",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontFamily: 'Lexend',
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: onionOpacity,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFFC1FFFE),
                      onChanged: (v) {
                        setModalState(() => onionOpacity = v);
                        setState(() => onionOpacity = v);
                      },
                    ),
                  ),
                  const Text(
                    "TRANSPARENTE",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ DISPARADOR DEL MODAL
  void _handleSaveAction() {
    if (capturedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Toma algunas fotos antes de guardar! 🦆"),
        ),
      );
      return;
    }
    _cameraViewerKey.currentState?.showSaveDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ AQUÍ ESTÁ EL ARREGLO: Pasamos 'projectToLoad' al viewer
          CameraViewer(
            key: _cameraViewerKey,
            controller: controller!,
            showGrid: showGrid,
            isPlaying: isPlaying,
            lastCapturedPhoto: lastCapturedPhoto,
            onionOpacity: onionOpacity,
            selectedIndex: selectedIndex,
            capturedPhotos: capturedPhotos,
            projectToLoad:
                widget.projectToLoad, // 👈 ¡ESTA ERA LA PIEZA FALTRANTE!
          ),

          if (!isPlaying)
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Column(
                    children: [
                      CameraControls(
                        isEditing: isEditing,
                        showGrid: showGrid,
                        onToggleGrid: () =>
                            setState(() => showGrid = !showGrid),
                        onShowSettings: _showSettings,
                        onExport: _exportVideo,
                        onSave: _handleSaveAction,
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
                            lastCapturedPhoto = capturedPhotos.isEmpty
                                ? null
                                : capturedPhotos.last;
                          });
                        },
                        selectedIndex: selectedIndex,
                        hasPhotos: capturedPhotos.isNotEmpty,
                      ),
                      CameraTimeline(
                        capturedPhotos: capturedPhotos,
                        selectedIndex: selectedIndex,
                        onPhotoTap: (index) =>
                            setState(() => selectedIndex = index),
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
          Center(
            child: kIsWeb
                ? Image.network(capturedPhotos[previewIndex].path)
                : Image.file(File(capturedPhotos[previewIndex].path)),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red, size: 80),
              onPressed: _stopPlayback,
            ),
          ),
        ],
      ),
    );
  }
}
