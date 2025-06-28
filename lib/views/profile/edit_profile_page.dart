import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:habi_vault/controllers/user_controller.dart';
import 'package:habi_vault/models/user_model.dart';
import 'package:habi_vault/widgets/custom_dialog.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel currentUser;

  const EditProfilePage({super.key, required this.currentUser});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final UserController _userController = UserController();
  File? _profileImageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _userController.updateUserProfile(
        newName: _nameController.text.trim(),
        newImageFile: _profileImageFile,
      );

      if (mounted) {
        Navigator.pop(context); // Kembali ke halaman pengaturan
        showHabiVaultDialog(
          context: context,
          title: "Sukses!",
          message: "Profilmu telah berhasil ditempa ulang.",
          type: DialogType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showHabiVaultDialog(
          context: context,
          title: "Gagal",
          message: e.toString(),
          type: DialogType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tempa Ulang Identitas"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Avatar Picker
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    backgroundImage: _profileImageFile != null
                        ? FileImage(_profileImageFile!) as ImageProvider
                        : (widget.currentUser.photoUrl.isNotEmpty
                            ? NetworkImage(widget.currentUser.photoUrl)
                            : null),
                    child: _profileImageFile == null &&
                            widget.currentUser.photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Theme.of(context).colorScheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _pickImage,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child:
                              Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(),

            const SizedBox(height: 32),

            // Nama Pengguna
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Petualang',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong.';
                }
                return null;
              },
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),

            const SizedBox(height: 16),

            // Email (Read-only)
            TextFormField(
              initialValue: widget.currentUser.email,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email (Tidak dapat diubah)',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                filled: true,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),

            const SizedBox(height: 40),

            // Tombol Simpan
            ElevatedButton(
              onPressed: _submitProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Simpan Perubahan'),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }
}
