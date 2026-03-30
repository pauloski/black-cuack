import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blackcuack_studio/src/features/auth/data/group_service.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/group_details_page.dart';

class MyGroupsPage extends StatefulWidget {
  const MyGroupsPage({super.key});

  @override
  State<MyGroupsPage> createState() => _MyGroupsPageState();
}

class _MyGroupsPageState extends State<MyGroupsPage> {
  final GroupService _groupService = GroupService();
  final String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MIS GRUPOS',
          style: TextStyle(
            fontFamily: 'LuckiestGuy',
            color: Color(0xFFC1FFFE),
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _groupService.getMyGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC1FFFE)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final allGroups = snapshot.data!.docs;
          final ownedGroups = allGroups
              .where((doc) => doc['ownerId'] == currentUserUid)
              .toList();
          final joinedGroups = allGroups
              .where((doc) => doc['ownerId'] != currentUserUid)
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            children: [
              const SizedBox(height: 10),
              if (ownedGroups.isNotEmpty) ...[
                _buildSectionHeader("CREADOS POR MÍ", const Color(0xFFC1FFFE)),
                ...ownedGroups
                    .map((doc) => _buildGroupCard(doc, true))
                    .toList(),
                const SizedBox(height: 20),
              ],
              if (joinedGroups.isNotEmpty) ...[
                _buildSectionHeader(
                  "A LOS QUE ME UNÍ",
                  const Color(0xFFBC87FE),
                ),
                ...joinedGroups
                    .map((doc) => _buildGroupCard(doc, false))
                    .toList(),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(DocumentSnapshot doc, bool isOwner) {
    final data = doc.data() as Map<String, dynamic>;
    final String groupId = doc.id; // ✅ ID largo de Firebase
    final String groupName = data['name'] ?? 'Sin nombre';
    final Color powerColor = isOwner
        ? const Color(0xFFC1FFFE)
        : const Color(0xFFBC87FE);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: powerColor.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsPage(
                groupName: groupName,
                groupCode: data['code'] ?? '',
              ),
            ),
          );
        },
        leading: Icon(
          isOwner ? Icons.workspace_premium_rounded : Icons.hub_rounded,
          color: powerColor,
          size: 28,
        ),
        title: Text(
          groupName.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'LuckiestGuy',
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          "CÓDIGO: ${data['code']}",
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        trailing: isOwner
            ? _buildOwnerActions(groupId, groupName)
            : _buildMemberActions(groupId, groupName),
      ),
    );
  }

  Widget _buildOwnerActions(String groupId, String name) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white24, size: 18),
          onPressed: () => _showEditDialog(groupId, name),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_forever_rounded,
            color: Color(0xFFFF4D4D),
            size: 18,
          ),
          onPressed: () => _confirmDeleteGroup(groupId, name),
        ),
      ],
    );
  }

  Widget _buildMemberActions(String groupId, String name) {
    return IconButton(
      icon: const Icon(
        Icons.door_front_door_rounded,
        color: Color(0xFFFFB34D),
        size: 18,
      ),
      onPressed: () => _confirmLeaveGroup(groupId, name),
    );
  }

  // --- DIÁLOGOS DE ACCIÓN ---

  void _showEditDialog(String groupId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "RENOMBRAR GRUPO",
          style: TextStyle(
            fontFamily: 'LuckiestGuy',
            color: Color(0xFFC1FFFE),
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'Lexend'),
          decoration: InputDecoration(
            labelText: "Nuevo nombre",
            labelStyle: const TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white10),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC1FFFE)),
            ),
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
              backgroundColor: const Color(0xFFC1FFFE),
            ),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _groupService.updateGroupName(groupId, controller.text);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text(
              "GUARDAR",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(String groupId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "¿ELIMINAR GRUPO?",
          style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFFF4D4D)),
        ),
        content: Text(
          "Esta acción borrará el grupo '$name'. Los alumnos ya no podrán acceder.",
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Lexend',
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              await _groupService.deleteGroup(groupId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              "BORRAR",
              style: TextStyle(color: Color(0xFFFF4D4D)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup(String groupId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "¿SALIR DEL GRUPO?",
          style: TextStyle(fontFamily: 'LuckiestGuy', color: Color(0xFFFFB34D)),
        ),
        content: Text(
          "¿Quieres desvincularte de '$name'? Ya no verás sus proyectos.",
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Lexend',
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              await _groupService.leaveGroup(groupId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              "SALIR",
              style: TextStyle(color: Color(0xFFFFB34D)),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE CABECERA ---

  Widget _buildSectionHeader(String title, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'LuckiestGuy',
            fontSize: 16,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        Container(
          width: 50,
          height: 3,
          margin: const EdgeInsets.only(top: 5, bottom: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_rounded, size: 80, color: Colors.white10),
          SizedBox(height: 20),
          Text(
            "Tu charca está tranquila...\nAun no te has unido ni creado ningún grupo.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontFamily: 'Lexend',
            ),
          ),
        ],
      ),
    );
  }
}
