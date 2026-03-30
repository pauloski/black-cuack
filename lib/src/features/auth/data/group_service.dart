import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blackcuack_studio/src/core/utils/group_utils.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. CREAR UN GRUPO (Se mantiene igual)
  Future<String?> createGroup(String groupName) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final String groupCode = GroupUtils.generateGroupCode();

    try {
      await _db.collection('groups').add({
        'name': groupName,
        'code': groupCode,
        'ownerId': user.uid,
        'members': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return groupCode;
    } catch (e) {
      print("Error al crear grupo: $e");
      return null;
    }
  }

  // 2. UNIRSE A UN GRUPO (Se mantiene igual)
  Future<bool> joinGroup(String code) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final query = await _db
          .collection('groups')
          .where('code', isEqualTo: code.toUpperCase())
          .get();

      if (query.docs.isEmpty) return false;

      final groupDoc = query.docs.first;
      await groupDoc.reference.update({
        'members': FieldValue.arrayUnion([user.uid]),
      });

      return true;
    } catch (e) {
      print("Error al unirse al grupo: $e");
      return false;
    }
  }

  // 📡 3. OBTENER MIS GRUPOS (Se mantiene igual)
  Stream<QuerySnapshot> getMyGroupsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .snapshots();
  }

  // 📝 4. RENOMBRAR GRUPO
  Future<void> updateGroupName(String groupId, String newName) async {
    try {
      await _db.collection('groups').doc(groupId).update({'name': newName});
    } catch (e) {
      print("Error al renombrar: $e");
    }
  }

  // 🗑️ 5. ELIMINAR GRUPO (Solo dueño)
  Future<void> deleteGroup(String groupId) async {
    try {
      await _db.collection('groups').doc(groupId).delete();
    } catch (e) {
      print("Error al borrar grupo: $e");
    }
  }

  // 🚪 6. SALIR DEL GRUPO (Desvincularse)
  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([user.uid]),
      });
    } catch (e) {
      print("Error al salir del grupo: $e");
    }
  }
}
