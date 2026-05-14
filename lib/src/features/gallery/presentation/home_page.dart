import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart'; // AppColors + QuackButton
import 'package:blackcuack_studio/src/features/gallery/presentation/camera_page.dart';
// ✅ Importaciones corregidas de tus widgets separados
import 'package:blackcuack_studio/src/features/gallery/presentation/widgets/project_grid_view.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/widgets/group_management_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'MIS QUACKS',
          style: TextStyle(
            fontFamily: 'LuckiestGuy',
            color: AppColors.primary,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.groups_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            tooltip: 'Mis Grupos',
            onPressed: () => showGroupManagementSheet(context),
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_rounded,
              color: AppColors.secondary,
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
                color: AppColors.secondary,
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
            const Expanded(child: ProjectGridView()),
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
          onPressed: () => showGroupManagementSheet(context),
          icon: const Icon(
            Icons.hub_rounded,
            size: 14,
            color: AppColors.primary,
          ),
          label: const Text(
            "MIS GRUPOS",
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
