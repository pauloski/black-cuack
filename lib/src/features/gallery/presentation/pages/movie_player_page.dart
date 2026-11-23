import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blackcuack_studio/src/core/config/repositories.dart';
import 'package:blackcuack_studio/src/core/services/local_project_service.dart'
    show listVersions;
import 'package:blackcuack_studio/src/core/utils/frame_codec.dart'
    show aspectValue;
import 'package:blackcuack_studio/src/core/utils/session_image.dart';
import 'package:blackcuack_studio/src/core/utils/video_creator.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/profile/data/profile_service.dart';
import 'package:blackcuack_studio/src/features/profile/domain/profile_model.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/projection_page.dart';

class MoviePlayerPage extends StatefulWidget {
  final QuackProject project;
  const MoviePlayerPage({super.key, required this.project});

  @override
  State<MoviePlayerPage> createState() => _MoviePlayerPageState();
}

class _MoviePlayerPageState extends State<MoviePlayerPage> {
  int _currentFrame = 0;
  bool _isPlaying = true;
  Timer? _timer;
  double _fps = 10.0;
  final double _maxFps = 24.0;
  final double _minFps = 2.0;

  // Versión actualmente reproducida (el proyecto "actual" o una de sus versiones).
  late QuackProject _current;
  // Opciones del selector: el proyecto actual + sus versiones (Inicio → …).
  List<QuackProject> _options = [];
  // id de perfil → perfil, para mostrar los participantes.
  Map<String, Profile> _profileMap = {};

  // Cuadros locales (bytes). Si está vacío, el proyecto es de nube (URLs).
  List<Uint8List> _frames = [];
  bool _loading = true;

  // Exportación de la versión que se está viendo.
  bool _exporting = false;
  double _exportProgress = 0.0;

  int get _frameCount =>
      _frames.isNotEmpty ? _frames.length : _current.photoPaths.length;

  @override
  void initState() {
    super.initState();
    _current = widget.project;
    _init();
  }

  Future<void> _init() async {
    // Versiones (hijos por parentId), ordenadas Inicio → más reciente.
    final versions = await listVersions(projectRepository, widget.project.id);
    versions.sort((a, b) => a.date.compareTo(b.date));
    final profiles = await ProfileService.list();
    if (!mounted) return;
    setState(() {
      _options = [widget.project, ...versions];
      _profileMap = {for (final p in profiles) p.id: p};
    });
    await _loadFrames();
  }

  Future<void> _loadFrames() async {
    setState(() => _loading = true);
    final frames = await projectRepository.loadFrames(_current.id);
    if (!mounted) return;
    setState(() {
      _frames = frames;
      _currentFrame = 0;
      _loading = false;
    });
    _startAnimation();
  }

  void _selectVersion(QuackProject p) {
    if (p.id == _current.id) return;
    _timer?.cancel();
    setState(() => _current = p);
    _loadFrames();
  }

