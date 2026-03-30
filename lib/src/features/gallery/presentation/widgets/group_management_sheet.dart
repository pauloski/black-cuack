import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/auth/data/group_service.dart';

// ✅ ESTA ES LA FUNCIÓN QUE HOME_PAGE NECESITA
void showGroupManagementSheet(BuildContext context) {
  final TextEditingController groupController = TextEditingController();
  final GroupService _groupService = GroupService();

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
          const Text(
            "Gestiona tus grupos para compartir tus Quacks",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontFamily: 'Lexend',
            ),
          ),
          const SizedBox(height: 25),

          // --- SECCIÓN: UNIRSE ---
          _buildActionCard(
            title: "UNIRSE A UN GRUPO",
            color: const Color(0xFFBC87FE),
            child: TextField(
              controller: groupController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 5,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                hintText: "CÓDIGO EJ: BQC2X",
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
                  onPressed: () async {
                    if (groupController.text.length == 5) {
                      bool success = await _groupService.joinGroup(
                        groupController.text,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: success
                                ? const Color(0xFFBC87FE)
                                : Colors.redAccent,
                            content: Text(
                              success
                                  ? "¡Te has unido al grupo! 🦆"
                                  : "Código no encontrado ⚠️",
                            ),
                          ),
                        );
                        if (success) Navigator.pop(context);
                      }
                    }
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- SECCIÓN: CREAR ---
          _buildActionCard(
            title: "CREAR NUEVO GRUPO",
            color: const Color(0xFFC1FFFE),
            child: QuackButton(
              text: "GENERAR CÓDIGO",
              onPressed: () async {
                String? name = await _showNameDialog(context);
                if (name != null && name.isNotEmpty) {
                  String? code = await _groupService.createGroup(name);
                  if (context.mounted && code != null) {
                    Navigator.pop(context);
                    _showSuccessDialog(context, code);
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 20),

          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/my_groups');
            },
            child: const Text(
              "VER MIS GRUPOS 🦆",
              style: TextStyle(
                color: Colors.white24,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// --- FUNCIONES DE APOYO INTERNAS ---

Future<String?> _showNameDialog(BuildContext context) async {
  String tempName = "";
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        "NOMBRE DEL GRUPO",
        style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFC1FFFE)),
      ),
      content: TextField(
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "Ej: Taller de Lunes",
          hintStyle: TextStyle(color: Colors.white24),
        ),
        onChanged: (v) => tempName = v,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCELAR"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, tempName),
          child: const Text(
            "CREAR",
            style: TextStyle(color: Color(0xFFC1FFFE)),
          ),
        ),
      ],
    ),
  );
}

void _showSuccessDialog(BuildContext context, String code) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFC1FFFE)),
      ),
      title: const Text(
        "¡GRUPO LISTO!",
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFC1FFFE)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Dicta este código a tus amigos:",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Text(
            code,
            style: const TextStyle(
              fontSize: 40,
              fontFamily: 'LuckiestGuy',
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: QuackButton(
            text: "ENTENDIDO",
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ),
  );
}

Widget _buildActionCard({
  required String title,
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
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}
