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

  // Method untuk menambahkan XP
  Future<void> addXp(int xpGained, String skillId) async {
    if (_user == null) return;

    final userRef = _firestore.collection('users').doc(_user.uid);
    final skillRef = userRef.collection('skills').doc(skillId);

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
      var currentSkillXp = skillModel.currentXp + xpGained;
      var currentSkillLevel = skillModel.level;
      var xpForNext = skillModel.xpForNextLevel;
      bool hasLeveledUp = false;

      // Loop untuk menangani multi-level up dalam satu kali penambahan XP
      while (currentSkillXp >= xpForNext) {
        hasLeveledUp = true;
        // Kurangi XP yang sudah dipakai untuk naik level
        currentSkillXp -= xpForNext;
        // Naikkan level
        currentSkillLevel++;

        // Tentukan XP yang dibutuhkan untuk level berikutnya berdasarkan tier BARU
        if (currentSkillLevel >= 30) {
          xpForNext = 2500;
        } else if (currentSkillLevel >= 20) {
          xpForNext = 1200;
        } else if (currentSkillLevel >= 10) {
          xpForNext = 500;
        } else {
          xpForNext = 150;
        }
      }

      if (hasLeveledUp) {
        final updatedSkillForEvent = SkillModel(
          id: skillModel.id,
          name: skillModel.name,
          icon: skillModel.icon,
          color: skillModel.color,
          level: currentSkillLevel,
          currentXp: currentSkillXp,
          xpForNextLevel: xpForNext,
          createdAt: skillModel.createdAt,
        );
        // Siarkan event level up skill
        levelUpBus.add(
            LevelUpEvent(isUserLevelUp: false, skill: updatedSkillForEvent));
      }

      transaction.update(skillRef, {
        'level': currentSkillLevel,
        'currentXp': currentSkillXp,
        'xpForNextLevel': xpForNext,
      });

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
