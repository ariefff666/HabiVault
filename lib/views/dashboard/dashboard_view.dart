// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:habi_vault/controllers/user_controller.dart';
import 'package:habi_vault/models/user_model.dart';
import 'package:habi_vault/controllers/mission_controller.dart';
import 'package:habi_vault/models/mission_model.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final UserController _userController = UserController();
  final MissionController _missionController = MissionController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: _userController.getUserData(),
          builder: (context, snapshot) {
            // Handle different states
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading user data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No user data found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please log in to continue',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }

            // Safe to use data now
            final userModel = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                _CharacterStatusHeader(userModel: userModel),
                const SizedBox(height: 32),
                _buildSectionTitle(context, 'Skill Summary'),
                const SizedBox(height: 16),
                const _PlaceholderCard(
                    height: 160, text: 'Skill Carousel - Coming Soon'),
                const SizedBox(height: 32),

                // GANTI BAGIAN INI
                _buildSectionTitle(context, "Today's Missions"),
                const SizedBox(height: 16),
                _TodaysMissionsSection(missionController: _missionController),

                const SizedBox(height: 90),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1);
  }
}

// WIDGET UNTUK ZONA 1: HEADER STATUS KARAKTER (HUD)
class _CharacterStatusHeader extends StatelessWidget {
  final UserModel userModel;
  const _CharacterStatusHeader({required this.userModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {/* Navigasi ke Halaman Profil */},
          child: CircleAvatar(
            radius: 32,
            backgroundImage: userModel.photoUrl.isNotEmpty
                ? NetworkImage(userModel.photoUrl)
                : null,
            child: userModel.photoUrl.isEmpty
                ? Text(userModel.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold))
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userModel.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // Tampilkan gelar di sebelah level
              Text(
                'Level ${userModel.level} · ${userModel.title}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              _AnimatedXpBar(
                currentXp: userModel.xp,
                maxXp: userModel.xpToNextLevel,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${userModel.xp} / ${userModel.xpToNextLevel} XP',
                      style: Theme.of(context).textTheme.labelSmall),
                  Icon(Icons.upgrade,
                      size: 14, color: Theme.of(context).colorScheme.primary),
                ],
              )
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, curve: Curves.easeOutCubic);
  }
}

// WIDGET KUSTOM UNTUK XP BAR YANG ANIMATIF
class _AnimatedXpBar extends StatelessWidget {
  final int currentXp;
  final int maxXp;
  final Color color;

  const _AnimatedXpBar(
      {required this.currentXp, required this.maxXp, required this.color});

  @override
  Widget build(BuildContext context) {
    final double progress = currentXp / maxXp;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 10,
        color: Theme.of(context).colorScheme.surface,
        child: Align(
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (ctx, constraints) => Container(
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                  stops: const [0.1, 1.0],
                ),
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .shimmer(
                  duration: 1500.ms,
                  delay: 500.ms,
                  color: Colors.white.withOpacity(0.3),
                ),
          ),
        ),
      ),
    );
  }
}

class _TodaysMissionsSection extends StatelessWidget {
  final MissionController missionController;
  const _TodaysMissionsSection({required this.missionController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MissionModel>>(
      stream: missionController.getTodaysMissions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _PlaceholderCard(
            height: 150,
            text: 'No missions for today. Enjoy your break!',
          );
        }

        final missions = snapshot.data!;
        return Column(
          children: missions.map((mission) {
            return MissionCard(
              mission: mission,
              onCompleted: () => missionController.completeMission(mission),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3);
          }).toList(),
        );
      },
    );
  }
}

// KARTU MISI YANG INTERAKTIF DAN ANIMATIF
class MissionCard extends StatelessWidget {
  final MissionModel mission;
  final VoidCallback onCompleted;

  const MissionCard(
      {super.key, required this.mission, required this.onCompleted});

  bool _isCompletedToday() {
    if (mission.lastCompleted == null) return false;
    final now = DateTime.now();
    final last = mission.lastCompleted!.toDate();
    return now.year == last.year &&
        now.month == last.month &&
        now.day == last.day;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = _isCompletedToday();
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDone ? colors.surface.withOpacity(0.5) : colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox Kustom
            GestureDetector(
              onTap: isDone ? null : onCompleted,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? colors.primary : Colors.transparent,
                  border: Border.all(
                      color: isDone ? Colors.transparent : colors.primary,
                      width: 2),
                ),
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Info Misi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: isDone ? Theme.of(context).disabledColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 14, color: colors.primary.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '// TODO: Skill Name', // Nanti kita ganti dengan nama skill asli
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.primary.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // XP Gain
            Text(
              '+${mission.xp} XP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    isDone ? Theme.of(context).disabledColor : colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGET PLACEHOLDER UNTUK KONTEN MENDATANG
class _PlaceholderCard extends StatelessWidget {
  final double height;
  final String text;
  const _PlaceholderCard({required this.height, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withOpacity(0.5)),
        ),
      ),
    );
  }
}
