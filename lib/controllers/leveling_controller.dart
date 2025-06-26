import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habi_vault/models/user_model.dart';

class LevelingController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // Method untuk menambahkan XP
  Future<void> addXp(int xpGained) async {
    if (_user == null) return;

    final userRef = _firestore.collection('users').doc(_user.uid);

    // Transaksi firestore untuk memastikan operasi data aman dan konsisten
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw Exception("User does not exist!");
      }

      var userModel = UserModel.fromMap(snapshot.data()!);

      // Tambahkan XP
      int newXp = userModel.xp + xpGained;
      int newLevel = userModel.level;
      int newXpToNextLevel = userModel.xpToNextLevel;
      String newTitle = userModel.title;

      // Cek apakah user naik level, bisa terjadi berkali-kali dalam satu aksi
      while (newXp >= newXpToNextLevel) {
        newLevel++; // Naikkan level
        newXp -= newXpToNextLevel; // Reset XP dengan sisa XP
        newXpToNextLevel *= 2; // Gandakan kebutuhan XP untuk level berikutnya

        // Tentukan gelar baru berdasarkan level
        newTitle = _getNewTitleForLevel(newLevel);

        // TODO: Picu event untuk menampilkan animasi/reward level up di UI
      }

      // Update data di Firestore
      transaction.update(userRef, {
        'level': newLevel,
        'xp': newXp,
        'xpToNextLevel': newXpToNextLevel,
        'title': newTitle,
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
