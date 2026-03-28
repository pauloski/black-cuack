import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

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
      ),
      body: StreamBuilder<List<QuackProject>>(
        stream: _projectService.getAllWorkshopProjects(),
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
              childAspectRatio: 0.85,
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
    // ✅ URL DIRECTA SIN PROXY
    final String imageUrl = p.photoPaths.isNotEmpty ? p.photoPaths.first : '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFBC87FE).withOpacity(0.5),
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
              child: p.photoPaths.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      // Estrategia para evitar bloqueos:
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white10,
                            size: 40,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white10,
                          ),
                        );
                      },
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
                    color: Colors.white,
                    fontFamily: 'LuckiestGuy',
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "POR ARTISTA ANÓNIMO",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (los widgets _buildErrorState y _buildEmptyState se mantienen igual)
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 50,
            ),
            const SizedBox(height: 10),
            const Text(
              "¡ALGO SALIÓ MAL!",
              style: TextStyle(color: Colors.white, fontFamily: 'LuckiestGuy'),
            ),
            const SizedBox(height: 10),
            Text(
              error.contains("requires an index")
                  ? "FIREBASE ESTÁ PREPARANDO EL ÍNDICE. ESPERA 5 MINUTOS."
                  : "ERROR DE CONEXIÓN",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, color: Colors.white10, size: 80),
          SizedBox(height: 10),
          Text(
            "LA CHARCA ESTÁ VACÍA",
            style: TextStyle(color: Colors.white24, fontFamily: 'LuckiestGuy'),
          ),
          Text(
            "¡SÉ EL PRIMERO EN SUBIR TU QUACK!",
            style: TextStyle(color: Colors.white10, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