  // ── Exportar la versión que se está viendo ─────────────────────────────────
  void _showExportSheet() {
    if (_frameCount == 0) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('EXPORTAR',
                style: TextStyle(
                    color: Color(0xFFFFB800),
                    fontFamily: 'Lexend',
                    fontSize: 15)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.gif_box_rounded,
                  color: Color(0xFFFFB800)),
              title: const Text('GIF animado',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Compatible en todos los dispositivos',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _runExport(ExportFormat.gif);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_zip_rounded,
                  color: Color(0xFFBC87FE)),
              title: const Text('Cuadros (ZIP)',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Las fotos originales, una por una',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _runExport(ExportFormat.imageSequence);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _runExport(ExportFormat format) async {
    if (_frameCount == 0 || _exporting) return;
    setState(() {
      _exporting = true;
      _exportProgress = 0;
    });
    final sessions = <SessionImage>[];
    try {
      List<String> paths;
      if (_frames.isNotEmpty) {
        // Cuadros locales (bytes) → imágenes de sesión con ruta exportable.
        for (final b in _frames) {
          sessions.add(await sessionImageFromBytes(b));
        }
        paths = sessions.map((s) => s.file.path).toList();
      } else {
        paths = _current.photoPaths; // proyecto de nube (URLs)
      }
      final base = _current.id == widget.project.id
          ? widget.project.name
          : '${widget.project.name}-${_current.name}';
      final safe = base.trim().isEmpty
          ? 'animacion'
          : base.trim().replaceAll(RegExp(r'[^\w\-]+'), '_');
      final result = await VideoCreator.exportAs(
        format,
        paths,
        _fps,
        filename: safe,
        aspect: aspectValue(_current.aspect),
        onProgress: (p) {
          if (mounted) setState(() => _exportProgress = p);
        },
      );
      if (!mounted) return;
      if (result == null) {
        _snack('No se generó el archivo 🛠️');
      } else if (kIsWeb) {
        _snack('Archivo guardado en tu carpeta de Descargas');
      } else {
        await SharePlus.instance.share(
          ShareParams(
              files: [XFile(result)], text: '¡Mi animación BlackQuack!'),
        );
      }
    } catch (e) {
      if (mounted) _snack('Error al exportar: $e');
    } finally {
      for (final s in sessions) {
        s.revoke();
      }
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontFamily: 'Lexend')),
      backgroundColor: const Color(0xFFBC87FE),
    ));
  }

  void _startAnimation() {
    _timer?.cancel();
    if (_frameCount == 0) return;
    _timer = Timer.periodic(Duration(milliseconds: (1000 / _fps).round()), (
      timer,
    ) {
      if (mounted && _isPlaying) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _frameCount;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Textos de la versión ──────────────────────────────────────────────────
  /// Participantes: "Apodo · Rol" si es uno; "Grupo 🦆🐸" si varios.
  String _authorLine(QuackProject p) {
    final ids = p.memberProfileIds;
    if (ids.isEmpty) {
      if (p.isCollaborative) return 'Grupo';
      final who =
          p.artistName.trim().isEmpty ? 'Autor anónimo' : p.artistName.trim();
      return p.authorRole.isEmpty ? who : '$who · ${p.authorRole}';
    }
    if (ids.length == 1) {
      final prof = _profileMap[ids.first];
      if (prof == null) return 'Participante';
      return prof.role.isEmpty ? prof.nickname : '${prof.nickname} · ${prof.role}';
    }
    final avatars = ids.take(4).map((id) => _profileMap[id]?.avatar ?? '👤').join(' ');
    final extra = ids.length > 4 ? ' +${ids.length - 4}' : '';
    return 'Grupo: $avatars$extra';
  }

  String _dateLine(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Etiqueta de una opción del selector: la actual se marca; las demás, su nombre.
  String _optionLabel(QuackProject p) =>
      p.id == widget.project.id ? 'Actual · ${p.name}' : p.name;

  @override
  Widget build(BuildContext context) {
    final photos = _current.photoPaths;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🎞️ EL PROYECTOR — recortado al aspecto del proyecto (los cuadros se
          // guardan sin recortar; el recorte del proyecto se aplica aquí).
          Center(
            child: _loading
                ? const CircularProgressIndicator(
                    color: Color(0xFFFFB800), strokeWidth: 2)
                : _frameCount == 0
                    ? const Text("Sin fotos",
                        style: TextStyle(color: Colors.white24))
                    : AspectRatio(
                        aspectRatio: aspectValue(_current.aspect),
                        child: ClipRect(
                          child: _frames.isNotEmpty
                              ? Image.memory(
                                  _frames[_currentFrame],
                                  key: ValueKey(
                                      '${_current.id}-$_currentFrame'),
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                )
                              : Image.network(
                                  photos[_currentFrame],
                                  key: ValueKey(photos[_currentFrame]),
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                        ),
                      ),
          ),

          // 🎭 INTERFAZ (UI)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeader(), // Arriba
                _buildBottomSection(), // Abajo (Bajada + Controles)
              ],
            ),
          ),

          if (_exporting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          value: _exportProgress,
                          color: const Color(0xFFFFB800),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Exportando… ${(_exportProgress * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Lexend',
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFB800),
                    fontFamily: 'Lexend',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                _buildVersionSelector(),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: Colors.white70),
            tooltip: 'Exportar',
            onPressed: _frameCount == 0 ? null : _showExportSheet,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProjectionPage(projects: [_current]))),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cast_rounded, color: Colors.black, size: 16),
                  SizedBox(width: 6),
                  Text('PROYECTAR',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Lexend',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Selector de versión (dropdown). Si solo existe el proyecto actual, no se
  /// muestra (no hay nada que elegir).
  Widget _buildVersionSelector() {
    if (_options.length <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _current.id,
          isDense: true,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: const Icon(Icons.expand_more_rounded,
              color: Color(0xFFBC87FE), size: 18),
          style: const TextStyle(
              color: Colors.white, fontFamily: 'Lexend', fontSize: 12),
          items: _options
              .map((p) => DropdownMenuItem<String>(
                    value: p.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            p.id == widget.project.id
                                ? Icons.movie_rounded
                                : (p.name == 'Inicio'
                                    ? Icons.flag_rounded
                                    : Icons.bookmark_rounded),
                            size: 14,
                            color: const Color(0xFFBC87FE)),
                        const SizedBox(width: 6),
                        Text(_optionLabel(p)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            final p = _options.firstWhere((x) => x.id == id);
            _selectVersion(p);
          },
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bajada con la info de la versión que se está viendo.
          _buildVersionCaption(),
          const SizedBox(height: 12),
          // FPS / foto actual a la derecha.
          Align(alignment: Alignment.centerRight, child: _buildInfoBadge()),
          const SizedBox(height: 12),
          _buildVideoControls(),
        ],
      ),
    );
  }

  /// Bajada: nombre de versión · fecha · nº cuadros · autor(es).
  Widget _buildVersionCaption() {
    final isActual = _current.id == widget.project.id;
    final title = isActual ? 'Versión actual' : _current.name;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  _current.isCollaborative
                      ? Icons.groups_rounded
                      : Icons.person_rounded,
                  size: 14,
                  color: const Color(0xFFFFB800)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Lexend',
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_authorLine(_current)}  ·  ${_dateLine(_current.date)}  ·  $_frameCount cuadros',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        "${_fps.round()} FPS | FOTO: ${_frameCount == 0 ? 0 : _currentFrame + 1}/$_frameCount",
        style: const TextStyle(
          color: Color(0xFFFFB800),
          fontFamily: 'Lexend',
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 35),
          color: _fps > _minFps ? Colors.white60 : Colors.white10,
          onPressed: _fps > _minFps
              ? () {
                  setState(() => _fps -= 2);
                  _startAnimation();
                }
              : null,
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: () => setState(() => _isPlaying = !_isPlaying),
          child: CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFFBC87FE),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 40,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 30),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 35),
          color: _fps < _maxFps ? Colors.white60 : Colors.white10,
          onPressed: _fps < _maxFps
              ? () {
                  setState(() => _fps += 2);
                  _startAnimation();
                }
              : null,
        ),
      ],
    );
  }
}
