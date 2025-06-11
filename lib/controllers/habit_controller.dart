import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/habit_model.dart';

class HabitController {
  // Stream untuk mendapatkan daftar habit dari Firestore
  Stream<List<Habit>> getHabits() {
    // 1. Dengarkan perubahan status autentikasi
    return FirebaseAuth.instance.authStateChanges().switchMap((User? user) {
      // 2. Gunakan switchMap untuk beralih stream
      if (user == null) {
        // JIKA USER LOGOUT (null), kembalikan stream kosong.
        // Ini secara otomatis menghentikan listener ke Firestore dan mencegah error.
        return Stream.value([]);
      } else {
        // JIKA USER LOGIN, kembalikan stream data habit dari Firestore.
        return FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('habits')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) =>
                snapshot.docs.map((doc) => Habit.fromMap(doc.data())).toList());
      }
    });
  }

  // Fungsi untuk menambahkan habit baru
  Future<void> addHabit({required String name}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Jika karena suatu alasan user tidak ada, jangan lakukan apa-apa.
      return;
    }

    final habitsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits');

    final newHabitRef = habitsCollection.doc();
    final newHabit = Habit(
      id: newHabitRef.id,
      name: name,
      createdAt: Timestamp.now(),
    );
    await newHabitRef.set(newHabit.toMap());
  }

  // Nanti kita akan tambahkan fungsi lain di sini
}
