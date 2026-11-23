import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:blackcuack_studio/main.dart' show navigatorKey;
import 'package:blackcuack_studio/src/core/config/app_info.dart';
import 'package:blackcuack_studio/src/core/config/debug_flags.dart';
import 'package:blackcuack_studio/src/core/config/feature_flags.dart';
import 'package:blackcuack_studio/src/core/config/repositories.dart';
import 'package:blackcuack_studio/src/core/services/local_project_service.dart';
import 'package:blackcuack_studio/src/core/services/session_log_service.dart';
import 'package:blackcuack_studio/src/features/profile/data/profile_service.dart';
import 'package:blackcuack_studio/src/features/profile/domain/profile_model.dart';
import 'package:blackcuack_studio/src/features/workshop/data/workshop_service.dart'
    show activeWorkshopCode;
import 'package:blackcuack_studio/src/features/workshop/presentation/team_helpers.dart'
    show showAddTeammateDialog, showTeamSheet;
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
  final String? initialName; // nombre elegido al crear (proyecto nuevo)
  final List<String> initialMembers; // ids de perfiles del equipo (proyecto nuevo)
  const CameraPage({
    super.key,
    this.projectToLoad,
    this.startRemoteSession = false,
    this.aspect = '9:16',
    this.initialName,
    this.initialMembers = const [],
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
  // Timeline colapsable que flota sobre el visor (se expande/contrae con el tirador).
  bool _timelineExpanded = true;
  // La "Versión de inicio" (solo el primer cuadro) se crea sola una vez. Evita
  // recrearla en cada captura.
  bool _inicioEnsured = false;
  // Perfil activo (para etiquetar la autoría de las versiones).
  Profile? _activeProfile;
  // Al reabrir un proyecto de taller con versiones, se pregunta una vez cómo
  // empezar la versión nueva (continuar / desde otra / desde 0).
  bool _newVersionAsked = false;
  // Equipo del proyecto (ids de perfiles): dueño + compañeros. Se define al
  // crear (en Home) o se hereda del proyecto reabierto.
  late List<String> _members;
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
    _title = isEditing
        ? widget.projectToLoad!.name
        : (widget.initialName != null && widget.initialName!.trim().isNotEmpty
            ? widget.initialName!.trim()
            : 'Mi Animación');
    _members = isEditing
        ? List<String>.of(widget.projectToLoad!.memberProfileIds)
        : List<String>.of(widget.initialMembers);
    _initCamera();
    _loadActiveProfile();
    if (isEditing) {
      _hydrateFromProject();
    }
  }

  Future<void> _loadActiveProfile() async {
    final p = await ProfileService.getActive();
    if (mounted) setState(() => _activeProfile = p);
  }

  /// Nombre de autor para versiones: apodo del perfil activo o, si no hay,
  /// el artista del proyecto.
  String get _authorName =>
      (_activeProfile?.nickname.isNotEmpty ?? false)
          ? _activeProfile!.nickname
          : (widget.projectToLoad?.artistName ?? '');
  String get _authorRole => _activeProfile?.role ?? '';

  /// Registro local de actividad (captura/versión) para el dashboard futuro.
  void _logSession(String type) {
    SessionLogService.log(
      type: type,
      workshopCode: activeWorkshopCode,
      profileId: activeProfileId,
      projectId: _projectId,
    );
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
          id: _projectId,
          frameIds: ids,
          name: _title, // nombre real del proyecto (ya no "Borrador")
          artistName: _authorName,
          aspect: _aspect,
          memberProfileIds: _members);
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
    // Proyecto reabierto sin "Inicio" (anterior a esta función): lo crea desde
    // el primer cuadro local.
    await _ensureInicioVersion();
    // Flujo de aula: al reabrir un proyecto de taller, preguntar cómo empezar
    // la versión nueva (otro día = nueva versión). HDU5.
    if (mounted) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeAskNewVersionStart());
    }
  }

  /// Al reabrir un proyecto **de taller con versiones**, ofrece empezar una
  /// versión nueva: continuar la última, partir de otra versión, o desde 0.
  Future<void> _maybeAskNewVersionStart() async {
    if (_newVersionAsked || !isEditing || activeWorkshopCode.isEmpty) return;
    _newVersionAsked = true;
    final versions = await listVersions(projectRepository, _projectId);
    if (!mounted || versions.isEmpty) return;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('NUEVA VERSIÓN',
            style: TextStyle(
                fontFamily: 'Lexend', color: AppColors.primary, fontSize: 15)),
        content: const Text(
          '¿Cómo quieres empezar tu versión de hoy?',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'continue'),
            child: const Text('Continuar la última',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'pick'),
            child: const Text('Desde otra versión…',
                style: TextStyle(color: AppColors.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'blank'),
            child: const Text('Desde 0',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'blank') {
      _pushUndo();
      setState(() {
        capturedPhotos = [];
        _frameIds = [];
        selectedIndex = null;
        lastCapturedPhoto = null;
      });
      _showSnack('Lienzo en blanco: empieza tu versión', AppColors.primary);
    } else if (choice == 'pick') {
      await _pickVersionToStartFrom(versions);
    }
    // 'continue' o null: se mantienen los cuadros hidratados (última).
  }

  /// Selector simple de versión para "empezar desde otra".
  Future<void> _pickVersionToStartFrom(List<QuackProject> versions) async {
    final picked = await showModalBottomSheet<QuackProject>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('EMPEZAR DESDE…',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Lexend',
                      fontSize: 15)),
            ),
            ...versions.map((v) => ListTile(
                  leading: Icon(
                      v.name == 'Inicio'
                          ? Icons.flag_rounded
                          : Icons.bookmark_rounded,
                      color: v.name == 'Inicio'
                          ? AppColors.primary
                          : AppColors.secondary),
                  title: Text(v.name,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${v.photoPaths.length} cuadros',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11)),
                  onTap: () => Navigator.pop(ctx, v),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked != null) await _restoreVersion(picked);
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

  /// Una sola vez (teléfono, web y nativo): entra a pantalla completa y bloquea
  /// la orientación del proyecto.
  /// - En nativo, lockOrientation FUERZA el giro (16:9 → horizontal, 9:16 →
  ///   vertical) con SystemChrome, sin depender del autogiro del sistema.
  /// - En web es best-effort: si el navegador lo rechaza, el aviso de "gira el
  ///   teléfono" cubre el caso.
  void _maybeEnterImmersive(bool isPhone) {
    if (_immersiveTried || !isPhone) return;
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
      // Se guarda SIN recortar (aspecto del sensor): así el papel cebolla calza
      // con la vista previa en vivo. El recorte al aspecto del proyecto se
      // aplica solo al exportar y en el reproductor.
      final jpeg = compressFrameJpeg(raw);
      sw.stop();
      debugPrint('⏱️ compresión (captura): ${sw.elapsedMilliseconds} ms/cuadro');
      compressionDebug.value = '${sw.elapsedMilliseconds} ms/cuadro';
      final id = await projectRepository.addFrame(jpeg);
      final idx = capturedPhotos.indexOf(file);
      if (idx != -1 && idx < _frameIds.length) {
        _frameIds[idx] = id;
        await _persistDraft(); // borrador incremental (HDU1)
        _logSession('capture');
        await _ensureInicioVersion(); // respaldo "Inicio" con el primer cuadro
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
        title: const Text('¿GUARDAR ANTES DE SALIR?',
            style: TextStyle(fontFamily: 'Lexend', color: Color(0xFFFFB800), fontSize: 16)),
        content: const Text(
          'Tienes cuadros sin guardar. Puedes guardarlos para seguir luego, o descartarlos.',
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
            child: const Text('GUARDAR', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (choice == null) return; // cancelar: quedarse
    if (choice == 'descartar') {
      await _compressQueue; // evita que una compresión en curso recree el borrador
      // Borra también las versiones (incl. "Inicio" automática) para no dejar
      // registros ni cuadros huérfanos al descartar.
      final versions = await listVersions(projectRepository, _projectId);
      for (final v in versions) {
        await projectRepository.deleteProject(v.id);
      }
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
  /// Crea una sola vez la "Versión de inicio" automática: **solo el primer
  /// cuadro** del proyecto, como punto de partida/respaldo desde el que un grupo
  /// ramifica. Se llama al capturar/hidratar el primer cuadro; no-op si ya existe.
  Future<void> _ensureInicioVersion() async {
    if (_inicioEnsured) return;
    final ids = _frameIds.whereType<String>().toList();
    if (ids.isEmpty) return;
    final existing = await listVersions(projectRepository, _projectId);
    if (existing.any((v) => v.name == 'Inicio')) {
      _inicioEnsured = true;
      return;
    }
    await saveVersion(projectRepository,
        parentId: _projectId,
        frameIds: [ids.first], // punto de inicio = primer cuadro
        author: _authorName,
        authorRole: _authorRole,
        participantIds: [if (activeProfileId.isNotEmpty) activeProfileId],
        aspect: _aspect,
        name: 'Inicio');
    _logSession('version');
    _inicioEnsured = true;
  }

  /// Diálogo simple para pedir un nombre. Devuelve null si se cancela.
  Future<String?> _promptName(
      {required String title, String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Lexend', color: AppColors.primary, fontSize: 15)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nombre',
            hintStyle: const TextStyle(color: Colors.white24),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  /// Renombra una versión existente (mismo id → upsert).
  Future<void> _renameVersion(QuackProject v) async {
    final name =
        await _promptName(title: 'RENOMBRAR VERSIÓN', initial: v.name);
    if (name == null || name.trim().isEmpty) return;
    await projectRepository.saveProject(v.copyWith(name: name.trim()));
    if (mounted) _showSnack('Versión renombrada', AppColors.secondary);
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
    var versions = await listVersions(projectRepository, _projectId);
    var profiles = await ProfileService.list();
    var profileMap = {for (final p in profiles) p.id: p};
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> reload() async {
            final v = await listVersions(projectRepository, _projectId);
            profiles = await ProfileService.list();
            if (mounted) {
              setSheet(() {
                versions = v;
                profileMap = {for (final p in profiles) p.id: p};
              });
            }
          }
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HISTORIAL DE VERSIONES',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Lexend',
                          fontSize: 16)),
                  const SizedBox(height: 16),
                  if (versions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Aún no hay versiones. Guarda tu trabajo.',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 13)),
                    )
                  else
                    ...versions.map(
                        (v) => _versionTile(ctx, v, reload, profileMap)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Participantes de una versión: "apodo · rol" si es uno, o "Grupo 🦆🐸" si
  /// son varios. Versiones antiguas (sin participantes) usan autor/rol.
  String _versionParticipantsLine(QuackProject v, Map<String, Profile> pm) {
    final ids = v.memberProfileIds;
    if (ids.isEmpty) {
      if (v.isCollaborative) return 'Grupo';
      final who =
          v.artistName.trim().isEmpty ? 'Sin autor' : v.artistName.trim();
      return v.authorRole.isEmpty ? who : '$who · ${v.authorRole}';
    }
    if (ids.length == 1) {
      final p = pm[ids.first];
      if (p == null) return 'Participante';
      return p.role.isEmpty ? p.nickname : '${p.nickname} · ${p.role}';
    }
    final avatars = ids.take(4).map((id) => pm[id]?.avatar ?? '👤').join(' ');
    final extra = ids.length > 4 ? ' +${ids.length - 4}' : '';
    return 'Grupo: $avatars$extra';
  }

  Widget _versionTile(BuildContext ctx, QuackProject v,
      Future<void> Function() reload, Map<String, Profile> pm) {
    final isInicio = v.name == 'Inicio';
    final isGroup = v.isCollaborative || v.memberProfileIds.length > 1;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(isInicio ? Icons.flag_rounded : Icons.bookmark_rounded,
          color: isInicio ? AppColors.primary : AppColors.secondary),
      title: Row(
        children: [
          Flexible(
            child: Text(v.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lexend',
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          if (isGroup) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('GRUPO',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontFamily: 'Lexend',
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _versionParticipantsLine(v, pm),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          Text(
            '${v.photoPaths.length} cuadros · ${v.date.day}/${v.date.month} ${v.date.hour}:${v.date.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white30, fontSize: 10),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restoreVersion(v);
            },
            child: const Text('RESTAURAR',
                style: TextStyle(color: AppColors.primary, fontSize: 11)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: Colors.white54, size: 18),
            color: const Color(0xFF222222),
            onSelected: (s) async {
              if (s == 'rename') {
                await _renameVersion(v);
                await reload();
              } else if (s == 'participants') {
                final picked = await showTeamSheet(
                  context,
                  initial: v.memberProfileIds.toSet(),
                  owner: '',
                  title: 'PARTICIPANTES DE "${v.name}"',
                );
                if (picked != null) {
                  await projectRepository.saveProject(v.copyWith(
                    memberProfileIds: picked.toList(),
                    isCollaborative: picked.length > 1,
                  ));
                }
                await reload();
              } else if (s == 'dup') {
                await saveVersion(projectRepository,
                    parentId: _projectId,
                    frameIds: v.photoPaths,
                    author: v.artistName,
                    authorRole: v.authorRole,
                    participantIds: v.memberProfileIds,
                    aspect: _aspect,
                    name: '${v.name} (copia)');
                if (mounted) _showSnack('Versión duplicada', AppColors.secondary);
                await reload();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'rename',
                  child: Text('Renombrar',
                      style: TextStyle(color: Colors.white))),
              PopupMenuItem(
                  value: 'participants',
                  child: Text('Editar participantes',
                      style: TextStyle(color: Colors.white))),
              PopupMenuItem(
                  value: 'dup',
                  child:
                      Text('Duplicar', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveAction() async {
    if (capturedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Toma algunas fotos antes de guardar")),
      );
      return;
    }
    // Guardar UNIFICADO: nombra el proyecto y, si se quiere, crea una versión
    // con sus participantes (todo en un solo diálogo).
    final existing = await listVersions(projectRepository, _projectId);
    if (!mounted) return;
    final userVersions = existing.where((v) => v.name != 'Inicio').length;
    final allProfiles = await ProfileService.list();
    if (!mounted) return;
    final result = await _showUnifiedSaveDialog(
      suggestedVersion: 'Versión ${userVersions + 1}',
      allProfiles: allProfiles,
    );
    if (result == null) return;
    setState(() => _title = result.projectName);
    // 1) Versión (si se pidió), con participantes.
    if (result.newVersion) {
      await _compressQueue;
      final ids = _frameIds.whereType<String>().toList();
      if (ids.isNotEmpty) {
        await saveVersion(projectRepository,
            parentId: _projectId,
            frameIds: ids,
            name: result.versionName,
            participantIds: result.participants,
            aspect: _aspect);
        _logSession('version');
      }
    }
    // 2) Finaliza el guardado del proyecto (y vuelve a Inicio).
    await _saveLocally(name: result.projectName, artist: _authorName);
  }

  /// Diálogo GUARDAR unificado: nombre del proyecto + "¿nueva versión?" (nombre
  /// + participantes). Devuelve null si se cancela.
  Future<
      ({
        String projectName,
        bool newVersion,
        String versionName,
        List<String> participants
      })?> _showUnifiedSaveDialog({
    required String suggestedVersion,
    required List<Profile> allProfiles,
  }) {
    final nameCtrl = TextEditingController(text: _title);
    final versionCtrl = TextEditingController(text: suggestedVersion);
    bool newVersion = true;
    // Participantes posibles = miembros del proyecto (o todos si no hay).
    final team = _members.isEmpty
        ? allProfiles
        : allProfiles.where((p) => _members.contains(p.id)).toList();
    final selected = <String>{
      ...team.map((p) => p.id),
    }; // por defecto participan todos los del equipo
    final profiles = List<Profile>.of(team);
    return showDialog<
        ({
          String projectName,
          bool newVersion,
          String versionName,
          List<String> participants
        })>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('GUARDAR',
              style: TextStyle(
                  fontFamily: 'Lexend', color: AppColors.primary, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nombre del proyecto',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nombre del proyecto',
                    hintStyle: const TextStyle(color: Colors.white24),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const Divider(color: Colors.white12, height: 28),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Guardar como nueva versión',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: newVersion,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setD(() => newVersion = v),
                ),
                if (newVersion) ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: versionCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre de la versión',
                      labelStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('¿Quiénes participaron?',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...profiles.map((p) {
                        final sel = selected.contains(p.id);
                        return FilterChip(
                          label: Text(
                              '${p.avatar} ${p.nickname}${p.role.isEmpty ? '' : ' · ${p.role}'}'),
                          selected: sel,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                              color: sel ? Colors.black : Colors.white70,
                              fontFamily: 'Lexend',
                              fontSize: 12),
                          backgroundColor: Colors.white10,
                          selectedColor: AppColors.primary,
                          onSelected: (v) => setD(() =>
                              v ? selected.add(p.id) : selected.remove(p.id)),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.person_add_alt_1_rounded,
                            size: 16, color: AppColors.secondary),
                        label: const Text('Nuevo',
                            style: TextStyle(
                                color: AppColors.secondary,
                                fontFamily: 'Lexend',
                                fontSize: 12)),
                        backgroundColor: Colors.white10,
                        onPressed: () async {
                          final p = await showAddTeammateDialog(ctx);
                          if (p != null) {
                            setD(() {
                              profiles.add(p);
                              selected.add(p.id);
                              _members = {..._members, p.id}.toList();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCELAR')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: () {
                final pName = nameCtrl.text.trim().isEmpty
                    ? _title
                    : nameCtrl.text.trim();
                Navigator.pop(ctx, (
                  projectName: pName,
                  newVersion: newVersion,
                  versionName: versionCtrl.text.trim().isEmpty
                      ? suggestedVersion
                      : versionCtrl.text.trim(),
                  participants: selected.toList(),
                ));
              },
              child:
                  const Text('GUARDAR', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
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
        memberProfileIds: _members,
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
        aspect: aspectValue(_aspect),
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
          ShareParams(files: [XFile(result)], text: '¡Mi animación BlackQuack!'),
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
    // Orientación incorrecta: NO se desmonta el visor (si se desmontara, al rotar
    // y volver la textura de video queda congelada y el papel cebolla se
    // descuadra, como pasaba con la reproducción). Se muestra el aviso "gira el
    // teléfono" como capa ENCIMA, dejando el CameraPreview montado y en vivo.
    final wrongOrientation =
        enforceOrientation && media.orientation != _requiredOrientation;

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
          // Visor a pantalla completa; barra y timeline flotan encima con opacidad.
          body: Stack(
            children: [
              Positioned.fill(child: _buildCameraArea()),
              // Controles superiores flotantes en las esquinas (X · Guardar · ⚙️).
              // Sin franja: el marco queda despejado.
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(bottom: false, child: _buildTopBar()),
              ),
              // Timeline colapsable flotante.
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: SafeArea(top: false, child: _buildTimelineOverlay()),
              ),
            ],
          ),
        ),
        // Reproducción: capa ENCIMA del editor, no un Scaffold aparte. Así el
        // CameraPreview nunca se desmonta y al detener sigue en vivo (si se
        // desmontara, en web la textura de video queda congelada). HDU3.
        if (isPlaying) Positioned.fill(child: _buildCinemaMode()),
        // Aviso "gira el teléfono" como capa (el visor sigue montado debajo).
        if (wrongOrientation)
          Positioned.fill(child: _buildRotateOverlay(_requiredOrientation)),
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
                    'v$appVersion · ⏱️ $v',
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
    // Solo esquinas flotantes: cerrar · Guardar · ⚙️ (el resto va en la hoja).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          _PanelBtn(
            icon: Icons.close_rounded,
            size: 44,
            onTap: () => _handleBackExit(Navigator.of(context)),
          ),
          const Spacer(),
          _PanelBtn(
            icon: Icons.settings_rounded,
            size: 44,
            onTap: _showProjectMenu,
          ),
        ],
      ),
    );
  }

  /// Hoja de acciones del proyecto (bajo el ⚙️): renombrar, deshacer, versión,
  /// historial, exportar. Mantiene el marco de la cámara despejado.
  void _showProjectMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => SafeArea(
        // En horizontal el alto útil es poco: se limita y se hace desplazable
        // para que no se corten los botones de abajo (versiones, exportar…).
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Lexend',
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Guardar: acción principal, destacada arriba.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: GestureDetector(
                onTap: hasPhotos
                    ? () {
                        Navigator.pop(ctx);
                        _handleSaveAction();
                      }
                    : null,
                child: Opacity(
                  opacity: hasPhotos ? 1 : 0.4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, color: Colors.black, size: 18),
                        SizedBox(width: 8),
                        Text('Guardar',
                            style: TextStyle(
                                fontFamily: 'Lexend',
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _projectMenuItem(ctx, Icons.undo_rounded, 'Deshacer',
                _undo.isNotEmpty ? _handleUndo : null),
            _projectMenuItem(
                ctx, Icons.history_rounded, 'Ver versiones', _showVersions),
            _projectMenuItem(ctx, Icons.ios_share, 'Exportar',
                hasPhotos ? _exportVideo : null),
            if (kEnableIgniteFeatures)
              _projectMenuItem(ctx, Icons.auto_fix_high_rounded,
                  'Borrar soporte', hasPhotos ? _openEraseTool : null),
            const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _projectMenuItem(
      BuildContext sheetCtx, IconData icon, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return ListTile(
      leading: Icon(icon,
          color: enabled ? Colors.white70 : Colors.white24, size: 22),
      title: Text(label,
          style: TextStyle(
              color: enabled ? Colors.white : Colors.white24,
              fontFamily: 'Lexend',
              fontSize: 14)),
      onTap: enabled
          ? () {
              Navigator.pop(sheetCtx);
              onTap();
            }
          : null,
    );
  }

  Widget _buildCameraArea() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Visor a pantalla completa (el marco de recorte lo dibuja el viewer).
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
          frameAspect: aspectValue(_aspect),
          onSave: _saveLocally,
        ),
        // Controles flotantes sobre el visor, centrados verticalmente.
        Positioned(left: 8, top: 0, bottom: 0,
            child: Center(child: _buildLeftPanel())),
        Positioned(right: 8, top: 0, bottom: 0,
            child: Center(child: _buildRightPanel())),
      ],
    );
  }

  /// Timeline que flota sobre el visor y se expande/contrae con el tirador.
  /// Cuando está contraída deja ver el encuadre completo (el tirador y el
  /// contador siguen visibles).
  Widget _buildTimelineOverlay() {
    final count = capturedPhotos.length;
    return Container(
      decoration: BoxDecoration(
        // Contenedor negro casi opaco: la tira se lee como un bloque sólido
        // (es colapsable), no como cuadros sueltos sobre la imagen.
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tirador: toca para expandir/contraer.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                setState(() => _timelineExpanded = !_timelineExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _timelineExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: Colors.white54, size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    count == 0
                        ? 'Sin cuadros'
                        : '$count cuadro${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Lexend',
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: _timelineExpanded
                ? CameraTimeline(
                    capturedPhotos: capturedPhotos,
                    selectedIndex: selectedIndex,
                    frameAspect: aspectValue(_aspect),
                    onPhotoTap: (i) => setState(() => selectedIndex = i),
                    onReorder: _reorderFrames,
                    onDuplicate: _duplicateFrame,
                    onDelete: _deleteFrameWithUndo,
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
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
        // Manejador visible de opacidad del papel cebolla (como el competidor):
        // aparece cuando hay capas activas; arrastrar arriba = más opaco.
        if (_onionLayers > 0) ...[
          const SizedBox(height: 12),
          _buildOnionSlider(),
        ],
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

  /// Slider vertical de opacidad del papel cebolla, en el riel izquierdo.
  Widget _buildOnionSlider() {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(onionOpacity * 100).round()}',
            style: const TextStyle(
                color: Colors.white54, fontSize: 9, fontFamily: 'Lexend'),
          ),
          SizedBox(
            height: 110,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  value: onionOpacity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) => setState(() => onionOpacity = v),
                ),
              ),
            ),
          ),
        ],
      ),
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
    // Capa opaca de reproducción (se dibuja sobre el editor, que queda montado).
    final idx = previewIndex.clamp(0, capturedPhotos.length - 1);
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: kIsWeb
                ? Image.network(capturedPhotos[idx].path)
                : Image.file(File(capturedPhotos[idx].path)),
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
