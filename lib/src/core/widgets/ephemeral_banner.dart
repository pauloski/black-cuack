import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/config/repositories.dart';

/// Aviso persistente cuando el almacén activo **no persiste** (respaldo en
/// memoria porque Hive no abrió). Si todo está bien, no ocupa espacio.
class EphemeralStorageBanner extends StatelessWidget {
  const EphemeralStorageBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!repositoryIsEphemeral) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFFFF4D4D),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Este navegador no permite guardar; tu trabajo se perderá al cerrar.',
                  style: TextStyle(
                      color: Colors.white, fontFamily: 'Lexend', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
