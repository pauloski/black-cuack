import 'dart:io'; // Para manejar archivos en móvil
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  
  // VARIABLES PARA EL EFECTO CEBOLLA
  XFile? lastCapturedPhoto; // Guarda la última foto tomada
  double onionOpacity = 0.3; // Valor del DIMMER (0.0 a 1.0)

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      // Usamos la primera cámara disponible (generalmente la trasera en móvil, webcam en PC)
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
        lastCapturedPhoto = file; // Guardamos la foto para el efecto cebolla
      });
      print("Foto capturada: ${file.path}");
    } catch (e) {
      print("Error al capturar: $e");
    }
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
          // 1. CAPA BASE: Vista previa de la cámara en vivo
          Center(child: CameraPreview(controller!)),

          // 2. CAPA SUPERPUESTA: Efecto Cebolla (Foto anterior transparente)
          if (lastCapturedPhoto != null)
            Opacity(
              opacity: onionOpacity, // CONTROLADO POR EL DIMMER
              child: Center(
                child: kIsWeb
                    ? Image.network(lastCapturedPhoto!.path) // Si es Web
                    : Image.file(File(lastCapturedPhoto!.path)), // Si es Móvil
              ),
            ),

          // 3. CAPA DE INTERFAZ (UI)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // DIMMER (SLIDER) NEÓN PÚRPURA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.opacity, color: Color(0xFFBC87FE), size: 20),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFBC87FE), // Púrpura
                            inactiveTrackColor: Colors.white10,
                            thumbColor: const Color(0xFFC1FFFE), // Cian
                            overlayColor: const Color(0xFFC1FFFE).withOpacity(0.2),
                          ),
                          child: Slider(
                            value: onionOpacity,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (value) {
                              setState(() {
                                onionOpacity = value; // Actualizamos opacidad
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // BOTONES DE CONTROL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón Salir
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    
                    // BOTÓN DE CAPTURA CON SOMBRA NEÓN ROJA
                    GestureDetector(
                      onTap: _takePhoto, // Llama a la función de capturar
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D4D), // Rojo vibrante
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
                      ),
                    ),

                    // Botón Eliminar última foto (Para corregir errores)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4D4D), size: 30),
                      onPressed: () {
                        setState(() {
                          lastCapturedPhoto = null; // Borramos el efecto cebolla
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}