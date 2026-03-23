import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  
  // --- LÓGICA DE CAPTURA Y TIMELINE ---
  List<XFile> capturedPhotos = []; 
  XFile? lastCapturedPhoto; 
  double onionOpacity = 0.3;

  // --- LÓGICA DE MODO PLAY ---
  bool isPlaying = false; 
  int previewIndex = 0; 

  @override
  void initState() {
    super.initState();
    _initCamera();
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

  // FUNCIÓN PARA CAPTURAR FOTO
  Future<void> _takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      final XFile file = await controller!.takePicture();
      setState(() {
        lastCapturedPhoto = file;
        capturedPhotos.add(file); 
      });
    } catch (e) {
      print("Error al capturar: $e");
    }
  }

  // FUNCIÓN PARA REPRODUCIR LA SECUENCIA
  void _playSequence() async {
    if (capturedPhotos.isEmpty) return;

    setState(() {
      isPlaying = true;
      previewIndex = 0;
    });

    // Reproducción a 8 cuadros por segundo aprox (125ms)
    for (int i = 0; i < capturedPhotos.length; i++) {
      if (!mounted || !isPlaying) break;
      setState(() {
        previewIndex = i;
      });
      await Future.delayed(const Duration(milliseconds: 125));
    }

    // Esperar un segundo al final antes de volver
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC1FFFE))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CÁMARA EN VIVO
          Center(child: CameraPreview(controller!)),

          // 2. EFECTO CEBOLLA
          if (lastCapturedPhoto != null && !isPlaying)
            Opacity(
              opacity: onionOpacity,
              child: Center(
                child: kIsWeb
                    ? Image.network(lastCapturedPhoto!.path)
                    : Image.file(File(lastCapturedPhoto!.path)),
              ),
            ),

          // 3. INTERFAZ DE USUARIO (CÁMARA)
          if (!isPlaying)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Barra superior: Dimmer
                Container(
                  padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.opacity, color: Color(0xFFBC87FE)),
                      Expanded(
                        child: Slider(
                          value: onionOpacity,
                          activeColor: const Color(0xFFBC87FE),
                          onChanged: (v) => setState(() => onionOpacity = v),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Parte inferior: Timeline + Botones
                Column(
                  children: [
                    Container(
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: capturedPhotos.isEmpty 
                        ? const Center(child: Text("¡Toma tu primera foto!", style: TextStyle(color: Colors.white24, fontFamily: 'Lexend')))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: capturedPhotos.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: index == capturedPhotos.length - 1 
                                        ? const Color(0xFFC1FFFE) 
                                        : Colors.white24,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: kIsWeb 
                                    ? Image.network(capturedPhotos[index].path, fit: BoxFit.cover)
                                    : Image.file(File(capturedPhotos[index].path), fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.undo, color: Color(0xFFFF4D4D), size: 30),
                            onPressed: () {
                              if (capturedPhotos.isNotEmpty) {
                                setState(() {
                                  capturedPhotos.removeLast();
                                  lastCapturedPhoto = capturedPhotos.isEmpty ? null : capturedPhotos.last;
                                });
                              }
                            },
                          ),
                          
                          GestureDetector(
                            onTap: _takePhoto,
                            child: Container(
                              height: 70, width: 70,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF4D4D),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 15)],
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 35),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.play_circle_fill, color: Color(0xFFC1FFFE), size: 45),
                            onPressed: _playSequence,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

          // 4. --- MODO CINE (Solo se ve al dar Play) ---
          if (isPlaying)
            Container(
              color: Colors.black,
              child: Stack(
                children: [
                  Center(
                    child: kIsWeb
                        ? Image.network(capturedPhotos[previewIndex].path)
                        : Image.file(File(capturedPhotos[previewIndex].path)),
                  ),
                  // Info arriba
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        "REPRODUCIENDO: ${previewIndex + 1} / ${capturedPhotos.length}",
                        style: const TextStyle(
                          fontFamily: 'Lexend', 
                          color: Color(0xFFC1FFFE),
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                  // Botón Stop abajo
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.stop_circle, color: Color(0xFFFF4D4D), size: 70),
                        onPressed: () => setState(() => isPlaying = false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}