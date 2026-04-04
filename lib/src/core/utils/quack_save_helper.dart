import 'package:flutter/material.dart';
import 'package:blackcuack_studio/main.dart'; // Importante para navigatorKey
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

class QuackSaveHelper {
  static final ProjectService _projectService = ProjectService();

  // 🦆 Diálogo de Carga (El Patito)
  static void showLoadingQuack() {
    // Usamos el contexto global para que no dependa de la página de la cámara
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => PopScope(
        canPop: false, // Bloquea el botón atrás
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              CircularProgressIndicator(
                color: Color(0xFFC1FFFE),
                strokeWidth: 5,
              ),
              SizedBox(height: 25),
              Text(
                "🎬 ¡PUBLICANDO OBRA!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'LuckiestGuy',
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "El patito está nadando...\nNo cierres la pestaña. 🦆",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Lexend',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 Lógica de Guardado y Salida Blindada
  static Future<void> saveAndExit({required QuackProject project}) async {
    // 1. Mostrar Patito inmediatamente
    showLoadingQuack();

    try {
      // 2. Intentar guardar con un Timeout de 15 segundos (especial para Flutter Web)
      await _projectService
          .saveProject(project)
          .timeout(const Duration(seconds: 15));

      debugPrint("🦆 ¡Proyecto '${project.name}' guardado correctamente!");
    } catch (e) {
      // Catch para capturar errores de credenciales o de protocolo QUIC de Chrome
      debugPrint(
        "🦆 Quack Debug: Error o Timeout detectado, forzando salida segura. $e",
      );
    } finally {
      // 3. 🛡️ SALIDA ATÓMICA (Garantiza que la App no se quede colgada)
      if (navigatorKey.currentState != null) {
        // Quitamos el patito usando la llave global
        navigatorKey.currentState!.pop();

        // AJUSTE DE ESTABILIDAD: Damos 500ms para que Chrome limpie el overlay de memoria
        await Future.delayed(const Duration(milliseconds: 500));

        // RESET ABSOLUTO: Volvemos a la Home eliminando la cámara del historial
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    }
  }
}
