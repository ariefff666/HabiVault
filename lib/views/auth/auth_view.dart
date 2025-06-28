// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:habi_vault/controllers/auth_controller.dart';
// import 'package:habi_vault/notifiers/theme_notifier.dart';
import 'package:habi_vault/widgets/custom_dialog.dart';
import 'package:habi_vault/notifiers/auth_provider.dart' as custom_auth;

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final AuthController _authController = AuthController();
  bool _isLoginMode = true;
  bool _isLoading = false;
  File? _profileImage;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _profileImage = null;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // FUNGSI UNTUK MENAMPILKAN DIALOG VERIFIKASI
  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.grey.shade800.withOpacity(0.8),
            title: const Center(
              child: Text('One Last Step!',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    color: Colors.amber, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'A verification link has been sent to your email. Please verify, then log in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.currentUser
                      ?.sendEmailVerification();
                  if (context.mounted) {
                    showHabiVaultDialog(
                        context: context,
                        title: "Success",
                        message: "Verification email has been resent.",
                        type: DialogType.success);
                  }
                },
                child: const Text('Resend Email',
                    style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK, I Understand'),
              ),
            ],
          ),
        ).animate().fadeIn();
      },
    );
  }

  Future<void> _submitEmailPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
        await _authController.loginWithEmail(
            _emailController.text, _passwordController.text);

        if (mounted) {
          await Provider.of<custom_auth.AuthProvider>(context, listen: false)
              .refreshAuthStatus();
        }
      } else {
        await _authController.registerWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
          imageFile: _profileImage,
        );
        if (mounted) _showVerificationDialog();
      }
    } on AuthException catch (e) {
      if (mounted) {
        showHabiVaultDialog(
            context: context,
            title: 'Oops!',
            message: e.message,
            type: DialogType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authController.loginWithGoogle();
    } on AuthException catch (e) {
      if (mounted) {
        showHabiVaultDialog(
            context: context,
            title: 'Google Sign-In Failed',
            message: e.message,
            type: DialogType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1D2B64), Color(0xFF373B44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Positioned(
          //   top: 40,
          //   right: 20,
          //   child: Consumer<ThemeNotifier>(
          //     builder: (context, theme, child) => IconButton(
          //       icon: Icon(theme.themeMode == ThemeMode.dark
          //           ? Icons.light_mode_outlined
          //           : Icons.dark_mode_outlined),
          //       onPressed: () => theme.toggleTheme(),
          //       color: Colors.white,
          //     ).animate().fade(delay: 500.ms),
          //   ),
          // ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                              color: Colors.white,
                            ))
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AnimatedSwitcher(
                                  duration: 500.ms,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                          opacity: animation, child: child),
                                  child: Text(
                                    _isLoginMode
                                        ? 'Welcome Back'
                                        : 'Create Account',
                                    key: ValueKey(_isLoginMode),
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                AnimatedSize(
                                  duration: 300.ms,
                                  curve: Curves.fastOutSlowIn,
                                  child: Column(children: _buildFormFields()),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _submitEmailPassword,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: const Color(0xFF6C63FF),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                      _isLoginMode
                                          ? 'Log In'
                                          : 'Create Account',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                                if (_isLoginMode) ...[
                                  const SizedBox(height: 16),
                                  const Row(
                                    children: [
                                      Expanded(
                                          child:
                                              Divider(color: Colors.white30)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text('OR',
                                            style: TextStyle(
                                                color: Colors.white70)),
                                      ),
                                      Expanded(
                                          child:
                                              Divider(color: Colors.white30)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    icon: Image.asset(
                                        'assets/icons/google_icon.png',
                                        height: 20),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      side: BorderSide(
                                          color: Colors.white.withOpacity(0.5)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onPressed: _submitGoogle,
                                    label: const Text('Continue with Google',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _switchMode,
                                  child: Text(
                                    _isLoginMode
                                        ? "Don't have an account? Register"
                                        : "Already have an account? Log In",
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                )
                              ]
                                  .animate(interval: 100.ms)
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.2),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );
    }

    if (_isLoginMode) {
      return [
        TextFormField(
            controller: _emailController,
            decoration: inputDecoration('Email', Icons.email_outlined),
            validator: (value) => value!.isEmpty || !value.contains('@')
                ? 'Enter a valid email'
                : null,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: inputDecoration('Password', Icons.lock_outline),
            validator: (value) => value!.length < 6
                ? 'Password must be at least 6 characters'
                : null,
            style: const TextStyle(color: Colors.white)),
      ];
    } else {
      return [
        Center(
            child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.black.withOpacity(0.2),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(Icons.camera_alt_outlined,
                            size: 40, color: Colors.white.withOpacity(0.7))
                        : null))),
        const SizedBox(height: 16),
        TextFormField(
            controller: _nameController,
            decoration: inputDecoration('Full Name', Icons.person_outline),
            validator: (value) =>
                value!.isEmpty ? 'Please enter your name' : null,
            style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        TextFormField(
            controller: _emailController,
            decoration: inputDecoration('Email', Icons.email_outlined),
            validator: (value) => value!.isEmpty || !value.contains('@')
                ? 'Enter a valid email'
                : null,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: inputDecoration('Password', Icons.lock_outline),
            validator: (value) => value!.length < 6
                ? 'Password must be at least 6 characters'
                : null,
            style: const TextStyle(color: Colors.white)),
      ];
    }
  }
}
