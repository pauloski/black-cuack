import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/camera_page.dart';

// --- IMPORTACIONES AUTH Y GALLERY ---
import 'package:blackcuack_studio/src/features/auth/data/auth_service.dart';
import 'package:blackcuack_studio/src/features/auth/presentation/login_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/workshop_gallery_page.dart';

// Importaciones de modelos y persistencia
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/core/persistence/project_storage.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  late final ProjectService _projectService;

  @override
  void initState() {
    super.initState();
    _projectService = ProjectService();
  }

  void _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _confirmDelete(BuildContext context, QuackProject project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFFF4D4D), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "¿BORRAR QUACK?",
          style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFFF4D4D)),
          textAlign: TextAlign.center,
        ),
        content: Text(
          "¿Estás seguro de que quieres eliminar '${project.name}'?",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontFamily: 'Lexend'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4D),
            ),
            onPressed: () async {
              await _projectService.deleteProject(project.id);
              await ProjectStorage.deleteProject(project.id);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text(
              "BORRAR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.groups_rounded,
              color: Color(0xFFC1FFFE),
              size: 28,
            ),
            tooltip: 'Ver Charca Grupal',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WorkshopGalleryPage()),
            ),
          ),
          const SizedBox(width: 5),
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
              style: TextStyle(
                fontFamily: 'Barriecito',
                fontSize: 28,
                color: Color(0xFFBC87FE),
              ),
            ),
            const SizedBox(height: 20),

            QuackButton(
              text: '+ NUEVO PROYECTO',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CameraPage()),
                );
                if (mounted) setState(() {});
              },
            ),

            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECIENTES',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkshopGalleryPage(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Color(0xFFC1FFFE),
                  ),
                  label: const Text(
                    "VER TALLER",
                    style: TextStyle(color: Color(0xFFC1FFFE), fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<List<QuackProject>>(
                stream: _projectService.getProjectsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "Sincronizando...",
                        style: TextStyle(color: Colors.white10, fontSize: 12),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC1FFFE),
                        strokeWidth: 2,
                      ),
                    );
                  }

                  final proyectos = snapshot.data ?? [];

                  if (proyectos.isEmpty) {
                    return const Center(
                      child: Text(
                        "¡Toca el botón de arriba para empezar!",
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    itemCount: proyectos.length,
                    itemBuilder: (context, index) {
                      final p = proyectos[index];

                      // ✅ CORRECCIÓN: Usamos la URL directa de Firebase (Sin Proxy)
                      final String? previewUrl = p.photoPaths.isNotEmpty
                          ? p.photoPaths[0]
                          : null;

                      return GestureDetector(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  CameraPage(projectToLoad: p),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                        onLongPress: () => _confirmDelete(context, p),
                        child: QuackCard(
                          title: p.name,
                          date: "${p.date.day}/${p.date.month}",
                          borderColor: index % 2 == 0
                              ? const Color(0xFFC1FFFE)
                              : const Color(0xFFBC87FE),
                          previewPath: previewUrl, // ✅ URL directa
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
