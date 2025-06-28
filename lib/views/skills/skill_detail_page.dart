// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:habi_vault/controllers/mission_controller.dart';
import 'package:habi_vault/controllers/skill_controller.dart';
import 'package:habi_vault/models/mission_model.dart';
import 'package:habi_vault/models/skill_model.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'add_skill_panel.dart'; // Impor panel untuk edit
import 'package:fl_chart/fl_chart.dart';

class SkillDetailPage extends StatefulWidget {
  // Terima skillId, bukan lagi seluruh objek SkillModel
  final String skillId;
  const SkillDetailPage({super.key, required this.skillId});

  @override
  State<SkillDetailPage> createState() => _SkillDetailPageState();
}

class _SkillDetailPageState extends State<SkillDetailPage>
    with SingleTickerProviderStateMixin {
  final MissionController _missionController = MissionController();
  final SkillController _skillController = SkillController();
  late TabController _tabController;

  void _showDeleteConfirmation(SkillModel skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Path?'),
        content: Text(
            'Are you sure you want to abandon the path of "${skill.name}"? All related progress and missions will be lost forever.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Tutup dialog
              Navigator.of(context).pop(); // Kembali dari halaman detail
              await _skillController.deleteSkill(skill.id);
            },
            child: const Text('Abandon', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan StreamBuilder di level tertinggi untuk mendapatkan data skill terbaru
    return StreamBuilder<SkillModel?>(
      stream: _skillController.getSkillById(widget.skillId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final skill = snapshot.data!;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildEpicHeader(skill),
              SliverToBoxAdapter(child: _buildStatsPanel(skill)),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Upcoming Missions'),
                      Tab(text: 'Completed Log'),
                    ],
                  ),
                ),
                pinned: true,
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMissionList(skillId: skill.id, isCompleted: false),
                    _buildMissionList(skillId: skill.id, isCompleted: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEpicHeader(SkillModel skill) {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      stretch: true,
      backgroundColor: Color(skill.color),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(skill.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 4)])),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(skill.color).withOpacity(0.8),
                Color(skill.color).withOpacity(0.4)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(
              IconData(int.parse(skill.icon), fontFamily: 'MaterialIcons'),
              size: 90,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => showAddSkillPanel(context, skill: skill),
          icon: const Icon(Icons.auto_fix_high),
          tooltip: 'Reforge Skill',
        ),
        IconButton(
          onPressed: () => _showDeleteConfirmation(skill),
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: 'Abandon Path',
        ),
      ],
    );
  }

  // WIDGET: Panel Statistik
  Widget _buildStatsPanel(SkillModel skill) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mastery Progress (Last 7 Days)',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            // Gunakan StreamBuilder untuk mengambil data log XP
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _skillController.getXpLogForSkill(skill.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Proses data log menjadi data yang bisa dibaca oleh grafik
                final spots = _processXpLogForChart(snapshot.data!);

                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots.isNotEmpty
                            ? spots
                            : [const FlSpot(0, 0)], // Pastikan tidak kosong
                        isCurved: true,
                        color: Color(skill.color),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Color(skill.color).withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total XP', skill.currentXp.toString()),

              // Statistik "Missions Done" dengan StreamBuilder
              StreamBuilder<int>(
                stream: _missionController.countCompletedMissions(skill.id),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('Missions Done', count.toString());
                },
              ),

              // Statistik "Current Streak" dengan FutureBuilder
              FutureBuilder<int>(
                future: _missionController.calculateSkillStreak(skill.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildStatItem('Current Streak', '...');
                  }
                  final streak = snapshot.data ?? 0;
                  return _buildStatItem('Current Streak', '$streak days');
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  List<FlSpot> _processXpLogForChart(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return [];

    // Kelompokkan XP berdasarkan hari
    Map<int, double> dailyXp = {};
    for (var log in logs) {
      final timestamp =
          (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final day = timestamp.day;
      dailyXp[day] = (dailyXp[day] ?? 0) + (log['xpGained'] as int);
    }

    // Buat daftar titik untuk 7 hari terakhir
    List<FlSpot> spots = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final xp = dailyXp[date.day] ?? 0.0;
      spots.add(FlSpot(6.0 - i, xp)); // X: 0=6 hari lalu, 6=hari ini
    }
    return spots;
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // WIDGET DAFTAR MISI YANG SUDAH DIPISAH
  Widget _buildMissionList(
      {required String skillId, required bool isCompleted}) {
    return StreamBuilder<List<MissionModel>>(
      stream: _missionController.getMissionsForSkill(skillId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final missions = snapshot.data!.where((m) {
          if (m.lastCompleted == null) return !isCompleted;
          final last = m.lastCompleted!.toDate();
          final isDoneToday = now.year == last.year &&
              now.month == last.month &&
              now.day == last.day;
          return isCompleted ? isDoneToday : !isDoneToday;
        }).toList();

        if (missions.isEmpty) {
          return Center(
              child: Text(isCompleted
                  ? 'No missions completed today.'
                  : 'No upcoming missions.'));
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: missions.length,
          itemBuilder: (context, index) {
            final mission = missions[index];
            final formatter = DateFormat('d MMM, HH:mm');
            return ListTile(
              leading: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
              title: Text(mission.title),
              subtitle: Text(
                isCompleted
                    ? 'Completed: ${formatter.format(mission.lastCompleted!.toDate())}'
                    : 'Scheduled',
              ),
              trailing: Text('+${mission.xp} XP',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }
}

// Helper class untuk membuat TabBar menjadi "sticky"
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
        color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
