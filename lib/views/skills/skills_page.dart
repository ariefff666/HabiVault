// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:habi_vault/controllers/skill_controller.dart';
import 'package:habi_vault/models/skill_model.dart';
import 'package:habi_vault/views/skills/add_skill_panel.dart';
import 'package:habi_vault/views/skills/skill_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Enum untuk pilihan sortir
enum SortSkillsBy { name, createdAt, xp }

class SkillsPage extends StatefulWidget {
  // Notifier untuk menerima sinyal dari MainView
  final ValueNotifier<bool> showAddSkillPanelNotifier;

  const SkillsPage({super.key, required this.showAddSkillPanelNotifier});

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // final SkillController _skillController = SkillController();

  // State untuk menyimpan pilihan sortir saat ini
  SortSkillsBy _sortBy = SortSkillsBy.createdAt;
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.showAddSkillPanelNotifier.addListener(_onShowPanelSignal);
  }

  void _onShowPanelSignal() {
    // Jika sinyalnya true, tampilkan panel
    if (widget.showAddSkillPanelNotifier.value) {
      // Gunakan addPostFrameCallback untuk memastikan build selesai
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showAddSkillPanel(context);
        }
      });
      // Reset sinyal setelah digunakan
      widget.showAddSkillPanelNotifier.value = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    widget.showAddSkillPanelNotifier.removeListener(_onShowPanelSignal);
    super.dispose();
  }

  // Fungsi untuk menampilkan bottom sheet pilihan sortir
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // Gunakan StatefulBuilder agar bottom sheet bisa update state-nya sendiri
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                runSpacing: 12,
                children: [
                  Text('Sort Arsenal By',
                      style: Theme.of(context).textTheme.titleLarge),
                  RadioListTile<SortSkillsBy>(
                    title: const Text('Creation Date'),
                    value: SortSkillsBy.createdAt,
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setModalState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                  RadioListTile<SortSkillsBy>(
                    title: const Text('Name (A-Z)'),
                    value: SortSkillsBy.name,
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setModalState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                  RadioListTile<SortSkillsBy>(
                    title: const Text('Experience (XP)'),
                    value: SortSkillsBy.xp,
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setModalState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Descending Order'),
                    value: _sortDescending,
                    onChanged: (value) {
                      setModalState(() {
                        _sortDescending = value;
                      });
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Apply Sort'),
                    onPressed: () {
                      // Terapkan pilihan sortir ke state utama dan tutup sheet
                      setState(() {});
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanctuary of Potential'),
        actions: [
          // Tombol untuk membuka pilihan sortir
          IconButton(
            icon: const Icon(Icons.sort_by_alpha_rounded),
            onPressed: _showSortOptions,
            tooltip: 'Sort Skills',
          ),
        ],
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(text: 'My Arsenal'),
            Tab(text: 'Paths Unseen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyArsenalView(sortBy: _sortBy, sortDescending: _sortDescending),
          _PathsUnseenView(),
        ],
      ),
    );
  }
}

// --- WIDGET UNTUK TAB "MY ARSENAL" ---
class _MyArsenalView extends StatelessWidget {
  final SkillController _skillController = SkillController();
  final SortSkillsBy sortBy;
  final bool sortDescending;

  _MyArsenalView({required this.sortBy, required this.sortDescending});

  String get _orderByField {
    switch (sortBy) {
      case SortSkillsBy.name:
        return 'name';
      case SortSkillsBy.xp:
        return 'currentXp';
      case SortSkillsBy.createdAt:
        return 'createdAt';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SkillModel>>(
      // Panggil getSkills dengan parameter sortir dari state
      stream: _skillController.getSkills(
          orderByField: _orderByField, descending: sortDescending),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _EmptySkillsState();
        }

        final skills = snapshot.data ?? [];

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: skills.length + 1,
          itemBuilder: (context, index) {
            if (index == skills.length) {
              return const ForgeSkillCard();
            }
            // Berikan ValueKey unik agar Flutter bisa menganimasikan perubahan urutan
            return SkillCard(
                    key: ValueKey(skills[index].id), skill: skills[index])
                .animate(delay: (50 * index).ms) // Animasi "Puzzle"
                .fadeIn(duration: 400.ms)
                .move(begin: const Offset(0, 20), curve: Curves.easeOut);
          },
        );
      },
    );
  }
}

// --- WIDGET UNTUK KARTU "FORGE A NEW SKILL" ---
class ForgeSkillCard extends StatelessWidget {
  const ForgeSkillCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.primary.withOpacity(0.5), width: 1.5),
      ),
      child: InkWell(
        onTap: () => showAddSkillPanel(context),
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 40, color: colors.primary),
              const SizedBox(height: 8),
              Text(
                'Forge a New Skill',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .shimmer(
          delay: 2.seconds,
          duration: 1800.ms,
          color: colors.primary.withOpacity(0.3),
        );
  }
}

// --- WIDGET UNTUK TAB "PATHS UNSEEN" ---
class _PathsUnseenView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withOpacity(0.2)
            : Colors.grey.shade200,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 80, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            const Text(
              'Discover New Paths',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-powered skill recommendations are coming soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }
}

// --- WIDGET UNTUK EMPTY STATE ---
class _EmptySkillsState extends StatelessWidget {
  const _EmptySkillsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_moon_outlined,
                    size: 100, color: Colors.grey)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(
                    duration: 2000.ms,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3))
                .animate() // chain animation
                .slideY(
                    begin: -0.2,
                    end: 0.2,
                    duration: 2000.ms,
                    curve: Curves.easeInOut),
            const SizedBox(height: 24),
            Text(
              'Perpustakaan Rune Kosong',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Setiap petualang hebat memulai dari satu keahlian. Ukir Rune pertamamu dan mulailah perjalanan menuju penguasaan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Ukir Rune Pertama'),
              onPressed: () => showAddSkillPanel(context),
            )
          ],
        ).animate().fadeIn(duration: 600.ms),
      ),
    );
  }
}
