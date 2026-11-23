import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/config/repositories.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/profile/data/profile_service.dart';
import 'package:blackcuack_studio/src/features/workshop/data/workshop_service.dart'
    show activeWorkshopCode;
import 'package:blackcuack_studio/src/features/workshop/presentation/team_helpers.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/movie_player_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/camera_page.dart';

class ProjectGridView extends StatefulWidget {
  final double bottomPadding;
  const ProjectGridView({super.key, this.bottomPadding = 0});

  @override
  State<ProjectGridView> createState() => _ProjectGridViewState();
}

class _ProjectGridViewState extends State<ProjectGridView> {
  late Future<List<QuackProject>> _future;
  // id de perfil → avatar (emoji), para mostrar los miembros en cada tarjeta.
  Map<String, String> _avatarById = {};

  @override
  void initState() {
    super.initState();
    _future = projectRepository.loadProjects();
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    final profiles = await ProfileService.list();
    if (!mounted) return;
    setState(() =>
        _avatarById = {for (final p in profiles) p.id: p.avatar});
  }

  void _reload() {
    setState(() => _future = projectRepository.loadProjects());
    _loadAvatars();
  }

  /// Gestiona el equipo de un proyecto ya creado: agrega/quita miembros.
  Future<void> _manageTeam(QuackProject p) async {
    final picked = await showTeamSheet(
      context,
      initial: p.memberProfileIds.toSet(),
      owner: p.ownerProfileId,
      title: 'EQUIPO DE "${p.name}"',
    );
    if (picked == null) return;
    await projectRepository
        .saveProject(p.copyWith(memberProfileIds: picked.toList()));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuackProject>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.secondary, strokeWidth: 2),
          );
        }
        // Un borrador con 0 cuadros no aparece; las versiones (parentId) tampoco.
        // Visible si soy del equipo (dueño o compañero). En una sala, además se
        // muestran los proyectos de esta sala y los sin etiqueta (no se esconde
        // nada). Así un proyecto que creó un pato con una rana y un perro
        // aparece en los perfiles de los tres.
        final inWorkshop = activeWorkshopCode.isNotEmpty;
        final proyectos = (snapshot.data ?? [])
            .where((p) {
              if (p.photoPaths.isEmpty || p.parentId != null) return false;
              final mine = p.ownerProfileId == activeProfileId ||
                  p.memberProfileIds.contains(activeProfileId);
              return inWorkshop
                  ? (mine ||
                      p.workshopCode == activeWorkshopCode ||
                      p.workshopCode == null ||
                      p.workshopCode!.isEmpty)
                  : mine;
            })
            .toList();
        if (proyectos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_filter_outlined,
                    color: Colors.white12, size: 56),
                SizedBox(height: 14),
                Text('Sin proyectos todavía',
                    style: TextStyle(
                        color: Colors.white38,
                        fontFamily: 'Lexend',
                        fontSize: 15)),
                SizedBox(height: 6),
                Text('Crea tu primera animación',
                    style: TextStyle(
                        color: Colors.white24,
                        fontFamily: 'Lexend',
                        fontSize: 12)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.only(bottom: widget.bottomPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.88,
          ),
          itemCount: proyectos.length,
          itemBuilder: (context, index) {
            final p = proyectos[index];
            final String? firstId =
                p.photoPaths.isNotEmpty ? p.photoPaths.first : null;
            return _ProjectCard(
              project: p,
              previewFrameId: firstId,
              memberAvatars: p.memberProfileIds
                  .map((id) => _avatarById[id])
                  .whereType<String>()
                  .toList(),
              onManageTeam: () => _manageTeam(p),
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MoviePlayerPage(project: p)),
              ),
              onEdit: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CameraPage(projectToLoad: p)),
                );
                _reload();
              },
              onDelete: () => _confirmDelete(context, p),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, QuackProject project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.danger, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('¿ELIMINAR?',
            style: TextStyle(
                fontFamily: 'Lexend', color: AppColors.danger, fontSize: 16),
            textAlign: TextAlign.center),
        content: Text(
          "'${project.name}' será eliminado permanentemente.",
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white54, fontFamily: 'Lexend', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await projectRepository.deleteProject(project.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Proyecto eliminado'),
                    backgroundColor: AppColors.danger),
              );
              _reload();
            },
            child: const Text('ELIMINAR',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Project card with overlay action buttons ──────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final QuackProject project;
  final String? previewFrameId;
  final List<String> memberAvatars; // avatares de los miembros del equipo
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageTeam;

  const _ProjectCard({
    required this.project,
    required this.previewFrameId,
    this.memberAvatars = const [],
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onManageTeam,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    child: _Thumbnail(frameId: previewFrameId),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${project.date.day}/${project.date.month}',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontFamily: 'Lexend',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Equipo del proyecto: avatares de los miembros (hasta 4) arriba-izq.
          if (memberAvatars.isNotEmpty)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final a in memberAvatars.take(4))
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Text(a, style: const TextStyle(fontSize: 14)),
                      ),
                    if (memberAvatars.length > 4)
                      Text('+${memberAvatars.length - 4}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Lexend',
                              fontSize: 10)),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: Row(
              children: [
                _OverlayBtn(
                  icon: Icons.group_add_rounded,
                  color: AppColors.secondary,
                  onTap: onManageTeam,
                ),
                const SizedBox(width: 5),
                _OverlayBtn(
                  icon: Icons.edit_rounded,
                  color: AppColors.primary,
                  onTap: onEdit,
                ),
                const SizedBox(width: 5),
                _OverlayBtn(
                  icon: Icons.delete_rounded,
                  color: AppColors.danger,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Miniatura del primer cuadro, leída como **bytes** del repo local
/// (`Image.memory`), para que persista tras recargar (sin depender de CORS).
class _Thumbnail extends StatelessWidget {
  final String? frameId;
  const _Thumbnail({required this.frameId});

  @override
  Widget build(BuildContext context) {
    final id = frameId;
    if (id == null) return _placeholder();
    return FutureBuilder<Uint8List?>(
      future: projectRepository.loadFrameBytes(id),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) return _placeholder();
        return Image.memory(bytes, fit: BoxFit.cover,
            gaplessPlayback: true);
      },
    );
  }

  Widget _placeholder() => const Center(
        child: Icon(Icons.movie_filter_rounded,
            color: Colors.white12, size: 36),
      );
}

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverlayBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}
