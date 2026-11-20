import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/remote/data/remote_session_service.dart';
import 'package:blackcuack_studio/src/features/remote/presentation/remote_camera_page.dart';

class JoinSessionPage extends StatefulWidget {
  const JoinSessionPage({super.key});

  @override
  State<JoinSessionPage> createState() => _JoinSessionPageState();
}

class _JoinSessionPageState extends State<JoinSessionPage> {
  final _codeController = TextEditingController();
  final _service = RemoteSessionService();
  MobileScannerController? _scanController;

  bool _isLoading = false;
  bool _scanMode = false;
  bool _scanned = false;
  bool _autoConnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoConnectFromUrl());
  }

  void _autoConnectFromUrl() {
    if (!kIsWeb) return;
    try {
      // Hash routing: URI.base.fragment = '/join?code=XXXXXX'
      final fragment = Uri.base.fragment;
      final code = Uri.parse(fragment).queryParameters['code'];
      if (code != null && code.length == 6) {
        setState(() => _autoConnecting = true);
        _connect(code);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scanController?.dispose();
    super.dispose();
  }

  Future<void> _connect(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.length != 6) {
      _showError('El código debe tener 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);
    final active = await _service.sessionIsActive(trimmed);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!active) {
      _showError('Sesión no encontrada o ya cerrada 🦆');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RemoteCameraPage(sessionCode: trimmed),
      ),
    );
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue ?? '';
    if (raw.length == 6) {
      _scanned = true;
      _scanController?.stop();
      _connect(raw);
    }
  }

  void _toggleScan() {
    if (_scanMode) {
      _scanController?.dispose();
      _scanController = null;
      setState(() {
        _scanMode = false;
        _scanned = false;
      });
    } else {
      setState(() {
        _scanMode = true;
        _scanned = false;
        _scanController = MobileScannerController();
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Lexend')),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_autoConnecting) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 24),
              Text(
                'Conectando al estudio...',
                style: TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Lexend',
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'UNIRSE COMO CÁMARA',
          style: TextStyle(
            fontFamily: 'Lexend',
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.camera_alt, color: AppColors.secondary, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Ingresa el código de 6 letras\nque aparece en el estudio',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontFamily: 'Lexend',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),

            if (_scanMode) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 260,
                  child: MobileScanner(
                    controller: _scanController!,
                    onDetect: _onQrDetected,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _toggleScan,
                child: const Text(
                  'INGRESAR CÓDIGO MANUALMENTE',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ] else ...[
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 30,
                  letterSpacing: 8,
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
                maxLength: 6,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: const TextStyle(
                    color: Colors.white12,
                    fontSize: 30,
                    letterSpacing: 8,
                    fontFamily: 'Lexend',
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _toggleScan,
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.primary,
                  size: 18,
                ),
                label: const Text(
                  'ESCANEAR QR',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Lexend',
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            if (_isLoading)
              const CircularProgressIndicator(color: AppColors.secondary)
            else if (!_scanMode)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _codeController.text.length == 6
                      ? () => _connect(_codeController.text)
                      : null,
                  child: const Text(
                    'CONECTAR 📡',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
