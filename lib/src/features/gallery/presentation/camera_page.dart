import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:blackcuack_studio/main.dart' show navigatorKey;
import 'package:blackcuack_studio/src/core/config/debug_flags.dart';
import 'package:blackcuack_studio/src/core/config/feature_flags.dart';
import 'package:blackcuack_studio/src/core/config/repositories.dart';
import 'package:blackcuack_studio/src/core/services/local_project_service.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/core/utils/camera_select.dart';
import 'package:blackcuack_studio/src/core/utils/frame_codec.dart';
import 'package:blackcuack_studio/src/core/utils/screen_lock.dart';
import 'package:blackcuack_studio/src/core/utils/quack_save_helper.dart';
import 'package:blackcuack_studio/src/core/utils/session_image.dart';
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
  final String aspect; // '9:16' | '16:9' (proyecto nuevo)
  const CameraPage({
    super.key,
    this.projectToLoad,
    this.startRemoteSession = false,
    this.aspect = '9:16',
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
  // Id del cuadro en el repo local, alineado con capturedPhotos. null = cuadro
  // nuevo (aún sin guardar) → se comprime y se agrega al guardar.
  List<String?> _frameIds = [];
  // Blobs/temp creados al reabrir, para revocarlos al salir (evita fugas).
  final List<SessionImage> _sessionImages = [];
  // Cola de compresión en segundo plano (no bloquea el obturador). Cada captura
  // se comprime y se guarda en el repo de a uno; el guardado espera la cola.
  Future<void> _compressQueue = Future.value();
  int _pendingCompressions = 0;
  // Id estable del proyecto (borrador en curso o proyecto que se reabre).
  late final String _projectId;
  late final String _aspect;
  // Título editable del proyecto (se puede renombrar con el lápiz).
  late String _title;
  // Pila de deshacer: instantáneas (cuadros + ids) ANTES de cada acción que
  // modifica la secuencia (capturar, borrar, duplicar, reordenar, restaurar).
  // Deshacer revierte la última acción, no borra las últimas capturas.
  final List<({List<XFile> photos, List<String?> ids})> _undo = [];
  // Orientación (web/móvil): se pide pantalla completa + bloqueo una sola vez.
  bool _immersiveTried = false;
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
    _projectId = isEditing
        ? widget.projectToLoad!.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    _aspect = isEditing ? widget.projectToLoad!.aspect : widget.aspect;
    _title = isEditing ? widget.projectToLoad!.name : 'Mi Animación';
    _initCamera();
    if (isEditing) {
      _hydrateFromProject();
    }
  }

  /// Persiste el borrador en curso (solo proyectos nuevos): un proyecto isDraft
  /// con los ids ya comprimidos. Así un cierre inesperado no pierde el trabajo y
  /// los cuadros no cuentan como huérfanos.
  Future<void> _persistDraft() async {
    if (isEditing) return;
    final ids = _frameIds.whereType<String>().toList();
    if (ids.isEmpty) return;
    try {
      await saveDraft(projectRepository,
          id: _projectId, frameIds: ids, aspect: _aspect);
    } catch (e) {
      debugPrint('No se pudo persistir el borrador: $e');
    }
  }

  /// Reabre un proyecto. Si es **local**, hidrata los cuadros desde el repo
  /// (bytes → XFile de sesión) conservando sus ids. Si no está en el repo
  /// (proyecto de nube con URLs), usa las rutas tal cual.
  Future<void> _hydrateFromProject() async {
    final project = widget.projectToLoad!;
    final photos = <XFile>[];
    final ids = <String?>[];
    for (final id in project.photoPaths) {
      final bytes = await projectRepository.loadFrameBytes(id);
      if (bytes == null) continue;
      final s = await sessionImageFromBytes(bytes);
      _sessionImages.add(s);
      photos.add(s.file);
      ids.add(id);
    }
    if (!mounted) return;
    if (photos.isNotEmpty) {
      setState(() {
        capturedPhotos = photos;
        _frameIds = ids;
        lastCapturedPhoto = photos.last;
      });
    } else {
      // Proyecto no local (URLs de nube): comportamiento anterior.
      setState(() {
        capturedPhotos =
            project.photoPaths.map((path) => XFile(path)).toList();
        _frameIds = List<String?>.filled(project.photoPaths.length, null);
        if (capturedPhotos.isNotEmpty) lastCapturedPhoto = capturedPhotos.last;
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      debugPrint('No se pudieron enumerar cámaras: $e');
      cameras = const [];
    }
    if (cameras != null && cameras!.isNotEmpty) {
      // Stop motion: siempre la cámara TRASERA (apunta a la mesa). Si no hay
      // trasera (webcam del Mac), usa la disponible. Sin botón de cambio.
      final cam = pickBackCamera(cameras!);
      controller = CameraController(cam, ResolutionPreset.high,
          enableAudio: false);
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
    // Liberar orientación y pantalla completa al salir del editor (no-op fuera de web).
    unlockOrientation();
    exitFullscreen();
    controller?.dispose();
    _remoteSub?.cancel();
    if (_sessionCode != null) _remoteService.closeSession(_sessionCode!);
    for (final s in _sessionImages) {
      s.revoke();
    }
    super.dispose();
  }

  /// Orientación que exige la relación del proyecto (9:16 → vertical, 16:9 → horizontal).
  Orientation get _requiredOrientation =>
      _aspect == '16:9' ? Orientation.landscape : Orientation.portrait;

  /// Una sola vez (solo web/teléfono): pide pantalla completa y bloquea la
  /// orientación del proyecto. Best-effort: si el navegador lo rechaza, el aviso
  /// de "gira el teléfono" cubre el caso.
  void _maybeEnterImmersive(bool isPhone) {
    if (_immersiveTried || !kIsWeb || !isPhone) return;
    _immersiveTried = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await enterFullscreen();
      await lockOrientation(_aspect);
    });
  }

  /// Guarda una instantánea del estado ANTES de una acción, para poder deshacerla.
  void _pushUndo() {
    _undo.add((
      photos: List<XFile>.of(capturedPhotos),
      ids: List<String?>.of(_frameIds),
    ));
    if (_undo.length > 40) _undo.removeAt(0); // acota memoria
  }

  Future<void> _takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return;
    try {
      final XFile file = await controller!.takePicture();
      _pushUndo();
      // El obturador no espera a la compresión: se muestra la imagen original
      // al instante y se comprime en segundo plano.
      setState(() {
        lastCapturedPhoto = file;
        capturedPhotos.add(file);
        _frameIds.add(null); // id se asigna cuando termine la compresión
        selectedIndex = null;
      });
      _enqueueCompression(file);
    } catch (e) {
      debugPrint("Error captura: $e");
    }
  }

  /// Encola la compresión de un cuadro recién capturado (serializado, uno a uno).
  void _enqueueCompression(XFile file) {
    _pendingCompressions++;
    _compressQueue = _compressQueue.then((_) => _compressAndStore(file));
  }

  Future<void> _compressAndStore(XFile file) async {
    try {
      final raw = await file.readAsBytes();
      final sw = Stopwatch()..start();
      final jpeg = compressFrameJpeg(raw, aspect: aspectValue(_aspect));
      sw.stop();
      debugPrint('⏱️ compresión (captura): ${sw.elapsedMilliseconds} ms/cuadro');
      compressionDebug.value = '${sw.elapsedMilliseconds} ms/cuadro';
      final id = await projectRepository.addFrame(jpeg);
      final idx = capturedPhotos.indexOf(file);
      if (idx != -1 && idx < _frameIds.length) {
        _frameIds[idx] = id;
        await _persistDraft(); // borrador incremental (HDU1)
      }
      // Si el cuadro se borró antes de comprimirse, queda huérfano y lo limpia
      // pruneOrphanFrames (>24h) en el próximo arranque.
    } catch (e) {
      debugPrint('Error compresión en segundo plano: $e');
    } finally {
      if (_pendingCompressions > 0) _pendingCompressions--;
    }
  }

  /// Al salir con "atrás" de un proyecto nuevo con cuadros: pregunta si guardar
  /// como borrador o descartar. (El borrador automático ya protege ante cierres
  /// inesperados; esto es para la salida explícita.)
  Future<void> _handleBackExit(NavigatorState nav) async {
    if (isEditing || capturedPhotos.isEmpty) {
      nav.pop();
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('¿GUARDAR BORRADOR?',
            style: TextStyle(fontFamily: 'Lexend', color: Color(0xFFFFB800), fontSize: 16)),
        content: const Text(
          'Tienes cuadros sin guardar. Puedes guardarlos como borrador para seguir luego, o descartarlos.',
          style: TextStyle(color: Colors.white54, fontFamily: 'Lexend', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'descartar'),
            child: const Text('DESCARTAR', style: TextStyle(color: Color(0xFFFF4D4D))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB800)),
            onPressed: () => Navigator.pop(ctx, 'borrador'),
            child: const Text('GUARDAR BORRADOR', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (choice == null) return; // cancelar: quedarse
    if (choice == 'descartar') {
      await _compressQueue; // evita que una compresión en curso recree el borrador
      await projectRepository.deleteProject(_projectId);
    } else {
      await _compressQueue;
      await _persistDraft();
    }
    if (mounted) nav.pop();
  }

  void _playSequence() async {
    if (capturedPhotos.isEmpty) return;
    // Bucle continuo desde el cuadro seleccionado (o el primero).
    final start = (selectedIndex ?? 0).clamp(0, capturedPhotos.length - 1);
    setState(() {
      isPlaying = true;
      previewIndex = start;
      selectedIndex = null;
    });
    int i = start;
    while (mounted && isPlaying) {
      setState(() => previewIndex = i);
      await Future.delayed(Duration(milliseconds: (1000 / fps).round()));
      if (capturedPhotos.isEmpty) break;
      i = (i + 1) % capturedPhotos.length;
    }
  }

  void _stopPlayback() => setState(() => isPlaying = false);

  void _cycleOnionLayers() =>
      setState(() => _onionLayers = (_onionLayers + 1) % 4);

  /// Deshacer: revierte la última acción (capturar, borrar, duplicar, reordenar,
  /// restaurar). Si se había borrado un cuadro, deshacer lo vuelve a poner.
  void _handleUndo() {
    if (_undo.isEmpty) {
      _showSnack('Nada que deshacer', Colors.white24);
      return;
    }
    final snap = _undo.removeLast();
    setState(() {
      capturedPhotos = snap.photos;
      _frameIds = snap.ids;
      selectedIndex = null;
      lastCapturedPhoto = capturedPhotos.isEmpty ? null : capturedPhotos.last;
    });
    _persistDraft();
  }

  void _reorderFrames(int oldIndex, int newIndex) {
    _pushUndo();
    setState(() {
      final p = capturedPhotos.removeAt(oldIndex);
      capturedPhotos.insert(newIndex.clamp(0, capturedPhotos.length), p);
      if (oldIndex < _frameIds.length) {
        final id = _frameIds.removeAt(oldIndex);
        _frameIds.insert(newIndex.clamp(0, _frameIds.length), id);
      }
      selectedIndex = null;
    });
    _persistDraft();
  }

  void _duplicateFrame(int i) {
    _pushUndo();
    setState(() {
      // Nuevo XFile (misma ruta) para no colisionar claves; el id (bytes) se
      // comparte, así que no se duplica el almacenamiento.
      capturedPhotos.insert(i + 1, XFile(capturedPhotos[i].path));
      _frameIds.insert(
          i + 1, i < _frameIds.length ? _frameIds[i] : null);
      selectedIndex = null;
      lastCapturedPhoto = capturedPhotos.last;
    });
    _persistDraft();
  }

  void _deleteFrameWithUndo(int i) {
    if (i < 0 || i >= capturedPhotos.length) return;
    _pushUndo();
    final removedPhoto = capturedPhotos[i];
    final removedId = i < _frameIds.length ? _frameIds[i] : null;
    setState(() {
      capturedPhotos.removeAt(i);
      if (i < _frameIds.length) _frameIds.removeAt(i);
      selectedIndex = null;
      lastCapturedPhoto = capturedPhotos.isEmpty ? null : capturedPhotos.last;
    });
    _persistDraft();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cuadro borrado',
            style: TextStyle(fontFamily: 'Lexend')),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DESHACER',
          textColor: AppColors.primary,
          onPressed: () {
            setState(() {
              capturedPhotos.insert(
                  i.clamp(0, capturedPhotos.length), removedPhoto);
              _frameIds.insert(i.clamp(0, _frameIds.length), removedId);
              lastCapturedPhoto = capturedPhotos.last;
            });
            _persistDraft();
          },
        ),
      ),
    );
  }

  // ── Versiones (HDU5) ───────────────────────────────────────────────────────
  Future<void> _saveVersion() async {
    await _compressQueue;
    final ids = _frameIds.whereType<String>().toList();
    if (ids.isEmpty) {
      _showSnack('Captura algunos cuadros primero', AppColors.danger);
      return;
    }
    await saveVersion(projectRepository,
        parentId: _projectId,
        frameIds: ids,
        author: widget.projectToLoad?.artistName ?? '',
        aspect: _aspect);
    if (mounted) _showSnack('Versión guardada 📑', AppColors.secondary);
  }

  Future<void> _restoreVersion(QuackProject version) async {
    final photos = <XFile>[];
    final ids = <String?>[];
    for (final id in version.photoPaths) {
      final bytes = await projectRepository.loadFrameBytes(id);
      if (bytes == null) continue;
      final s = await sessionImageFromBytes(bytes);
      _sessionImages.add(s);
      photos.add(s.file);
      ids.add(id);
    }
    if (!mounted) return;
    _pushUndo(); // restaurar es reversible con Deshacer
    setState(() {
      capturedPhotos = photos;
      _frameIds = ids;
      selectedIndex = null;
      lastCapturedPhoto = photos.isNotEmpty ? photos.last : null;
    });
    _showSnack('Versión restaurada', AppColors.primary);
  }

  void _showVersions() async {
    final versions = await listVersions(projectRepository, _projectId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HISTORIAL DE VERSIONES',
                style: TextStyle(
                    color: AppColors.primary, fontFamily: 'Lexend', fontSize: 16)),
            const SizedBox(height: 16),
            if (versions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Aún no hay versiones. Toca "Guardar versión".',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
              )
            else
              ...versions.map((v) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bookmark_rounded,
                        color: AppColors.secondary),
                    title: Text(
                        '${v.date.day}/${v.date.month} ${v.date.hour}:${v.date.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.white, fontFamily: 'Lexend', fontSize: 13)),
                    subtitle: Text('${v.photoPaths.length} cuadros',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _restoreVersion(v);
                          },
                          child: const Text('RESTAURAR',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 11)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded,
                              color: Colors.white54, size: 18),
                          tooltip: 'Duplicar versión',
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await saveVersion(projectRepository,
                                parentId: _projectId,
                                frameIds: v.photoPaths,
                                author: v.artistName,
                                aspect: _aspect);
                            if (mounted) {
                              _showSnack('Versión duplicada', AppColors.secondary);
                            }
                          },
                        ),
                      ],
                    ),
                  )),
          ],
        ),
        ),
      ),
    );
  }

  /// Renombra el proyecto (lápiz junto al título). Si el proyecto ya existe en
  /// el repo, persiste el nuevo nombre de inmediato.
  Future<void> _renameTitle() async {
    final ctrl = TextEditingController(text: _title);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('TÍTULO',
            style: TextStyle(
                fontFamily: 'Lexend', color: AppColors.primary, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'Lexend'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          decoration: InputDecoration(
            hintText: 'Nombre de la animación',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('LISTO',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => _title = name);
    // Si ya hay un registro guardado (proyecto o borrador), persiste el nombre.
    final existing = await projectRepository.getProject(_projectId);
    if (existing != null) {
      await saveCapturedProject(
        projectRepository,
        id: _projectId,
        name: name,
        artistName: existing.artistName,
        frames: existing.photoPaths.map(CapturedFrame.existing).toList(),
        isPublished: existing.isPublished,
        workshopCode: existing.workshopCode,
        isDraft: existing.isDraft,
        aspect: existing.aspect,
      );
    }
  }

  void _handleSaveAction() {
    if (capturedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Toma algunas fotos antes de guardar")),
      );
      return;
    }
    _cameraViewerKey.currentState?.showSaveDialog(context, initialName: _title);
  }

  /// Guarda el proyecto en el **repositorio local** (sin Firebase). Conserva los
  /// ids de los cuadros existentes (no los recomprime) y comprime solo los
  /// nuevos. Luego vuelve a Inicio.
  Future<void> _saveLocally({
    required String name,
    required String artist,
    bool isPublished = false,
    String? groupCode,
  }) async {
    QuackSaveHelper.showLoadingQuack();
    try {
      // Espera a que la cola de compresión termine (indicador ya visible). Así
      // no se pierde ningún cuadro que todavía se esté comprimiendo.
      await _compressQueue;

      final frames = <CapturedFrame>[];
      for (int i = 0; i < capturedPhotos.length; i++) {
        final id = i < _frameIds.length ? _frameIds[i] : null;
        if (id != null) {
          frames.add(CapturedFrame.existing(id));
        } else {
          // Respaldo: si una compresión falló, se comprime ahora al guardar.
          frames.add(CapturedFrame.raw(await capturedPhotos[i].readAsBytes()));
        }
      }
      await saveCapturedProject(
        projectRepository,
        id: _projectId,
        name: name,
        artistName: artist,
        frames: frames,
        isPublished: isPublished,
        workshopCode: groupCode,
        isDraft: false, // "Guardar" finaliza el borrador
        aspect: _aspect,
      );

      _quackSavedToast();
    } catch (e) {
      debugPrint('⚠️ Error al guardar localmente: $e');
      _quackSaveErrorToast();
    } finally {
      // Salida atómica a Inicio (igual que el guardado anterior).
      final nav = navigatorKey.currentState;
      if (nav != null) {
        nav.pop(); // cierra el patito de carga
        await Future.delayed(const Duration(milliseconds: 300));
        nav.pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  void _quackSavedToast() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final ephemeral = repositoryIsEphemeral;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          ephemeral
              ? 'Guardado temporal: este navegador no permite guardar; se perderá al cerrar.'
              : 'Guardado en este dispositivo 🦆',
          style: const TextStyle(fontFamily: 'Lexend'),
        ),
        backgroundColor:
            ephemeral ? const Color(0xFFFF4D4D) : const Color(0xFF3CCF7A),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _quackSaveErrorToast() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('No se pudo guardar. Intenta de nuevo.',
            style: TextStyle(fontFamily: 'Lexend')),
        backgroundColor: Color(0xFFFF4D4D),
      ),
    );
  }

  void _exportVideo() {
    if (capturedPhotos.isEmpty) return;
    _showExportDialog();
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SingleChildScrollView(
        child: Padding(
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
              subtitle: 'Todos los frames en un archivo .zip',
              color: AppColors.green,
              onTap: () {
                Navigator.pop(context);
                _askFilenameAndExport(ExportFormat.imageSequence, 'zip');
              },
            ),
          ],
        ),
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
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
                left: 30,
                right: 30,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('VELOCIDAD (FPS)',
                style: TextStyle(color: AppColors.primary, fontFamily: 'Lexend', fontSize: 16)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: fps, min: 1, max: 30, divisions: 29,
                      activeColor: AppColors.secondary,
                      onChanged: (v) { setModalState(() => fps = v); setState(() => fps = v); },
                    ),
                  ),
                  Text('${fps.round()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [6, 8, 12, 15, 24].map((v) {
                  final sel = fps.round() == v;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() => fps = v.toDouble());
                      setState(() => fps = v.toDouble());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.secondary : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$v',
                          style: TextStyle(
                              color: sel ? Colors.black : Colors.white70,
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  );
                }).toList(),
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
            _frameIds.add(null);
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

    // Control de orientación (solo web en teléfono). En pantallas grandes
    // (Mac/tablet) no se fuerza nada.
    final media = MediaQuery.of(context);
    final isPhone = media.size.shortestSide < 600;
    final enforceOrientation = kIsWeb && isPhone;
    _maybeEnterImmersive(isPhone);
    if (enforceOrientation && media.orientation != _requiredOrientation) {
      // Bloquea la captura (no se renderiza el editor) hasta girar: así no se
      // guardan cuadros torcidos ni se rompe el layout.
      return _buildRotateOverlay(_requiredOrientation);
    }

    if (isPlaying) return _buildCinemaMode();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackExit(Navigator.of(context));
      },
      child: Stack(
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
                  onReorder: _reorderFrames,
                  onDuplicate: _duplicateFrame,
                  onDelete: _deleteFrameWithUndo,
                ),
              ],
            ),
          ),
        ),
        if (_isExporting) _buildExportOverlay(),
        if (kShowDebugOverlay)
          Positioned(
            left: 8,
            bottom: 8,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.black.withValues(alpha: 0.6),
                child: ValueListenableBuilder<String>(
                  valueListenable: compressionDebug,
                  builder: (_, v, _) => Text(
                    '⏱️ $v',
                    style: const TextStyle(
                        color: Color(0xFF3CCF7A),
                        fontFamily: 'Lexend',
                        fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
      ],
      ),
    );
  }

  Widget _buildTopBar() {
    // En pantallas angostas, los secundarios (versión, historial, exportar) van a
    // un menú ⋯ para que no se superpongan con el título. Quedan Deshacer y Guardar.
    final compact = MediaQuery.of(context).size.width < 480;

    final undoBtn = IconButton(
      icon: Icon(Icons.undo_rounded,
          color: _undo.isNotEmpty ? Colors.white60 : Colors.white24, size: 22),
      onPressed: _undo.isNotEmpty ? _handleUndo : null,
      tooltip: 'Deshacer',
    );

    final versionBtn = IconButton(
      icon: Icon(Icons.bookmark_add_outlined,
          color: hasPhotos ? AppColors.secondary : Colors.white24, size: 20),
      onPressed: hasPhotos ? _saveVersion : null,
      tooltip: 'Guardar versión',
    );
    final historyBtn = IconButton(
      icon: const Icon(Icons.history_rounded, color: Colors.white60, size: 20),
      onPressed: _showVersions,
      tooltip: 'Versiones',
    );
    final exportBtn = IconButton(
      icon: Icon(Icons.ios_share,
          color: hasPhotos ? Colors.white60 : Colors.white24, size: 20),
      onPressed: hasPhotos ? _exportVideo : null,
      tooltip: 'Exportar',
    );

    final guardarPill = GestureDetector(
      onTap: hasPhotos ? _handleSaveAction : null,
      child: Opacity(
        opacity: hasPhotos ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.save_rounded, color: Colors.black, size: 16),
              SizedBox(width: 5),
              Text('Guardar',
                  style: TextStyle(
                      fontFamily: 'Lexend',
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );

    final List<Widget> actions = compact
        ? [
            undoBtn,
            _buildOverflowMenu(),
            const SizedBox(width: 2),
            guardarPill,
          ]
        : [
            versionBtn,
            historyBtn,
            undoBtn,
            if (kEnableIgniteFeatures)
              IconButton(
                icon: Icon(Icons.auto_fix_high_rounded,
                    color: hasPhotos ? AppColors.secondary : Colors.white24,
                    size: 20),
                onPressed: hasPhotos ? _openEraseTool : null,
                tooltip: 'Borrar soporte',
              ),
            exportBtn,
            const SizedBox(width: 4),
            guardarPill,
          ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
            onPressed: () => _handleBackExit(Navigator.of(context)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _renameTitle,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Flexible(
                    child: Text(_title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white, fontFamily: 'Lexend',
                          fontWeight: FontWeight.w600, fontSize: 15,
                        )),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.edit_outlined,
                      color: Colors.white38, size: 14),
                ],
              ),
            ),
          ),
          ...actions,
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  /// Menú ⋯ para pantallas angostas: versión, historial y exportar.
  Widget _buildOverflowMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 22),
      color: const Color(0xFF1A1A1A),
      tooltip: 'Más',
      onSelected: (v) {
        switch (v) {
          case 'version':
            if (hasPhotos) _saveVersion();
            break;
          case 'history':
            _showVersions();
            break;
          case 'export':
            if (hasPhotos) _exportVideo();
            break;
          case 'erase':
            if (hasPhotos) _openEraseTool();
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'version',
          child: _MenuRow(icon: Icons.bookmark_add_outlined, label: 'Guardar versión'),
        ),
        const PopupMenuItem(
          value: 'history',
          child: _MenuRow(icon: Icons.history_rounded, label: 'Versiones'),
        ),
        const PopupMenuItem(
          value: 'export',
          child: _MenuRow(icon: Icons.ios_share, label: 'Exportar'),
        ),
        if (kEnableIgniteFeatures)
          const PopupMenuItem(
            value: 'erase',
            child: _MenuRow(icon: Icons.auto_fix_high_rounded, label: 'Borrar soporte'),
          ),
      ],
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
          onSave: _saveLocally,
        ),
        // Guía de encuadre según la orientación del proyecto (HDU2).
        IgnorePointer(
          child: Center(
            child: AspectRatio(
              aspectRatio: aspectValue(_aspect),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35), width: 2),
                ),
              ),
            ),
          ),
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
    // Panel compacto: capas de cebolla y cuadrícula. La opacidad del papel cebolla
    // vive en Ajustes (deslizador horizontal, fácil con el dedo), no como un
    // deslizador vertical diminuto en el borde.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
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
        const SizedBox(height: 16),
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
                  color: AppColors.danger.withValues(alpha: 0.45),
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

  /// Aviso de "gira el teléfono" cuando la orientación no coincide con el proyecto.
  Widget _buildRotateOverlay(Orientation required) {
    final toPortrait = required == Orientation.portrait;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  toPortrait
                      ? Icons.stay_current_portrait_rounded
                      : Icons.screen_rotation_rounded,
                  color: AppColors.primary,
                  size: 72,
                ),
                const SizedBox(height: 24),
                Text(
                  toPortrait
                      ? 'Gira tu teléfono a vertical\npara seguir animando'
                      : 'Gira tu teléfono a horizontal\npara seguir animando',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lexend',
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Este proyecto es ${toPortrait ? 'vertical (9:16)' : 'horizontal (16:9)'}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white38, fontFamily: 'Lexend', fontSize: 13),
                ),
                const SizedBox(height: 28),
                TextButton.icon(
                  onPressed: () => _handleBackExit(Navigator.of(context)),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white38, size: 18),
                  label: const Text('Salir',
                      style: TextStyle(color: Colors.white38, fontFamily: 'Lexend')),
                ),
              ],
            ),
          ),
        ),
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

// ── Fila del menú ⋯ ───────────────────────────────────────────────────────────
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontFamily: 'Lexend', fontSize: 13)),
      ],
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
