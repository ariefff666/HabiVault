import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habi_vault/models/skill_model.dart'; // Pastikan path ini benar
import 'package:rxdart/rxdart.dart';

class SkillController {
  // Mengambil daftar skill milik pengguna
  Stream<List<SkillModel>> getSkills() {
    return FirebaseAuth.instance.authStateChanges().switchMap((user) {
      if (user == null) {
        return Stream.value([]);
      } else {
        return FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('skills')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => SkillModel.fromMap(doc.data()))
                .toList());
      }
    });
  }

  // Fungsi untuk menambah skill baru
  Future<void> addSkill({
    required String name,
    required String icon,
    required int color,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final skillsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('skills');

    final newSkillRef = skillsCollection.doc();
    final newSkill = SkillModel(
      id: newSkillRef.id,
      name: name,
      icon: icon,
      color: color,
    );

    await newSkillRef.set(newSkill.toMap());
  }
}
