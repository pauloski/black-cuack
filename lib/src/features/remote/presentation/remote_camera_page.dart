import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/remote/data/remote_session_service.dart';

class RemoteCameraPage extends StatefulWidget {
  final String sessionCode;
  const RemoteCameraPage({super.key, required this.sessionCode});

  @override
  State<RemoteCameraPage> createState() => _RemoteCameraPageState();
}

class _RemoteCameraPageState extends State<RemoteCameraPage> {
  CameraController? _controller;
  final _service = RemoteSessionService();

  int _framesSent = 0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndSend() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isUploading) return;

    setState(() => _isUploading = true);
    try {
      final photo = await _controller!.takePicture();
      await _service.uploadFrame(widget.sessionCode, photo.path);
      if (mounted) setState(() => _framesSent++);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enviando frame: $e',
                style: const TextStyle(fontFamily: 'Lexend')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _pill(
                    Icons.close,
                    'SALIR',
                    Colors.white54,
                    () => Navigator.pop(context),
                  ),
                  _pill(
                    Icons.wifi,
                    widget.sessionCode,
                    AppColors.primary,
                    null,
                  ),
                  _pill(
                    Icons.photo_library_outlined,
                    '$_framesSent enviados',
                    AppColors.secondary,
                    null,
                  ),
                ],
              ),
            ),
          ),

          // Capture button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _isUploading
                    ? const SizedBox(
                        height: 80,
                        width: 80,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _captureAndSend,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                const SizedBox(height: 10),
                const Text(
                  'CAPTURAR Y ENVIAR',
                  style: TextStyle(
                    color: Colors.white38,
                    fontFamily: 'Lexend',
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontFamily: 'Lexend',
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
