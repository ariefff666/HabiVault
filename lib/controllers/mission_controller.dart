import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:habi_vault/controllers/mission_events.dart';
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

  Stream<List<MissionModel>> getAllMissions() {
    if (_user == null) return Stream.value([]);
    return _missionsCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<Map<String, List<MissionModel>>> getGroupedMissions() {
    if (_user == null) return Stream.value({});

    // Cukup ambil semua misi dan kita akan kelompokkan di sisi klien
    return _missionsCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final missions = snapshot.docs.map((doc) => doc.data()).toList();

      // Buat map kosong untuk hasil pengelompokan
      final Map<String, List<MissionModel>> groupedMissions = {};

      // Iterasi setiap misi dan masukkan ke dalam map berdasarkan skillId
      for (var mission in missions) {
        if (groupedMissions[mission.skillId] == null) {
          groupedMissions[mission.skillId] = [];
        }
        groupedMissions[mission.skillId]!.add(mission);
      }

      return groupedMissions;
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
    debugPrint('New mission added to Firestore!');
  }

  // Fungsi untuk Menghapus misi
  Future<void> deleteMission(String missionId) async {
    if (_user == null) return;
    await _missionsCollection!.doc(missionId).delete();
  }

  // Fungsi untuk Mengedit misi (terbatas)
  Future<void> updateMissionDetails({
    required String missionId,
    required int xp,
    required List<int> scheduleDays,
    required TimeOfDay startTime,
    Duration? duration,
    String? notes,
  }) async {
    if (_user == null) return;
    await _missionsCollection!.doc(missionId).update({
      'xp': xp,
      'scheduleDays': scheduleDays,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'durationInMinutes': duration?.inMinutes,
      'notes': notes,
      // Reset status reschedule jika jadwal diubah
      'isRescheduled': false,
      'originalScheduledDate': null,
    });
  }

  // Fungsi untuk Menjadwalkan ulang misi
  Future<void> rescheduleMission(
      MissionModel missionToReschedule, DateTime newDateTime) async {
    if (_user == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // 1. Buat misi baru yang sudah di-reschedule
    final newMissionRef = _missionsCollection!.doc();
    final rescheduledMission = MissionModel(
      id: newMissionRef.id,
      title: missionToReschedule.title,
      skillId: missionToReschedule.skillId,
      xp: missionToReschedule.xp,
      // Jadwal hanya untuk hari yang baru, di-set ke timestamp agar unik
      scheduleDays: [newDateTime.weekday],
      startTime: TimeOfDay.fromDateTime(newDateTime),
      duration: missionToReschedule.duration,
      notes: "Rescheduled from original. ${missionToReschedule.notes ?? ''}"
          .trim(),
      // Gunakan timestamp dari newDateTime untuk memastikannya unik dan terjadwal dengan benar
      createdAt: Timestamp.fromDate(newDateTime),
      isRescheduled: true,
      originalScheduledDate: missionToReschedule.createdAt,
    );
    batch.set(newMissionRef, rescheduledMission.toMap());

    // 2. Hapus jadwal hari ini dari misi asli.
    final todayWeekday = DateTime.now().weekday;
    List<int> originalSchedule = List.from(missionToReschedule.scheduleDays);

    // Hanya hapus jika tidak di-reschedule, untuk mencegah penghapusan ganda
    if (!missionToReschedule.isRescheduled) {
      originalSchedule.remove(todayWeekday);
    }

    // Jika jadwal asli masih ada, update. Jika tidak, hapus misi asli.
    if (originalSchedule.isNotEmpty && !missionToReschedule.isRescheduled) {
      batch.update(_missionsCollection!.doc(missionToReschedule.id),
          {'scheduleDays': originalSchedule});
    } else {
      // Hapus misi asli jika tidak ada jadwal tersisa atau jika itu adalah misi hasil reschedule
      batch.delete(_missionsCollection!.doc(missionToReschedule.id));
    }

    await batch.commit();
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

    // --- SIARKAN EVENT ---
    missionCompletionBus.add(MissionCompletedEvent(
      missionId: mission.id,
      xpGained: mission.xp,
      skillId: mission.skillId,
    ));

    // Lanjutkan dengan menyimpan ke database seperti biasa
    final missionRef = _missionsCollection!.doc(mission.id);
    final completionLogRef = missionRef.collection('completion_log').doc();
    final now = Timestamp.now();

    // Gunakan batch write untuk operasi atomik
    final batch = FirebaseFirestore.instance.batch();

    // 1. Perbarui timestamp terakhir di dokumen utama (untuk akses cepat)
    batch.update(missionRef, {'lastCompleted': now});

    // 2. Tambahkan entri baru ke dalam sub-koleksi log
    batch.set(completionLogRef, {
      'completedAt': now,
      'xpGained': mission.xp, // Simpan juga XP untuk referensi di masa depan
    });

    await batch.commit();

    // Berikan XP ke LevelingController
    await _levelingController.addXp(mission.xp, mission.skillId);

    debugPrint(
        'Mission ${mission.title} completed! Logged and user gained ${mission.xp} XP.');
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

  Stream<QuerySnapshot> getCompletionLogStream(String missionId) {
    if (_user == null) return Stream.empty();
    return _missionsCollection!
        .doc(missionId)
        .collection('completion_log')
        .orderBy('completedAt', descending: true)
        .snapshots();
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

  // Menggabungkan semua misi dan skill
  Stream<List<EnrichedMissionModel>> getEnrichedMissionsStream() {
    if (_user == null) return Stream.value([]);

    final missionsStream = _missionsCollection!
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

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

    return Rx.combineLatest2(missionsStream, skillsStream,
        (List<MissionModel> missions, Map<String, SkillModel> skillsMap) {
      return missions.map((mission) {
        return EnrichedMissionModel(
          mission: mission,
          skill: skillsMap[mission.skillId] ?? SkillModel.empty(),
        );
      }).toList();
    });
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
      // Menggabungkan misi dengan skill
      var enrichedMissions = missions.map((mission) {
        return EnrichedMissionModel(
          mission: mission,
          skill: skillsMap[mission.skillId],
        );
      }).toList();

      // --- PENYESUAIAN DI SINI: Urutkan berdasarkan waktu mulai ---
      enrichedMissions.sort((a, b) {
        final timeA = a.mission.startTime;
        final timeB = b.mission.startTime;
        final aMinutes = timeA.hour * 60 + timeA.minute;
        final bMinutes = timeB.hour * 60 + timeB.minute;
        return aMinutes.compareTo(bMinutes);
      });

      return enrichedMissions;
    });
  }
}
