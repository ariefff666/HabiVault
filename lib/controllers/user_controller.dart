import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habi_vault/controllers/auth_controller.dart';
import 'package:habi_vault/models/user_model.dart';

class UserController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  final AuthController _authController = AuthController();

  Stream<UserModel?> getUserData() {
    if (_user == null) {
      return Stream.value(null);
    }
    return _firestore.collection('users').doc(_user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  Future<void> updateUserProfile({
    required String newName,
    File? newImageFile,
  }) async {
    if (_user == null) throw Exception("Pengguna tidak ditemukan");

    try {
      String? newPhotoUrl;
      // Jika ada file gambar baru, unggah menggunakan fungsi dari AuthController
      if (newImageFile != null) {
        // Ini adalah fungsi yang mengunggah ke Cloudinary, bukan Firebase Storage
        newPhotoUrl =
            await _authController.uploadProfilePicture(_user.uid, newImageFile);
      }

      final Map<String, dynamic> updatedData = {
        'name': newName,
      };

      if (newPhotoUrl != null) {
        updatedData['photoUrl'] = newPhotoUrl;
      }

      await _firestore.collection('users').doc(_user.uid).update(updatedData);
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }
}
