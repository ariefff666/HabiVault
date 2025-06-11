import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  late final StreamSubscription<User?> _authSubscription;

  User? get user => _user;

  AuthProvider() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
    _user = FirebaseAuth.instance.currentUser;
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> refreshAuthStatus() async {
    _user = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
