import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habi_vault/models/mission_model.dart';
// import 'package:rxdart/rxdart.dart';
import 'leveling_controller.dart';

class MissionController {
  final User? _user = FirebaseAuth.instance.currentUser;
  final LevelingController _levelingController = LevelingController();

  // Referensi ke koleksi misi pengguna
  CollectionReference<MissionModel>? get _missionsCollection {
    if (_user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('missions')
        .withConverter<MissionModel>(
          fromFirestore: (snapshots, _) =>
              MissionModel.fromMap(snapshots.data()!),
          toFirestore: (mission, _) => mission.toMap(),
        );
  }

  // Stream untuk mendapatkan misi yang relevan untuk hari ini
  Stream<List<MissionModel>> getTodaysMissions() {
    if (_missionsCollection == null) return Stream.value([]);

    // Dapatkan hari ini (1=Senin, ..., 7=Minggu)
    final today = DateTime.now().weekday;

    return _missionsCollection!
        .where('scheduleDays', arrayContains: today)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Fungsi untuk menandai misi sebagai selesai
  Future<void> completeMission(MissionModel mission) async {
    if (_user == null) return;

    final missionRef = _missionsCollection!.doc(mission.id);

    // Tandai misi sebagai selesai untuk hari ini
    await missionRef.update({'lastCompleted': Timestamp.now()});

    // Tambahkan XP ke pengguna menggunakan LevelingController
    await _levelingController.addXp(mission.xp);

    // Tambahkan juga XP ke skill yang relevan
    print('Mission ${mission.title} completed! User gained ${mission.xp} XP.');
  }
}
