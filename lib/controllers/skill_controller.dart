import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habi_vault/models/skill_model.dart';
import 'package:rxdart/rxdart.dart';

class SkillController {
  final User? _user = FirebaseAuth.instance.currentUser;

  // Referensi ke koleksi skills dengan converter
  CollectionReference<SkillModel>? get _skillsCollection {
    if (_user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('skills')
        .withConverter<SkillModel>(
          fromFirestore: (snapshots, _) =>
              SkillModel.fromMap(snapshots.data()!),
          toFirestore: (skill, _) => skill.toMap(),
        );
  }

  // Stream untuk mendapatkan semua skill pengguna
  Stream<List<SkillModel>> getSkills({
    String orderByField = 'createdAt',
    bool descending = true,
  }) {
    return FirebaseAuth.instance.authStateChanges().switchMap((user) {
      if (user == null) {
        return Stream.value([]);
      } else {
        return FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('skills')
            .orderBy(orderByField, descending: descending)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => SkillModel.fromMap(doc.data()))
                .toList());
      }
    });
  }

  // Fungsi untuk menambahkan skill baru
  Future<void> addSkill({
    required String name,
    required String icon,
    required int color,
  }) async {
    final collection = _skillsCollection;
    if (collection == null) return;

    final newSkillRef = collection.doc();

    final newSkill = SkillModel(
      id: newSkillRef.id,
      name: name,
      icon: icon,
      color: color,
      level: SkillLevel.beginner,
      currentXp: 0,
      xpForNextLevel: 100,
      createdAt: Timestamp.now(),
    );

    await newSkillRef.set(newSkill);
    print('New skill "$name" added to Firestore with timestamp!');
  }

  Future<void> updateSkill(SkillModel skill) async {
    final collection = _skillsCollection;
    if (collection == null) return;
    await collection.doc(skill.id).update(skill.toMap());
  }

  // --- DELETE SKILL ---
  Future<void> deleteSkill(String skillId) async {
    final collection = _skillsCollection;
    if (collection == null) return;
    await collection.doc(skillId).delete();

    // TODO: Hapus juga semua misi yang terhubung dengan skillId ini
  }

  Stream<SkillModel?> getSkillById(String skillId) {
    if (_user == null) return Stream.value(null);
    return _skillsCollection!.doc(skillId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  Stream<List<Map<String, dynamic>>> getXpLogForSkill(String skillId,
      {int days = 7}) {
    if (_user == null) return Stream.value([]);

    // Tentukan batas waktu (misal: 7 hari yang lalu)
    final timeLimit = DateTime.now().subtract(Duration(days: days));

    return _skillsCollection!
        .doc(skillId)
        .collection('xp_log')
        .where('timestamp', isGreaterThanOrEqualTo: timeLimit)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
