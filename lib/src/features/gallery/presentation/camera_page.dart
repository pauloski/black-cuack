import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:blackcuack_studio/src/core/config/feature_flags.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/core/utils/video_creator.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/remote/data/remote_session_service.dart';
import 'package:blackcuack_studio/src/features/remote/presentation/widgets/qr_invite_dialog.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/widgets/camera_viewer.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/widgets/camera_timeline.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/erase_tool_page.dart';

class CameraPage extends StatefulWidget {
  final QuackProject? projectToLoad;
  final bool startRemoteSession;
  const CameraPage({
    super.key,
    this.projectToLoad,
    this.startRemoteSession = false,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  List<CameraDescription>? cameras;

  final GlobalKey<CameraViewerState> _cameraViewerKey =
      GlobalKey<CameraViewerState>();

  List<XFile> capturedPhotos = [];
  XFile? lastCapturedPhoto;
  double onionOpacity = 0.3;
  int _onionLayers = 1;
  double fps = 12.0;
  bool showGrid = false;
  bool isPlaying = false;
  int previewIndex = 0;
  int? selectedIndex;
  bool _isExporting = false;
  double _exportProgress = 0.0;

  final _remoteService = RemoteSessionService();
  String? _sessionCode;
  StreamSubscription<List<String>>? _remoteSub;
  final Set<String> _knownRemoteUrls = {};

  bool get isEditing => widget.projectToLoad != null;
  bool get hasPhotos => capturedPhotos.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initCamera();
    if (isEditing) {
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
      if (mounted) {
        setState(() {});
        if (kEnableIgniteFeatures && widget.startRemoteSession) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _openRemoteSession());
        }
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _remoteSub?.cancel();
    if (_sessionCode != null) _remoteService.closeSession(_sessionCode!);
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
    } catch (e) {
      debugPrint("Error captura: $e");
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

  void _cycleOnionLayers() =>
      setState(() => _onionLayers = (_onionLayers + 1) % 4);

  void _handleUndo() {
    if (!hasPhotos) return;
    setState(() {
      if (selectedIndex != null) {
        capturedPhotos.removeAt(selectedIndex!);
        selectedIndex = null;
      } else {
        capturedPhotos.removeLast();
      }
      lastCapturedPhoto = capturedPhotos.isEmpty ? null : capturedPhotos.last;
    });
  }

  void _handleSaveAction() {
    if (capturedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Toma algunas fotos antes de guardar")),
      );
      return;
    }
    _cameraViewerKey.currentState?.showSaveDialog(context);
  }

  void _exportVideo() {
    if (capturedPhotos.isEmpty) return;
    _showExportDialog();
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'EXPORTAR COMO',
              style: TextStyle(
                fontFamily: 'Lexend',
                color: AppColors.primary,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),
            _exportOption(
              icon: Icons.gif_box_rounded,
              title: 'GIF Animado',
              subtitle: 'Compatible en todos los dispositivos',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _askFilenameAndExport(ExportFormat.gif, 'gif');
              },
            ),
            const SizedBox(height: 12),
            _exportOption(
              icon: Icons.movie_rounded,
              title: 'Video MP4',
              subtitle: kIsWeb
                  ? '🛠️ En corrección — disponible pronto'
                  : 'Alta calidad, ideal para compartir',
              color: AppColors.secondary,
              onTap: () {
                Navigator.pop(context);
                if (kIsWeb) {
                  _showSnack('MP4 en corrección 🛠️ — disponible pronto',
                      AppColors.secondary);
                  return;
                }
                _askFilenameAndExport(ExportFormat.mp4, 'mp4');
              },
            ),
            const SizedBox(height: 12),
            _exportOption(
              icon: Icons.folder_zip_rounded,
              title: 'Secuencia de Imágenes',
              subtitle: kIsWeb
                  ? '🛠️ En corrección — disponible pronto'
                  : 'Todos los frames en un archivo .zip',
              color: AppColors.green,
              onTap: () {
                Navigator.pop(context);
                if (kIsWeb) {
                  _showSnack('ZIP en corrección 🛠️ — disponible pronto',
                      AppColors.green);
                  return;
                }
                _askFilenameAndExport(ExportFormat.imageSequence, 'zip');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _askFilenameAndExport(ExportFormat format, String ext) {
    final ctrl = TextEditingController(
      text: 'mi_quack_${DateTime.now().millisecondsSinceEpoch}',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'GUARDAR COMO',
          style: TextStyle(fontFamily: 'Lexend', color: AppColors.primary, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white, fontFamily: 'Lexend', fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Nombre del archivo',
                labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                suffixText: '.$ext',
                suffixStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final name = ctrl.text.trim().isEmpty ? 'mi_animacion' : ctrl.text.trim();
              Navigator.pop(context);
              _runExport(format, filename: name);
            },
            icon: const Icon(Icons.download_rounded, color: Colors.black, size: 18),
            label: const Text('EXPORTAR', style: TextStyle(fontFamily: 'Lexend', color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _exportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontFamily: 'Lexend', fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontFamily: 'Lexend', fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _runExport(ExportFormat format, {required String filename}) async {
    setState(() { _isExporting = true; _exportProgress = 0.0; });
    try {
      final paths = capturedPhotos.map((f) => f.path).toList();
      final result = await VideoCreator.exportAs(
        format, paths, fps,
        filename: filename,
        onProgress: (p) => setState(() => _exportProgress = p),
      );
      if (!mounted) return;
      if (result == null) {
        // Nunca descargamos un archivo vacío: si no se generó contenido, avisamos.
        _showSnack(
          'Exportación en corrección 🛠️ — no se generó ningún archivo',
          AppColors.danger,
        );
      } else if (kIsWeb) {
        _showSnack('Archivo guardado en tu carpeta de Descargas', AppColors.primary);
      } else {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(result)], text: '¡Mi animación Blackcuack!'),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Lexend')), backgroundColor: color),
    );
  }

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
              const Text('VELOCIDAD (FPS)',
                style: TextStyle(color: AppColors.primary, fontFamily: 'Lexend', fontSize: 16)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: fps, min: 1, max: 24, divisions: 23,
                      activeColor: AppColors.secondary,
                      onChanged: (v) { setModalState(() => fps = v); setState(() => fps = v); },
                    ),
                  ),
                  Text('${fps.round()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('PAPEL CEBOLLA',
                style: TextStyle(color: AppColors.primary, fontFamily: 'Lexend', fontSize: 16)),
              Row(
                children: [
                  const Text('SIN OPACIDAD',
                    style: TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'Lexend')),
                  Expanded(
                    child: Slider(
                      value: onionOpacity, min: 0.0, max: 1.0,
                      activeColor: AppColors.primary,
                      onChanged: (v) { setModalState(() => onionOpacity = v); setState(() => onionOpacity = v); },
                    ),
                  ),
                  const Text('OPACO',
                    style: TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'Lexend')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRemoteSession() async {
    if (_sessionCode != null) { _showRemoteDialog(); return; }
    final code = await _remoteService.createSession();
    setState(() => _sessionCode = code);
    _remoteSub = _remoteService.getFrameUrlsStream(code).listen((urls) {
      for (final url in urls) {
        if (!_knownRemoteUrls.contains(url)) {
          _knownRemoteUrls.add(url);
          setState(() {
            final xf = XFile(url);
            capturedPhotos.add(xf);
            lastCapturedPhoto = xf;
          });
        }
      }
    });
    _showRemoteDialog();
  }

  void _showRemoteDialog() {
    if (_sessionCode == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => QrInviteDialog(
        sessionCode: _sessionCode!,
        frameStream: _remoteService.getFrameUrlsStream(_sessionCode!),
        onClose: () { Navigator.pop(context); _closeRemoteSession(); },
      ),
    );
  }

  void _closeRemoteSession() {
    if (_sessionCode == null) return;
    _remoteService.closeSession(_sessionCode!);
    _remoteSub?.cancel();
    _remoteSub = null;
    setState(() => _sessionCode = null);
  }

  Future<void> _openEraseTool() async {
    if (!hasPhotos) return;
    final result = await Navigator.push<List<XFile>>(
      context,
      MaterialPageRoute(
        builder: (_) => EraseToolPage(
          frames: capturedPhotos,
          workingFrameIndex: selectedIndex ?? (capturedPhotos.length - 1),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        capturedPhotos = result;
        lastCapturedPhoto = capturedPhotos.isNotEmpty ? capturedPhotos.last : null;
        selectedIndex = null;
      });
      _showSnack('Soporte borrado en ${result.length} frames', AppColors.green);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (isPlaying) return _buildCinemaMode();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildCameraArea()),
                CameraTimeline(
                  capturedPhotos: capturedPhotos,
                  selectedIndex: selectedIndex,
                  onPhotoTap: (i) => setState(() => selectedIndex = i),
                ),
              ],
            ),
          ),
        ),
        if (_isExporting) _buildExportOverlay(),
      ],
    );
  }

