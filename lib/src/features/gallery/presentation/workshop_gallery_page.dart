import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
// ✅ Importamos el reproductor de cine
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/movie_player_page.dart';

class WorkshopGalleryPage extends StatelessWidget {
  final ProjectService _projectService = ProjectService();

  WorkshopGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: const Text(
          "LA CHARCA GRUPAL 🦆",
          style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFC1FFFE)),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<QuackProject>>(
        stream: _projectService.getWorkshopProjects("TALLER_TEST"),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFBC87FE)),
                  SizedBox(height: 20),
                  Text(
                    "BUSCANDO PATOS EN LA NUBE...",
                    style: TextStyle(
                      color: Colors.white24,
                      fontFamily: 'Lexend',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.8,
            ),
            itemCount: projects.length,
            itemBuilder: (context, index) =>
                _workshopCard(context, projects[index]),
          );
        },
      ),
    );
  }

  Widget _workshopCard(BuildContext context, QuackProject p) {
    final String imageUrl = p.photoPaths.isNotEmpty ? p.photoPaths.first : '';

    return GestureDetector(
      // ✅ AL TOCAR: Abrimos el Modo Cine para ver la animación del compañero
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MoviePlayerPage(project: p)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFBC87FE).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white10,
                                size: 40,
                              ),
                            ),
                      )
                    : const Center(
                        child: Icon(Icons.videocam, color: Colors.white10),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFC1FFFE),
                      fontFamily: 'LuckiestGuy',
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.palette,
                        size: 10,
                        color: Color(0xFFBC87FE),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.artistName.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 9,
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOS MÉTODOS DE ESTADO SE MANTIENEN IGUAL ---
  Widget _buildErrorState(String error) {
    /* ... igual al anterior ... */
    return const SizedBox();
  }

  Widget _buildEmptyState() {
    /* ... igual al anterior ... */
    return const SizedBox();
  }
}
