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
// ✅ Importa tus utils para generar el código
import 'package:blackcuack_studio/src/core/utils/group_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  late final ProjectService _projectService;
  // Controlador para el input del código
  final TextEditingController _groupCodeController = TextEditingController();

  // 💡 TODO: Esto vendrá de un Stream de Firebase más adelante
  bool hasGroups = false;

  @override
  void initState() {
    super.initState();
    _projectService = ProjectService();
  }

  @override
  void dispose() {
    _groupCodeController.dispose();
    super.dispose();
  }

  // --- MODAL DE GESTIÓN DE GRUPOS (VERSION CORREGIDA) ---
  void _showGroupManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 25,
          right: 25,
          top: 15,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "MI CHARCA",
              style: TextStyle(
                fontFamily: 'LuckiestGuy',
                fontSize: 24,
                color: Color(0xFFC1FFFE),
              ),
            ),
            const SizedBox(height: 10),

            // ✅ AYUDA CONTEXTUAL
            if (!hasGroups)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Aun no te has unido ni creado ningún grupo",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontFamily: 'Lexend',
                  ),
                ),
              ),

            const SizedBox(height: 25),

            // SECCIÓN: UNIRSE
            _buildGroupActionCard(
              title: "UNIRSE A UN GRUPO",
              icon: Icons.group_add_rounded,
              color: const Color(0xFFBC87FE),
              child: TextField(
                controller: _groupCodeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 5,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                decoration: InputDecoration(
                  hintText: "CÓDIGO EJ: BQC2X",
                  hintStyle: const TextStyle(
                    color: Colors.white12,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: Colors.black26,
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFBC87FE),
                    ),
                    onPressed: () {
                      print(
                        "Uniendo al grupo: ${_groupCodeController.text.toUpperCase()}",
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),
            const Text(
              "O",
              style: TextStyle(
                color: Colors.white10,
                fontFamily: 'LuckiestGuy',
              ),
            ),
            const SizedBox(height: 15),

            // SECCIÓN: CREAR
            _buildGroupActionCard(
              title: "CREAR NUEVO GRUPO",
              icon: Icons.add_box_rounded,
              color: const Color(0xFFC1FFFE),
              child: QuackButton(
                text: "GENERAR CÓDIGO",
                onPressed: () {
                  final newCode = GroupUtils.generateGroupCode();
                  print("Nuevo grupo creado con código: $newCode");
                },
              ),
            ),

            const SizedBox(height: 20),

            // ✅ BOTÓN SECUNDARIO
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WorkshopGalleryPage()),
              ),
              icon: const Icon(
                Icons.auto_awesome_motion_rounded,
                size: 16,
                color: Colors.white24,
              ),
              label: const Text(
                "VER GALERÍA DE GRUPOS",
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
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
          "¿Estás seguro de que quieres eliminar '${project.name}'?",
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
          IconButton(
            icon: const Icon(
              Icons.groups_rounded,
              color: Color(0xFFC1FFFE),
              size: 28,
            ),
            tooltip: 'Mis Grupos',
            onPressed: () => _showGroupManagement(context),
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_rounded,
              color: Color(0xFFBC87FE),
              size: 28,
            ),
            tooltip: 'Mi Perfil',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
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
            _buildSectionHeader(context),
            const SizedBox(height: 10),
            Expanded(child: _buildProjectGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'MIS PROYECTOS',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.bold,
            color: Colors.white38,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
        TextButton.icon(
          onPressed: () => _showGroupManagement(context),
          icon: const Icon(
            Icons.hub_rounded,
            size: 14,
            color: Color(0xFFC1FFFE),
          ),
          label: const Text(
            "MIS GRUPOS",
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
