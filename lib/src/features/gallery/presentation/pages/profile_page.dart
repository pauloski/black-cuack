import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // 🌐 Abre la política de privacidad hospedada en Cloudflare Pages
  Future<void> _launchPrivacyUrl() async {
    final Uri url = Uri.parse('https://black-cuack-privacy.pages.dev/');
    try {
      // Usamos LaunchMode.externalApplication para que abra en el navegador nativo
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir la página $url');
      }
    } catch (e) {
      debugPrint('Error al intentar abrir la URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final projectService = ProjectService();

    // 🚪 Función para Cerrar Sesión
    Future<void> _handleLogout() async {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }

    // ⚠️ Función para manejar el borrado de cuenta con confirmación
    Future<void> _handleDeleteAccount() async {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "⚠️ ¿BORRAR CUENTA?",
            style: TextStyle(color: Colors.white, fontFamily: 'LuckiestGuy'),
          ),
          content: const Text(
            "Esta acción eliminará para siempre tu cuenta y todos tus proyectos. ¡No podrás recuperarlos! 🦆💥",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'Lexend',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "CANCELAR",
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D4D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "BORRAR PARA SIEMPRE",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFC1FFFE)),
          ),
        );

        try {
          await projectService.deleteUserAccount();
          if (context.mounted) {
            Navigator.pop(context); // Quitar loading
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Quitar loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Error al borrar: $e",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: const Text(
          "MI PERFIL 🦆",
          style: TextStyle(color: Color(0xFFC1FFFE), fontFamily: 'LuckiestGuy'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            // --- INFO DE USUARIO ---
            const Icon(
              Icons.account_circle,
              size: 80,
              color: Color(0xFFBC87FE),
            ),
            const SizedBox(height: 15),
            Text(
              user?.email ?? 'Artista Anónimo',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Lexend',
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "ID: ${user?.uid.substring(0, 8).toUpperCase()}...",
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 40),

            // --- MENÚ DE OPCIONES ---
            _buildProfileOption(
              icon: Icons.privacy_tip_outlined,
              title: "POLÍTICA DE PRIVACIDAD",
              color: const Color(0xFFC1FFFE),
              onTap: _launchPrivacyUrl,
            ),
            _buildProfileOption(
              icon: Icons.logout_rounded,
              title: "CERRAR SESIÓN",
              color: Colors.white70,
              onTap: _handleLogout,
            ),

            const Spacer(),

            // --- BOTÓN DE BORRADO (ZONA DE PELIGRO) ---
            TextButton.icon(
              icon: const Icon(
                Icons.delete_forever,
                color: Color(0xFFFF4D4D),
                size: 18,
              ),
              label: const Text(
                "BORRAR MI CUENTA Y DATOS",
                style: TextStyle(
                  color: Color(0xFFFF4D4D),
                  fontSize: 12,
                  fontFamily: 'Lexend',
                  decoration: TextDecoration.underline,
                ),
              ),
              onPressed: _handleDeleteAccount,
            ),
            const SizedBox(height: 10),
            const Text(
              "v0.9.2 (Beta Taller)",
              style: TextStyle(color: Colors.white10, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para las opciones del menú
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white.withOpacity(0.03),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Lexend',
            fontSize: 13,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white12,
          size: 20,
        ),
      ),
    );
  }
}