  Widget _buildTopBar() {
    final projectName = widget.projectToLoad?.name ?? 'Mi Animación';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              children: [
                Text(projectName,
                  style: const TextStyle(
                    color: Colors.white, fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600, fontSize: 15,
                  )),
                const SizedBox(width: 5),
                const Icon(Icons.edit_outlined, color: Colors.white24, size: 13),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              selectedIndex != null ? Icons.delete_forever : Icons.undo_rounded,
              color: hasPhotos ? Colors.white60 : Colors.white24,
              size: 22,
            ),
            onPressed: hasPhotos ? _handleUndo : null,
            tooltip: selectedIndex != null ? 'Eliminar frame' : 'Deshacer',
          ),
          // IGNITE (borrado de soportes): oculto tras el flag.
          if (kEnableIgniteFeatures)
            IconButton(
              icon: Icon(
                Icons.auto_fix_high_rounded,
                color: hasPhotos ? AppColors.secondary : Colors.white24,
                size: 20,
              ),
              onPressed: hasPhotos ? _openEraseTool : null,
              tooltip: 'Borrar soporte',
            ),
          IconButton(
            icon: Icon(Icons.ios_share,
              color: hasPhotos ? Colors.white60 : Colors.white24, size: 20),
            onPressed: hasPhotos ? _exportVideo : null,
            tooltip: 'Exportar',
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _handleSaveAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_rounded, color: Colors.black, size: 15),
                  SizedBox(width: 5),
                  Text('Compartir',
                    style: TextStyle(fontFamily: 'Lexend', color: Colors.black,
                      fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraViewer(
          key: _cameraViewerKey,
          controller: controller!,
          showGrid: showGrid,
          isPlaying: false,
          lastCapturedPhoto: lastCapturedPhoto,
          onionOpacity: onionOpacity,
          onionLayers: _onionLayers,
          selectedIndex: selectedIndex,
          capturedPhotos: capturedPhotos,
          projectToLoad: widget.projectToLoad,
        ),
        Positioned(left: 8, top: 16, bottom: 16, child: _buildLeftPanel()),
        Positioned(right: 8, top: 0, bottom: 0, child: _buildRightPanel()),
        if (hasPhotos)
          Positioned(
            bottom: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${capturedPhotos.length} frames',
                style: const TextStyle(
                  color: Colors.white, fontFamily: 'Lexend', fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        // Onion layers
        _PanelBtn(
          onTap: _cycleOnionLayers,
          active: _onionLayers > 0,
          size: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers_rounded, size: 14,
                color: _onionLayers > 0 ? AppColors.primary : Colors.white38),
              Text(_onionLayers == 0 ? '—' : '$_onionLayers',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                  color: _onionLayers > 0 ? AppColors.primary : Colors.white38,
                  height: 1.2)),
            ],
          ),
        ),
        // Opacity slider (vertical)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white12,
                ),
                child: Slider(
                  value: onionOpacity,
                  min: 0, max: 1,
                  onChanged: (v) => setState(() => onionOpacity = v),
                ),
              ),
            ),
          ),
        ),
        // Grid toggle
        _PanelBtn(
          icon: Icons.grid_4x4,
          onTap: () => setState(() => showGrid = !showGrid),
          active: showGrid,
          size: 44,
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // IGNITE (cámara remota): oculto tras el flag.
        if (kEnableIgniteFeatures) ...[
          _PanelBtn(
            icon: _sessionCode != null ? Icons.wifi : Icons.wifi_off,
            onTap: _openRemoteSession,
            active: _sessionCode != null,
            size: 40,
          ),
          const SizedBox(height: 16),
        ],
        // Red capture button
        GestureDetector(
          onTap: _takePhoto,
          child: Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withOpacity(0.45),
                  blurRadius: 14, spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PanelBtn(icon: Icons.play_arrow_rounded, onTap: hasPhotos ? _playSequence : null, size: 40),
        const SizedBox(height: 16),
        _PanelBtn(icon: Icons.tune_rounded, onTap: _showSettings, size: 40),
      ],
    );
  }

  Widget _buildCinemaMode() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: kIsWeb
                ? Image.network(capturedPhotos[previewIndex].path)
                : Image.file(File(capturedPhotos[previewIndex].path)),
          ),
          Positioned(
            bottom: 50, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _stopPlayback,
                child: Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.danger, shape: BoxShape.circle),
                  child: const Icon(Icons.stop_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('EXPORTANDO...',
              style: TextStyle(color: AppColors.primary, fontFamily: 'Lexend', fontSize: 22)),
            const SizedBox(height: 25),
            SizedBox(
              width: 220,
              child: LinearProgressIndicator(
                value: _exportProgress,
                color: AppColors.secondary,
                backgroundColor: Colors.white10,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Text('${(_exportProgress * 100).round()}%',
              style: const TextStyle(color: Colors.white54, fontFamily: 'Lexend', fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Reusable panel button ─────────────────────────────────────────────────────

class _PanelBtn extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;
  final bool active;
  final double size;

  const _PanelBtn({this.icon, this.child, this.onTap, this.active = false, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final iconColor = onTap == null
        ? Colors.white24
        : (active ? AppColors.primary : Colors.white60);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.15) : Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppColors.primary : Colors.white24,
            width: active ? 1.5 : 1,
          ),
        ),
        child: child ?? Icon(icon!, size: size * 0.45, color: iconColor),
      ),
    );
  }
}
