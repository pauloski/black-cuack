import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/camera_page.dart';

// --- IMPORTACIONES AUTH, GALLERY Y CINE ---
import 'package:blackcuack_studio/src/features/auth/data/auth_service.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/workshop_gallery_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/profile_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/movie_player_page.dart';

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

  // ... (Mantenemos tu función _confirmDelete igual)
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
          "¿Estás seguro de que quieres eliminar '${project.name}'?\nEsta acción no se puede deshacer.",
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
        centerTitle: false,
        title: const Text(
          'MIS QUACKS',
          style: TextStyle(
            fontFamily: 'LuckiestGuy',
            color: Color(0xFFC1FFFE),
            fontSize: 22,
          ),
        ),
        actions: [
          // 🦆 BOTÓN DE CHARCA (GRUPO)
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
          // 👤 BOTÓN DE PERFIL (RUTA NOMBRADA)
          IconButton(
            icon: const Icon(
              Icons.account_circle_rounded,
              color: Color(0xFFBC87FE),
              size: 28,
            ),
            tooltip: 'Mi Perfil',
            onPressed: () => Navigator.pushNamed(
              context,
              '/profile',
            ), // ✅ Usa la ruta del main.dart
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // 🔥 Un saludo dinámico se vería genial aquí más adelante
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

            const SizedBox(height: 35),

            // ... (Mantenemos el resto del StreamBuilder y GridView igual como lo tienes)
            _buildSectionHeader(context),
            const SizedBox(height: 10),

            Expanded(child: _buildProjectGrid()),
          ],
        ),
      ),
    );
  }

  // He extraído esto para limpiar el build principal
  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'RECIENTES',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.bold,
            color: Colors.white38,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
        TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WorkshopGalleryPage()),
          ),
          icon: const Icon(
            Icons.arrow_forward,
            size: 14,
            color: Color(0xFFC1FFFE),
          ),
          label: const Text(
            "VER TALLER",
            style: TextStyle(
              color: Color(0xFFC1FFFE),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectGrid() {
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
}
