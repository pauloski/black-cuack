import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final projectService = ProjectService();

    // Función para manejar el borrado de cuenta con confirmación
    Future<void> _handleDeleteAccount() async {
      // 1. Mostrar diálogo de confirmación (Crucial para no borrar por error)
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            "⚠️ ¿BORRAR CUENTA?",
            style: TextStyle(color: Colors.white, fontFamily: 'LuckiestGuy'),
          ),
          content: const Text(
            "Esta acción eliminará para siempre tu cuenta y todos tus proyectos. ¡No podrás recuperarlos! 🦆💥",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D4D),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("BORRAR PARA SIEMPRE"),
            ),
          ],
        ),
      );

      // 2. Si confirmó, borrar la cuenta
      if (confirm == true) {
        // Mostrar loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        try {
          // ✅ Llamamos al método que ya creamos en el service
          await projectService.deleteUserAccount();

          if (context.mounted) {
            Navigator.pop(context); // Quitar loading
            // Volver al Login y limpiar el historial de navegación
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Quitar loading
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error al borrar: $e")));
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: const Text(
          "PERFIL 🦆",
          style: TextStyle(color: Color(0xFFC1FFFE), fontFamily: 'LuckiestGuy'),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(
              Icons.account_circle,
              size: 80,
              color: Color(0xFFBC87FE),
            ),
            const SizedBox(height: 15),
            Text(
              user?.email ?? 'Artista Anónimo',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'Lexend',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "ID: ${user?.uid.substring(0, 8)}...",
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
            const Spacer(), // Empuja el resto hacia abajo
            // --- BOTÓN DE BORRADO DE CUENTA (OBLIGATORIO) ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.delete_forever,
                  color: Color(0xFFFF4D4D),
                ),
                label: const Text(
                  "BORRAR MI CUENTA Y DATOS",
                  style: TextStyle(
                    color: Color(0xFFFF4D4D),
                    fontFamily: 'Lexend',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF4D4D)),
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: _handleDeleteAccount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
