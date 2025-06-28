import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
// import 'package:cloudinary_url_gen/cloudinary.dart' as url_gen;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:habi_vault/encrypted/env.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Tambahkan Env untuk akses kunci
  static final Env env = Env.create();

  // Inisialisasi Cloudinary
  final Cloudinary cloudinary = Cloudinary.signedConfig(
    apiKey: env.cloudinaryApiKey,
    apiSecret: env.cloudinaryApiSecretKey,
    cloudName: env.cloudinaryCloudName,
  );

  // Ganti total method ini dengan logika Cloudinary
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final response = await cloudinary.unsignedUpload(
        file: imageFile.path,
        uploadPreset: env.cloudinaryUploadPreset,
      );

      if (response.isSuccessful && response.secureUrl != null) {
        if (kDebugMode) {
          debugPrint('Upload Cloudinary berhasil: ${response.secureUrl}');
        }
        return response.secureUrl;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error uploading to Cloudinary: $e');
      return null;
    }
    return null;
  }

  Future<void> _createUserInFirestore(User user, String name,
      {String? photoUrl}) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: name,
        photoUrl: photoUrl ?? '',
      );
      await userDoc.set(newUser.toMap());
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      await cred.user?.reload();

      final freshUser = _auth.currentUser;
      if (freshUser != null && !freshUser.emailVerified) {
        throw AuthException(
            'Email has not been verified. Please check your inbox.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw AuthException('Invalid email or password.');
      }
      throw AuthException('An unknown error occurred.');
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
    File? imageFile,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = cred.user;
      if (user != null) {
        String? photoUrl;
        if (imageFile != null) {
          photoUrl = await uploadProfilePicture(user.uid, imageFile);
        }
        // final newUser = UserModel(
        //     uid: user.uid, name: name, email: email, photoUrl: photoUrl ?? '');
        // await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        await _createUserInFirestore(user, name, photoUrl: photoUrl);
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AuthException('An account already exists for that email.');
      }
      if (e.code == 'network-request-failed') {
        throw AuthException('Network error. Please check your connection.');
      }
      if (e.code == 'invalid-email') {
        throw AuthException('Invalid email format.');
      }
      debugPrint('Error during registration: $e');
      throw AuthException('Registration failed. Please try again. {$e}');
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final UserCredential userCredential =
          await _auth.signInWithProvider(googleProvider);
      final user = userCredential.user;
      if (user != null) {
        await _createUserInFirestore(user, user.displayName ?? 'Google User',
            photoUrl: user.photoURL);
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('Error during Google login: $e');
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException("Tidak ada pengguna yang masuk.");

    // Buat kredensial dengan email dan password lama
    final cred = EmailAuthProvider.credential(
        email: user.email!, password: currentPassword);

    try {
      // Lakukan re-autentikasi pengguna
      await user.reauthenticateWithCredential(cred);

      // Jika berhasil, perbarui password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw AuthException("Password lama yang Anda masukkan salah.");
      }
      throw AuthException("Terjadi kesalahan: ${e.message}");
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      // TIDAK ADA NAVIGASI DI SINI. AuthProvider akan mendeteksi perubahan ini.
    } catch (e) {
      if (kDebugMode) debugPrint('Error during logout: $e');
      throw AuthException('Failed to log out.');
    }
  }
}
