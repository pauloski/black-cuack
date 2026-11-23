import 'package:flutter/material.dart';

import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/profile/data/profile_service.dart';
import 'package:blackcuack_studio/src/features/profile/domain/profile_model.dart';

const _roles = ['Animador', 'Cámara', 'Director', 'Otro'];
const _avatars = ['🦆', '🐱', '🐶', '🦊', '🐸', '🐼', '🐯', '🦉'];

/// Crea un perfil ligero de compañero (avatar + apodo + rol) y lo guarda.
/// Sin clave de imágenes: la crea al entrar por primera vez. Devuelve el perfil
/// o null si se cancela.
Future<Profile?> showAddTeammateDialog(BuildContext context) async {
  final nameCtrl = TextEditingController();
  final otherCtrl = TextEditingController();
  String avatar = _avatars.first;
  String role = '';
  return showDialog<Profile>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('NUEVO COMPAÑERO',
            style: TextStyle(
                fontFamily: 'Lexend', color: AppColors.primary, fontSize: 15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Apodo',
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Avatar',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _avatars
                    .map((a) => GestureDetector(
                          onTap: () => setD(() => avatar = a),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                avatar == a ? AppColors.primary : Colors.white10,
                            child:
                                Text(a, style: const TextStyle(fontSize: 20)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              const Text('Rol',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _roles.map((r) {
                  final sel = role == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: sel,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                        color: sel ? Colors.black : Colors.white70,
                        fontFamily: 'Lexend',
                        fontSize: 12),
                    backgroundColor: Colors.white10,
                    selectedColor: AppColors.primary,
                    onSelected: (_) => setD(() => role = sel ? '' : r),
                  );
                }).toList(),
              ),
              if (role == 'Otro') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: otherCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '¿Cuál rol?',
                    hintStyle: const TextStyle(color: Colors.white24),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final finalRole = role == 'Otro' ? otherCtrl.text.trim() : role;
              final p = Profile(
                id: 'p_${DateTime.now().microsecondsSinceEpoch}',
                nickname: name,
                avatar: avatar,
                imageKey: const [],
                role: finalRole,
              );
              await ProfileService.save(p);
              if (ctx.mounted) Navigator.pop(ctx, p);
            },
            child: const Text('AGREGAR', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    ),
  );
}

/// Hoja para elegir los miembros del equipo (perfiles del dispositivo) y crear
/// compañeros nuevos. [owner] siempre queda incluido y no se puede desmarcar.
/// Devuelve el set de ids elegidos, o null si se cancela.
Future<Set<String>?> showTeamSheet(
  BuildContext context, {
  required Set<String> initial,
  required String owner,
  String title = '¿QUIÉNES SON EL EQUIPO?',
}) async {
  var profiles = await ProfileService.list();
  if (!context.mounted) return null;
  final selected = <String>{...initial, if (owner.isNotEmpty) owner};
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Lexend',
                      fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Toca a quienes trabajarán en este proyecto.',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...profiles.map((p) {
                    final sel = selected.contains(p.id);
                    final isOwner = p.id == owner;
                    return FilterChip(
                      label: Text(
                          '${p.avatar} ${p.nickname}${p.role.isEmpty ? '' : ' · ${p.role}'}'),
                      selected: sel,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                          color: sel ? Colors.black : Colors.white70,
                          fontFamily: 'Lexend',
                          fontSize: 12),
                      backgroundColor: Colors.white10,
                      selectedColor: AppColors.primary,
                      onSelected: isOwner
                          ? null
                          : (v) => setSheet(() =>
                              v ? selected.add(p.id) : selected.remove(p.id)),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.person_add_alt_1_rounded,
                        size: 16, color: AppColors.secondary),
                    label: const Text('Nuevo compañero',
                        style: TextStyle(
                            color: AppColors.secondary,
                            fontFamily: 'Lexend',
                            fontSize: 12)),
                    backgroundColor: Colors.white10,
                    onPressed: () async {
                      final p = await showAddTeammateDialog(ctx);
                      if (p != null) {
                        profiles = await ProfileService.list();
                        setSheet(() => selected.add(p.id));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('LISTO',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result == true ? selected : null;
}
