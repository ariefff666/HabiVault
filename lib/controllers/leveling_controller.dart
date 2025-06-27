import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habi_vault/models/user_model.dart';
import 'package:habi_vault/models/skill_model.dart';

// --- EVENT BUS SEDERHANA UNTUK NOTIFIKASI LEVEL UP ---
class LevelUpEvent {
  final bool isUserLevelUp;
  final String? newTitle;
  final int? newLevel;
  final SkillModel? skill;

  LevelUpEvent(
      {required this.isUserLevelUp, this.newTitle, this.newLevel, this.skill});
}

// StreamController untuk menyiarkan event
final StreamController<LevelUpEvent> levelUpBus = StreamController.broadcast();

class LevelingController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // Aturan XP untuk skill level up
  final Map<SkillLevel, int> _skillXpThresholds = {
    SkillLevel.beginner: 1500,
    SkillLevel.amateur: 5000,
    SkillLevel.expert: 12500,
    SkillLevel.professional: 999999, // Level maksimal
  };

  // Method untuk menambahkan XP
  Future<void> addXp(int xpGained, String skillId) async {
    if (_user == null) return;

    final userRef = _firestore.collection('users').doc(_user.uid);
    final skillRef = userRef.collection('skills').doc(skillId);

    // Gunakan transaksi untuk memastikan semua operasi data aman
    return _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final skillSnapshot = await transaction.get(skillRef);

      if (!userSnapshot.exists || !skillSnapshot.exists) {
        throw Exception("User or Skill does not exist!");
      }

      // --- 1. Update XP & Level Pengguna ---
      var userModel = UserModel.fromMap(userSnapshot.data()!);
      int newXp = userModel.xp + xpGained;
      int newLevel = userModel.level;
      int newXpToNextLevel = userModel.xpToNextLevel;
      String newTitle = userModel.title;

      while (newXp >= newXpToNextLevel) {
        newLevel++;
        newXp -= newXpToNextLevel;
        newXpToNextLevel = (newXpToNextLevel * 1.5).round();
        newTitle = _getNewTitleForLevel(newLevel);

        levelUpBus.add(LevelUpEvent(
            isUserLevelUp: true, newLevel: newLevel, newTitle: newTitle));
      }

      transaction.update(userRef, {
        'level': newLevel,
        'xp': newXp,
        'xpToNextLevel': newXpToNextLevel,
        'title': newTitle,
      });

      // --- 2. Update XP & Level Skill ---
      var skillModel = SkillModel.fromMap(skillSnapshot.data()!);
      int newSkillXp = skillModel.currentXp + xpGained;
      SkillLevel newSkillLevel = skillModel.level;

      // Cek apakah skill naik level
      int requiredXp = _skillXpThresholds[newSkillLevel] ?? 999999;
      if (newSkillXp >= requiredXp &&
          newSkillLevel != SkillLevel.professional) {
        // Pindah ke level berikutnya
        newSkillLevel = SkillLevel.values[newSkillLevel.index + 1];

        // SIARKAN EVENT SKILL LEVEL UP!
        final updatedSkill = skillModel..level = newSkillLevel;
        levelUpBus.add(LevelUpEvent(isUserLevelUp: false, skill: updatedSkill));
      }

      transaction.update(
          skillRef, {'currentXp': newSkillXp, 'level': newSkillLevel.index});

      // --- 3. Buat Log Perolehan XP ---
      final xpLogRef = skillRef.collection('xp_log').doc();
      transaction.set(xpLogRef, {
        'xpGained': xpGained,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  // Helper untuk menentukan gelar baru
  String _getNewTitleForLevel(int level) {
    if (level >= 25) return 'Master of Habits';
    if (level >= 10) return 'Adept Explorer';
    if (level >= 5) return 'Apprentice';
    return 'Novice';
  }
}
