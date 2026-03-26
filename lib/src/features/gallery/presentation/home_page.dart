import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/camera_page.dart';

// --- NUEVAS IMPORTACIONES PARA AUTH ---
import 'package:blackcuack_studio/src/features/auth/data/auth_service.dart';
import 'package:blackcuack_studio/src/features/auth/presentation/login_page.dart';

// Importaciones de modelos y persistencia
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/core/persistence/project_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService(); // Instanciamos el servicio

  // --- MÉTODO PARA CERRAR SESIÓN ---
  void _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  // --- MÉTODO PARA CONFIRMAR EL BORRADO (NEÓN) ---
  void _confirmDelete(BuildContext context, QuackProject project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFFF4D4D), width: 2), // Rojo neón
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "¿BORRAR QUACK?",
          style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFFF4D4D)),
          textAlign: TextAlign.center,
        ),
        content: Text(
          "¿Estás seguro de que quieres eliminar '${project.name}'? Esta acción no se puede deshacer.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontFamily: 'Lexend'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4D)),
            onPressed: () async {
              await ProjectStorage.deleteProject(project.id);
              if (context.mounted) {
                Navigator.pop(context); // Cierra el diálogo
                setState(() {}); // Refresca la Home
              }
            },
            child: const Text("BORRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MIS QUACKS',
          style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFC1FFFE)),
        ),
        // --- BOTÓN DE LOGOUT AÑADIDO ---
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFBC87FE)),
            tooltip: 'Cerrar Sesión',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¡Hola, Artista!',
              style: TextStyle(fontFamily: 'Barriecito', fontSize: 28, color: Color(0xFFBC87FE)),
            ),
            const SizedBox(height: 20),
            
            // BOTÓN NUEVO PROYECTO
            QuackButton(
              text: '+ NUEVO PROYECTO',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CameraPage()),
                );
                setState(() {}); // Recarga al volver de la cámara
              },
            ),
            
            const SizedBox(height: 40),
            const Text(
              'RECIENTES',
              style: TextStyle(
                fontFamily: 'Lexend', 
                fontWeight: FontWeight.bold, 
                color: Colors.white70, 
                letterSpacing: 2
              ),
            ),
            const SizedBox(height: 20),
            
            // GALERÍA DINÁMICA
            Expanded(
              child: FutureBuilder<List<QuackProject>>(
                future: ProjectStorage.loadProjects(), // Aquí luego cambiaremos a Firestore
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFC1FFFE)));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_motion, size: 60, color: Colors.white10),
                          SizedBox(height: 10),
                          Text(
                            "¡No hay proyectos todavía!", 
                            style: TextStyle(color: Colors.white24, fontFamily: 'Lexend')
                          ),
                        ],
                      ),
                    );
                  }

                  final proyectos = snapshot.data!;
                  
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: proyectos.length,
                    itemBuilder: (context, index) {
                      final p = proyectos[index];
                      
                      return GestureDetector(
                        onTap: () async {
                          // NAVEGAR A EDICIÓN
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CameraPage(projectToLoad: p),
                            ),
                          );
                          setState(() {}); // Refresca si se editó algo
                        },
                        onLongPress: () {
                          // ACTIVAR BORRADO CON TOQUE LARGO
                          _confirmDelete(context, p);
                        },
                        child: QuackCard(
                          title: p.name,
                          date: "${p.date.day}/${p.date.month}",
                          borderColor: index % 2 == 0 
                              ? const Color(0xFFC1FFFE) 
                              : const Color(0xFFBC87FE),
                          previewPath: p.photoPaths.isNotEmpty ? p.photoPaths[0] : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}