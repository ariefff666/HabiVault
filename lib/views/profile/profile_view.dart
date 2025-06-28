// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:habi_vault/controllers/user_controller.dart';
import 'package:habi_vault/models/user_model.dart';
import 'package:habi_vault/views/settings/settings_page.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final UserController userController = UserController();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Adventurer's Dossier"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Pengaturan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: userController.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Gagal memuat data pengguna."));
          }
          final user = snapshot.data!;
          final progress =
              user.xp / (user.xpToNextLevel > 0 ? user.xpToNextLevel : 100);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withOpacity(0.3),
                  Theme.of(context).scaffoldBackgroundColor
                ],
                stops: const [0.0, 0.4],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 110),
              children: [
                _buildProfileHeader(context, user, progress),
                const SizedBox(height: 32),
                _buildStatsGrid(),
                const SizedBox(height: 32),
                _buildAchievementsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, UserModel user, double progress) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.surface,
          backgroundImage:
              user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
          child:
              user.photoUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
        ),
        const SizedBox(height: 16),
        Text(user.name,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(user.title,
            style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Text('Level ${user.level}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Theme.of(context).dividerColor,
            ),
          ),
        ),
        Text('${user.xp} / ${user.xpToNextLevel} XP',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
        children: const [
          _StatCard(
              icon: Icons.check_circle, value: '124', label: 'Misi Selesai'),
          _StatCard(
              icon: Icons.local_fire_department,
              value: '12 hari',
              label: 'Streak Terpanjang'),
          _StatCard(
              icon: Icons.star, value: '5,680', label: 'Total XP Didapat'),
          _StatCard(
              icon: Icons.military_tech, value: '3', label: 'Skill Dikuasai'),
        ],
      ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2);
    });
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pencapaian',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _AchievementBadge(icon: Icons.flag, label: 'Misi Pertama'),
              _AchievementBadge(icon: Icons.rocket_launch, label: 'Level 10'),
              _AchievementBadge(icon: Icons.school, label: 'Ahli Skill'),
              _AchievementBadge(
                  icon: Icons.calendar_month,
                  label: 'Streak 7 Hari',
                  locked: true),
              _AchievementBadge(
                  icon: Icons.wb_sunny, label: 'Morning Person', locked: true),
            ],
          ),
        )
      ],
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool locked;
  const _AchievementBadge(
      {required this.icon, required this.label, this.locked = false});

  @override
  Widget build(BuildContext context) {
    final color =
        locked ? Colors.grey.shade700 : Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(locked ? Icons.lock : icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
