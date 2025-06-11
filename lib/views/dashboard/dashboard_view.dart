import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:habi_vault/controllers/auth_controller.dart';
import 'package:habi_vault/controllers/habit_controller.dart';
import 'package:habi_vault/models/habit_model.dart';
import 'package:habi_vault/notifiers/theme_notifier.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final HabitController _habitController = HabitController();
  final AuthController _authController = AuthController();

  void _showAddHabitDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Habit'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Habit Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _habitController.addHabit(name: nameController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HabiVault'),
        actions: [
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: child.key == const ValueKey('icon1')
                          ? Tween<double>(begin: 1, end: 0.75)
                              .animate(animation)
                          : Tween<double>(begin: 0.75, end: 1)
                              .animate(animation),
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: themeNotifier.themeMode == ThemeMode.dark
                      ? const Icon(Icons.nightlight_round,
                          key: ValueKey('icon1'))
                      : const Icon(Icons.wb_sunny_rounded,
                          key: ValueKey('icon2')),
                ),
                onPressed: () => themeNotifier.toggleTheme(),
              );
            },
          ),
          // TOMBOL LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authController.logout();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Habit>>(
        stream: _habitController.getHabits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: const Text(
                'No habits yet.\nTap a + to add your first habit!',
                textAlign: TextAlign.center,
              ).animate().fade(duration: 500.ms).scale(),
            );
          }

          final habits = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return _HabitCard(habit: habit)
                  .animate()
                  .fadeIn(delay: (100 * index).ms, duration: 400.ms)
                  .slideX(begin: -0.2, curve: Curves.easeOutCubic);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: const Icon(Icons.add),
      ).animate().scale(delay: 300.ms),
    );
  }
}

// Widget _HabitCard tidak berubah
class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit});
  final Habit habit;
  @override
  Widget build(BuildContext context) {
    double progress = habit.currentXp / habit.xpToNextLevel;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(habit.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Level ${habit.level}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.isNaN ? 0 : progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('XP: ${habit.currentXp} / ${habit.xpToNextLevel}',
                    style: Theme.of(context).textTheme.labelSmall),
                const Text('Next Level'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
