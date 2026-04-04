import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';
import 'package:blackcuack_studio/src/core/persistence/project_storage.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/movie_player_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/camera_page.dart';

class ProjectGridView extends StatefulWidget {
  const ProjectGridView({super.key});

  @override
  State<ProjectGridView> createState() => _ProjectGridViewState();
}

class _ProjectGridViewState extends State<ProjectGridView> {
  late final ProjectService _projectService;

  @override
  void initState() {
    super.initState();
    _projectService = ProjectService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuackProject>>(
      stream: _projectService.getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFBC87FE),
              strokeWidth: 2,
            ),
          );
        }
        final proyectos = snapshot.data ?? [];
        if (proyectos.isEmpty) {
          return const Center(
            child: Text(
              "¡Toca el botón de arriba para empezar!",
              style: TextStyle(color: Colors.white10, fontSize: 12),
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.9,
          ),
          itemCount: proyectos.length,
          itemBuilder: (context, index) {
            final p = proyectos[index];
            final String? previewUrl = p.photoPaths.isNotEmpty
                ? p.photoPaths[0]
                : null;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoviePlayerPage(project: p),
                ),
              ),
              onLongPress: () => _showOptionsDialog(context, p),
              child: Column(
                children: [
                  Expanded(
                    child: QuackCard(
                      title: p.name,
                      date: "${p.date.day}/${p.date.month}",
                      borderColor: index % 2 == 0
                          ? const Color(0xFFC1FFFE)
                          : const Color(0xFFBC87FE),
                      previewPath: previewUrl,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "POR: ${p.artistName.toUpperCase()}",
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 8,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- DIÁLOGOS DE GESTIÓN (MOVIDOS AQUÍ PARA LIMPIAR LA HOME) ---

  void _showOptionsDialog(BuildContext context, QuackProject p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFFC1FFFE)),
            title: const Text(
              'EDITAR PROYECTO',
              style: TextStyle(color: Colors.white, fontFamily: 'Lexend'),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CameraPage(projectToLoad: p),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Color(0xFFFF4D4D)),
            title: const Text(
              'BORRAR QUACK',
              style: TextStyle(color: Color(0xFFFF4D4D), fontFamily: 'Lexend'),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, p);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
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
          "¿Estás seguro de que quieres eliminar '${project.name}'?\nEsta acción limpiará todas las fotos de la nube. 🧹",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Lexend',
            fontSize: 12,
          ),
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
              // 1. Mostramos un indicador de carga rápido para el borrado
              debugPrint("🦆 Borrando fotos y datos...");

              // 2. Llamamos al nuevo método con los DOS parámetros necesarios
              await _projectService.deleteProjectFull(
                project.id,
                project
                    .photoPaths, // ✅ Ahora pasamos la lista de fotos para limpiar Storage
              );

              // 3. Limpiamos cache local si existe
              await ProjectStorage.deleteProject(project.id);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("¡Charca limpiada con éxito! 🧹🦆"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
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
}
