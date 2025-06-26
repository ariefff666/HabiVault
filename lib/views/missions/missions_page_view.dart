import 'package:flutter/material.dart';
import 'package:habi_vault/views/missions/create_mission_altar.dart';

class QuestsPage extends StatefulWidget {
  final bool showAltarOnLoad;

  const QuestsPage({
    super.key,
    this.showAltarOnLoad = false,
  });

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  @override
  void initState() {
    super.initState();
    // Tetap tangani kasus jika halaman dimuat pertama kali dengan flag true
    if (widget.showAltarOnLoad) {
      _openAltarAfterBuild();
    }
  }

  // --- PERBAIKAN UTAMA ADA DI SINI ---
  @override
  void didUpdateWidget(QuestsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Method ini akan dipanggil setiap kali MainView melakukan setState
    // Kita cek apakah flag `showAltarOnLoad` baru saja berubah menjadi true
    if (widget.showAltarOnLoad && !oldWidget.showAltarOnLoad) {
      _openAltarAfterBuild();
    }
  }

  void _openAltarAfterBuild() {
    // Menggunakan addPostFrameCallback untuk memastikan build selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showCreateMissionAltar(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Missions'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Your Missions Will Appear Here',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first mission to get started!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      // Tombol + di halaman ini juga bisa membuka Altar
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateMissionAltar(context),
        label: const Text('New Mission'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
