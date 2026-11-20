import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/core/utils/background_eraser.dart';

// ── Notifier ──────────────────────────────────────────────────────────────────

class _MaskNotifier extends ChangeNotifier {
  final List<Offset> _points = [];
  final Path _path = Path();
  double brushRadius = 80.0;
  Offset? _lastAdded;
  Offset? _cursorPosition;

  List<Offset> get points => _points;
  Path get renderPath => _path;
  bool get hasPoints => _points.isNotEmpty;
  Offset? get cursorPosition => _cursorPosition;

  void startStroke(Offset p) {
    _lastAdded = null;
    _cursorPosition = p;
    addPoint(p);
  }

  void addPoint(Offset p) {
    _cursorPosition = p;
    if (_lastAdded != null) {
      final dx = p.dx - _lastAdded!.dx;
      final dy = p.dy - _lastAdded!.dy;
      final threshold = brushRadius * 0.25;
      if (dx * dx + dy * dy < threshold * threshold) {
        notifyListeners();
        return;
      }
    }
    _lastAdded = p;
    _points.add(p);
    _path.addOval(Rect.fromCircle(center: p, radius: brushRadius));
    notifyListeners();
  }

  void endStroke() {
    _cursorPosition = null;
    notifyListeners();
  }

  void setBrushRadius(double r) {
    brushRadius = r;
  }

