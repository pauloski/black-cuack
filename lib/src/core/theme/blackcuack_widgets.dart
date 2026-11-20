import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0E0E0E);
  static const surface    = Color(0xFF1A1A1A);
  static const primary    = Color(0xFFFFB800);
  static const secondary  = Color(0xFFBC87FE);
  static const green      = Color(0xFF4CAF50);
  static const tertiary   = Color(0xFFF3FFCA);
  static const danger     = Color(0xFFFF4D4D);
}

// --- BOTÓN PRINCIPAL ---
class QuackButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const QuackButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

// --- TARJETA DE PROYECTO (CORREGIDA) ---
// En lib/src/core/theme/blackcuack_widgets.dart

class QuackCard extends StatelessWidget {
  final String title;
  final String date;
  final Color borderColor;
  final String? previewPath;

  const QuackCard({
    super.key,
    required this.title,
    required this.date,
    required this.borderColor,
    this.previewPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.black38,
                image: (previewPath != null && previewPath!.isNotEmpty)
                    ? DecorationImage(
                        // TRUCO PARA WEB: Si es web usamos network, si no File
                        image: (kIsWeb) 
                            ? NetworkImage(previewPath!) as ImageProvider
                            : FileImage(File(previewPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (previewPath == null || previewPath!.isEmpty)
                  ? const Icon(Icons.play_circle_outline, color: Colors.white24, size: 40)
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Lexend'),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'Lexend'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}