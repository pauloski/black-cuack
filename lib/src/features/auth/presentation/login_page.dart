import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:blackcuack_studio/src/features/auth/data/auth_service.dart';
import 'package:blackcuack_studio/src/features/workshop/presentation/workshop_entry_page.dart'
    show WorkshopMode;

/// Acceso (demo): 3 caminos. Solo **código de sala** funciona; docente y usuario
/// registrado quedan como "flujo en desarrollo".
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  // ── Entrada por código de sala (estudiante) ───────────────────────────────
  void _enterWithCode() {
    // El intento anónimo corre en segundo plano con timeout; la entrada NO lo
    // espera (así funciona sin conexión y no se cuelga).
    unawaited(_tryAnonymous());
    // pushNamed (no replacement) para que "volver" regrese al Login.
    Navigator.pushNamed(context, '/workshop', arguments: WorkshopMode.student);
  }

  Future<void> _tryAnonymous() async {
    try {
      await _authService
          .signInAnonymously()
          .timeout(const Duration(seconds: 4));
    } on TimeoutException {
      debugPrint('Inicio anónimo: timeout (seguimos sin conexión).');
    } catch (e) {
      debugPrint('Inicio anónimo falló: $e');
    }
  }

  void _comingSoon(String flujo) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$flujo · flujo en desarrollo 🛠️',
          style: const TextStyle(fontFamily: 'Lexend')),
      backgroundColor: const Color(0xFF333333),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _devAccessButton(String label, IconData icon, String flujo) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _comingSoon(flujo),
        icon: Icon(icon, color: Colors.white38, size: 18),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                    fontSize: 13)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('pronto',
                  style: TextStyle(color: Colors.white38, fontSize: 9)),
            ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Center(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/images/logo-login.svg',
                        height: 154),
                    const SizedBox(height: 44),

                    // 1) Acceso con código de sala (funcional).
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _enterWithCode,
                        icon: const Icon(Icons.meeting_room_rounded,
                            color: Colors.black, size: 20),
                        label: const Text(
                          'ENTRAR CON CÓDIGO DE SALA',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lexend',
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB800),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2) Acceso docente (en desarrollo).
                    _devAccessButton('ACCESO DOCENTE', Icons.school_rounded,
                        'Acceso docente'),
                    const SizedBox(height: 10),

                    // 3) Usuario registrado (en desarrollo).
                    _devAccessButton('USUARIO REGISTRADO', Icons.person_rounded,
                        'Usuario registrado'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