  void clear() {
    _points.clear();
    _path.reset();
    _lastAdded = null;
    _cursorPosition = null;
    notifyListeners();
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class EraseToolPage extends StatefulWidget {
  final List<XFile> frames;
  final int workingFrameIndex;

  const EraseToolPage({
    super.key,
    required this.frames,
    this.workingFrameIndex = 0,
  });

  @override
  State<EraseToolPage> createState() => _EraseToolPageState();
}

class _EraseToolPageState extends State<EraseToolPage> {
  Uint8List? _frameBytes;
  Size? _imageSize;

  late final _MaskNotifier _maskNotifier;
  late int _currentIndex;
  late List<String> _framePaths;
  final Set<int> _processedFrames = {};
  int? _refIndex;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.workingFrameIndex;
    _framePaths = widget.frames.map((f) => f.path).toList();
    _maskNotifier = _MaskNotifier();
    _loadCurrentFrame();
  }

  @override
  void dispose() {
    _maskNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentFrame() async {
    final path = _framePaths[_currentIndex];
    final bytes = await _fetchBytes(path);
    final decoded = img.decodeImage(bytes);
    if (decoded != null && mounted) {
      setState(() {
        _frameBytes = bytes;
        _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
      });
    }
  }

  Future<Uint8List> _fetchBytes(String path) async {
    if (path.startsWith('http') || path.startsWith('blob:')) {
      return (await http.get(Uri.parse(path))).bodyBytes;
    }
    return File(path).readAsBytes();
  }

  // ── Navegación con advertencia ────────────────────────────────────────────

  Future<void> _navigateToFrame(int index) async {
    if (_isProcessing) return;
    if (index == _currentIndex || index < 0 || index >= widget.frames.length) return;

    if (_maskNotifier.hasPoints) {
      final confirmed = await _confirmLeaveWithMask();
      if (!confirmed) return;
    }

    _maskNotifier.clear();
    setState(() {
      _currentIndex = index;
      _frameBytes = null;
      _imageSize = null;
    });
    _loadCurrentFrame();
  }

  Future<bool> _confirmLeaveWithMask() async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black54,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Selección sin aplicar',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Lexend',
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Tienes una selección pintada que no se ha borrado todavía. ¿Cambiar de frame de todas formas?',
              style: TextStyle(
                  color: Colors.white70, fontFamily: 'Lexend', fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar',
                    style: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Lexend',
                        fontSize: 13)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Cambiar igual',
                    style:
                        TextStyle(fontFamily: 'Lexend', fontSize: 13)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Fondo limpio ──────────────────────────────────────────────────────────

  void _toggleRefFrame(int index) {
    setState(() => _refIndex = _refIndex == index ? null : index);
    final msg = _refIndex == index
        ? 'Frame ${index + 1} eliminado como fondo limpio'
        : 'Frame ${index + 1} marcado como fondo limpio ✓';
    _snack(msg);
  }

  // ── Aplicar borrado ───────────────────────────────────────────────────────

  Future<void> _applyToCurrentFrame() async {
    if (_isProcessing) return;
    if (!_maskNotifier.hasPoints) {
      _snack('Pinta primero el área del soporte con el pincel');
      return;
    }
    if (_refIndex == null) {
      _snack('Mantén presionado un frame para marcarlo como fondo limpio');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final newPath = await BackgroundEraser.eraseSingleFrame(
        framePath: _framePaths[_currentIndex],
        referencePath: _framePaths[_refIndex!],
        maskPoints: _maskNotifier.points,
        brushRadiusPx: _maskNotifier.brushRadius,
      );

      if (!mounted) return;
      _framePaths[_currentIndex] = newPath;
      _processedFrames.add(_currentIndex);
      _maskNotifier.clear();
      setState(() {
        _isProcessing = false;
        _frameBytes = null;
        _imageSize = null;
      });
      _loadCurrentFrame();
      _snack('Frame ${_currentIndex + 1} borrado ✓');
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _snack('Error: $e', isError: true);
      }
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Lexend')),
      backgroundColor: isError ? AppColors.danger : AppColors.surface,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildCanvas()),
                _buildBrushSlider(),
                _buildTimeline(),
                _buildApplyButton(),
              ],
            ),
          ),
        ),
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
            onPressed: _isProcessing
                ? null
                : () => Navigator.pop(
                      context,
                      _framePaths.map(XFile.new).toList(),
                    ),
          ),
          const Expanded(
            child: Text(
              'BORRAR SOPORTE',
              style: TextStyle(
                color: AppColors.primary,
                fontFamily: 'Lexend',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _maskNotifier,
            builder: (ctx, _) {
              if (!_maskNotifier.hasPoints) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: _maskNotifier.clear,
                icon: const Icon(Icons.replay_rounded,
                    size: 16, color: Colors.white54),
                label: const Text(
                  'Limpiar',
                  style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'Lexend',
                      fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    if (_frameBytes == null || _imageSize == null) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2),
      );
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: _imageSize!.width,
        height: _imageSize!.height,
        child: Stack(
          children: [
            Image.memory(
              _frameBytes!,
              fit: BoxFit.fill,
              width: _imageSize!.width,
              height: _imageSize!.height,
              gaplessPlayback: true,
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => _maskNotifier.startStroke(d.localPosition),
              onPanUpdate: (d) => _maskNotifier.addPoint(d.localPosition),
              onPanEnd: (_) => _maskNotifier.endStroke(),
              onTapDown: (d) => _maskNotifier.startStroke(d.localPosition),
              onTapUp: (_) => _maskNotifier.endStroke(),
              child: ListenableBuilder(
                listenable: _maskNotifier,
                builder: (ctx, _) => CustomPaint(
                  size: _imageSize!,
                  painter: _MaskPainter(_maskNotifier),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrushSlider() {
    return StatefulBuilder(
      builder: (_, setLocal) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Row(
          children: [
            const Icon(Icons.circle_outlined, color: Colors.white38, size: 13),
            Expanded(
              child: SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 2,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                  activeTrackColor: AppColors.danger,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.danger,
                  overlayColor: Color(0x22FF4D4D),
                ),
                child: Slider(
                  value: _maskNotifier.brushRadius,
                  min: 20,
                  max: 400,
                  onChanged: (v) {
                    _maskNotifier.setBrushRadius(v);
                    setLocal(() {});
                  },
                ),
              ),
            ),
            const Icon(Icons.circle, color: Colors.white38, size: 19),
            const SizedBox(width: 8),
            SizedBox(
              width: 28,
              child: Text(
                '${_maskNotifier.brushRadius.round()}',
                style: const TextStyle(
                    color: Colors.white38,
                    fontFamily: 'Lexend',
                    fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timeline unificado ────────────────────────────────────────────────────
  // Tap   → navegar a ese frame (con advertencia si hay máscara)
  // Hold  → marcar/desmarcar como fondo limpio

  Widget _buildTimeline() {
    final refSet = _refIndex != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.timeline,
                  color: AppColors.primary, size: 14),
              const SizedBox(width: 6),
              const Text(
                'TIMELINE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Lexend',
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'editando ${_currentIndex + 1} / ${widget.frames.length}',
                style: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Lexend',
                    fontSize: 10),
              ),
              const Spacer(),
              // Estado del fondo limpio
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: refSet
                      ? AppColors.green.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: refSet
                        ? AppColors.green.withValues(alpha: 0.5)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers_outlined,
                        size: 10,
                        color: refSet
                            ? AppColors.green
                            : Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      refSet
                          ? 'Fondo: Frame ${_refIndex! + 1}'
                          : 'Mantén para fondo',
                      style: TextStyle(
                        color: refSet
                            ? AppColors.green
                            : Colors.white38,
                        fontFamily: 'Lexend',
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.frames.length,
            itemBuilder: (_, i) {
              final isCurrent = i == _currentIndex;
              final isRef = i == _refIndex;
              final isDone = _processedFrames.contains(i);
              final path = _framePaths[i];

              Color borderColor;
              double borderWidth;
              if (isCurrent) {
                borderColor = AppColors.primary;
                borderWidth = 2.5;
              } else if (isRef) {
                borderColor = AppColors.green;
                borderWidth = 2.0;
              } else if (isDone) {
                borderColor =
                    AppColors.green.withValues(alpha: 0.5);
                borderWidth = 1.5;
              } else {
                borderColor = Colors.white24;
                borderWidth = 1.0;
              }

              return GestureDetector(
                onTap: () => _navigateToFrame(i),
                onLongPress: () => _toggleRefFrame(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  width: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border:
                        Border.all(color: borderColor, width: borderWidth),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 8,
                            )
                          ]
                        : isRef
                            ? [
                                BoxShadow(
                                  color: AppColors.green
                                      .withValues(alpha: 0.35),
                                  blurRadius: 6,
                                )
                              ]
                            : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail
                        (path.startsWith('http') || kIsWeb)
                            ? Image.network(path,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, e, s) =>
                                    Container(color: Colors.white10))
                            : Image.file(File(path),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, e, s) =>
                                    Container(color: Colors.white10)),

                        // Overlay: procesado
                        if (isDone && !isRef)
                          Container(
                            color: AppColors.green.withValues(alpha: 0.30),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.green,
                              size: 20,
                            ),
                          ),

                        // Badge: fondo limpio
                        if (isRef)
                          Positioned(
                            top: 3,
                            left: 3,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.layers_rounded,
                                color: Colors.white,
                                size: 9,
                              ),
                            ),
                          ),

                        // Número de frame
                        Positioned(
                          bottom: 2,
                          left: 0,
                          right: 0,
                          child: Text(
                            '${i + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.primary
                                  : isRef
                                      ? AppColors.green
                                      : Colors.white54,
                              fontFamily: 'Lexend',
                              fontSize: 8,
                              shadows: const [
                                Shadow(blurRadius: 4, color: Colors.black)
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: Colors.white12,
            foregroundColor: Colors.black,
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _isProcessing ? null : _applyToCurrentFrame,
          icon: const Icon(Icons.auto_fix_high_rounded, size: 20),
          label: Text(
            'BORRAR EN FRAME ${_currentIndex + 1}',
            style: const TextStyle(
                fontFamily: 'Lexend', fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Borrando soporte...',
              style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Lexend',
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mask CustomPainter ────────────────────────────────────────────────────────

class _MaskPainter extends CustomPainter {
  final _MaskNotifier notifier;

  _MaskPainter(this.notifier) : super(repaint: notifier);

  @override
  void paint(Canvas canvas, Size size) {
    if (notifier.hasPoints) {
      canvas.drawPath(
        notifier.renderPath,
        Paint()
          ..color = const Color(0xAAFF4D4D)
          ..style = PaintingStyle.fill,
      );
    }

    final cursor = notifier.cursorPosition;
    if (cursor != null) {
      canvas.drawCircle(
        cursor,
        notifier.brushRadius,
        Paint()
          ..color = const Color(0x44FF4D4D)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        cursor,
        notifier.brushRadius,
        Paint()
          ..color = const Color(0xCCFF4D4D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MaskPainter old) => true;
}
