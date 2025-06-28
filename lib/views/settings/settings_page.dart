// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:habi_vault/controllers/auth_controller.dart';
import 'package:habi_vault/controllers/user_controller.dart';
import 'package:habi_vault/models/user_model.dart';
import 'package:habi_vault/notifiers/theme_notifier.dart';
import 'package:habi_vault/views/auth/auth_view.dart';
import 'package:habi_vault/views/profile/change_password_dialog.dart';
import 'package:habi_vault/views/profile/edit_profile_page.dart';
import 'package:provider/provider.dart';

// --- DIUBAH MENJADI STATEFULWIDGET ---
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthController authController = AuthController();

  Future<void> _logout() async {
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // ... isi dialog tidak berubah
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Keluar', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true && mounted) {
      // 1. Kembali ke halaman paling awal di dalam MainView (yaitu Dashboard)
      // Ini membersihkan tumpukan navigasi seperti SettingsPage, ProfilePage, dll.
      Navigator.of(context).popUntil((route) => route.isFirst);

      // 2. Lakukan operasi logout dari Firebase
      await authController.logout();

      // 3. SELESAI. Tidak perlu navigasi manual ke AuthView.
      // AuthProvider dan Consumer di main.dart akan menanganinya secara otomatis.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Akun',
            tiles: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profil',
                onTap: () {
                  // Ambil data user saat ini untuk dikirim ke halaman edit
                  final userStream = UserController().getUserData();
                  userStream.first.then((UserModel? currentUser) {
                    if (currentUser != null && mounted) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EditProfilePage(currentUser: currentUser)));
                    }
                  });
                },
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Ubah Password',
                onTap: () {
                  showChangePasswordDialog(context);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Tampilan & Notifikasi',
            tiles: [
              Consumer<ThemeNotifier>(
                builder: (context, themeNotifier, child) {
                  return _SettingsTile(
                    icon: themeNotifier.themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: 'Mode Gelap',
                    trailing: Switch(
                      value: themeNotifier.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        themeNotifier.toggleTheme();
                      },
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi Misi',
                trailing: Switch(
                  value: true, // Placeholder
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Lainnya',
            tiles: [
              _SettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Kirim Masukan',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Kebijakan Privasi',
                onTap: () {},
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: _logout, // Panggil fungsi dari state
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text('Keluar'),
            ),
          )
        ],
      ),
    );
  }
}

// Widget-widget kustom
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> tiles;
  const _SettingsSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...tiles,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile(
      {required this.icon, required this.title, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
