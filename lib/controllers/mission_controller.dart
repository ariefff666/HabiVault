import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:habi_vault/models/enriched_mission_model.dart';
import 'package:habi_vault/models/mission_model.dart';
import 'package:habi_vault/models/skill_model.dart';
import 'package:rxdart/rxdart.dart';
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

  // Fungsi untuk menambahkan misi baru
  Future<void> addMission({
    required String title,
    required String skillId,
    required int xp,
    required List<int> scheduleDays,
    required TimeOfDay startTime,
    Duration? duration,
    String? notes,
  }) async {
    if (_user == null) return;

    final newMissionRef = _missionsCollection!.doc();
    final newMission = MissionModel(
      id: newMissionRef.id,
      title: title,
      skillId: skillId,
      xp: xp,
      scheduleDays: scheduleDays,
      startTime: startTime,
      duration: duration,
      notes: notes,
      createdAt: Timestamp.now(),
    );

    await newMissionRef.set(newMission);
    print('New mission added to Firestore!');
  }

  Stream<List<MissionModel>> getMissionsForSkill(String skillId) {
    if (_user == null) return Stream.value([]);

    // Query ke Firestore untuk misi yang memiliki skillId yang cocok
    return _missionsCollection!
        .where('skillId', isEqualTo: skillId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Fungsi untuk menandai misi sebagai selesai
  Future<void> completeMission(MissionModel mission) async {
    if (_user == null) return;

    final missionRef = _missionsCollection!.doc(mission.id);
    await missionRef.update({'lastCompleted': Timestamp.now()});

    // Berikan XP dan skillId ke LevelingController
    await _levelingController.addXp(mission.xp, mission.skillId);

    print(
        'Mission ${mission.title} completed! User gained ${mission.xp} XP for skill ${mission.skillId}.');
  }

  // --- Menghitung jumlah misi yang selesai untuk satu skill ---
  Stream<int> countCompletedMissions(String skillId) {
    if (_user == null) return Stream.value(0);

    // Query misi untuk skillId spesifik yang sudah pernah diselesaikan
    return _missionsCollection!
        .where('skillId', isEqualTo: skillId)
        .where('lastCompleted', isNotEqualTo: null)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // --- Menghitung streak harian ---
  Future<int> calculateSkillStreak(String skillId) async {
    if (_user == null) return 0;

    // Ambil semua misi yang selesai untuk skill ini, diurutkan dari terbaru
    final snapshot = await _missionsCollection!
        .where('skillId', isEqualTo: skillId)
        .where('lastCompleted', isNotEqualTo: null)
        .orderBy('lastCompleted', descending: true)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    // Gunakan Set untuk menyimpan tanggal unik tanpa jam/menit/detik
    final Set<DateTime> completionDates = {};
    for (var doc in snapshot.docs) {
      final mission = doc.data();
      final timestamp = mission.lastCompleted!.toDate();
      completionDates
          .add(DateTime(timestamp.year, timestamp.month, timestamp.day));
    }

    int currentStreak = 0;
    final today = DateTime.now();
    var checkDate = DateTime(today.year, today.month, today.day);

    // Cek apakah hari ini menyelesaikan misi
    if (completionDates.contains(checkDate)) {
      currentStreak++;
      // Lanjutkan cek ke hari-hari sebelumnya
      for (int i = 1; i < completionDates.length + 1; i++) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        if (completionDates.contains(checkDate)) {
          currentStreak++;
        } else {
          // Jika ada hari yang bolong, streak berhenti
          break;
        }
      }
    }

    return currentStreak;
  }

  // --- getEnrichedTodaysMissions ---
  Stream<List<EnrichedMissionModel>> getEnrichedTodaysMissions() {
    if (_user == null) return Stream.value([]);

    // Stream 1: Misi untuk hari ini
    final today = DateTime.now().weekday;
    final missionsStream = _missionsCollection!
        .where('scheduleDays', arrayContains: today)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

    // Stream 2: Semua skill pengguna (sebagai map untuk pencarian cepat)
    final skillsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('skills')
        .snapshots()
        .map((snapshot) {
      final Map<String, SkillModel> skillsMap = {};
      for (var doc in snapshot.docs) {
        final skill = SkillModel.fromMap(doc.data());
        skillsMap[skill.id] = skill;
      }
      return skillsMap;
    });

    // Gabungkan kedua stream
    return Rx.combineLatest2(missionsStream, skillsStream,
        (List<MissionModel> missions, Map<String, SkillModel> skillsMap) {
      // Untuk setiap misi, cari skill yang cocok di dalam map
      return missions.map((mission) {
        return EnrichedMissionModel(
          mission: mission,
          skill: skillsMap[mission.skillId], // Ambil skill dari map
        );
      }).toList();
    });
  }
}
