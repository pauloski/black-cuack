import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';

class QrInviteDialog extends StatelessWidget {
  final String sessionCode;
  final Stream<List<String>> frameStream;
  final VoidCallback onClose;

  const QrInviteDialog({
    super.key,
    required this.sessionCode,
    required this.frameStream,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Reads the actual origin the app was loaded from at runtime.
    // If opened via cloudflared (https://xxx.trycloudflare.com), the QR
    // inherits that HTTPS URL automatically — no recompile needed.
    final origin = html.window.location.origin;
    final joinUrl = '$origin/#/join?code=$sessionCode';
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📡 CÁMARA REMOTA',
              style: TextStyle(
                fontFamily: 'Lexend',
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Escanea con el celular en la misma red WiFi\nNo necesitas instalar ninguna app',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontFamily: 'Lexend',
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: joinUrl,
                size: 170,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: joinUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enlace copiado',
                        style: TextStyle(fontFamily: 'Lexend')),
                    backgroundColor: AppColors.secondary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link, color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        joinUrl,
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sessionCode,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  color: AppColors.secondary,
                  fontSize: 30,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<String>>(
              stream: frameStream,
              builder: (context, snap) {
                final count = snap.data?.length ?? 0;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    key: ValueKey(count),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        count > 0
                            ? Icons.photo_library
                            : Icons.hourglass_empty,
                        color: count > 0 ? AppColors.primary : Colors.white24,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        count > 0
                            ? '$count frame${count == 1 ? '' : 's'} recibidos'
                            : 'Esperando frames...',
                        style: TextStyle(
                          color: count > 0 ? Colors.white70 : Colors.white24,
                          fontFamily: 'Lexend',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onClose,
                icon: const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                label: const Text(
                  'CERRAR SESIÓN',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    color: Colors.white,
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
