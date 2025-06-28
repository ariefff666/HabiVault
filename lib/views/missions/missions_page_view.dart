// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:confetti/confetti.dart'; // Impor confetti
import 'package:flutter/material.dart';
import 'package:habi_vault/controllers/mission_controller.dart';
import 'package:habi_vault/models/enriched_mission_model.dart';
import 'package:habi_vault/models/mission_model.dart';
import 'package:habi_vault/models/skill_model.dart';
import 'package:habi_vault/views/missions/create_mission_altar.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Impor animate
import 'package:collection/collection.dart';
import 'package:habi_vault/views/missions/edit_mission_panel.dart';
import 'package:habi_vault/views/missions/mission_detail_page.dart';
import 'package:intl/intl.dart';

enum MissionStatus { today, upcoming, completed }

class QuestsPage extends StatefulWidget {
  // --- PERUBAHAN: Gunakan ValueNotifier untuk menghindari rebuild ---
  final ValueNotifier<bool> showAltarNotifier;

  const QuestsPage({super.key, required this.showAltarNotifier});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MissionController _missionController = MissionController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.showAltarNotifier.addListener(_onShowAltarSignal);
  }

  void _onShowAltarSignal() {
    if (widget.showAltarNotifier.value) {
      // Tampilkan altar jika sinyalnya true
      showCreateMissionAltar(context);
      // Reset sinyal setelah digunakan
      widget.showAltarNotifier.value = false;
    }
  }

  @override
  void dispose() {
    widget.showAltarNotifier.removeListener(_onShowAltarSignal);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adventurer\'s Journal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hari Ini'),
            Tab(text: 'Akan Datang'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: StreamBuilder<List<EnrichedMissionModel>>(
        stream: _missionController.getEnrichedMissionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(); // Widget untuk saat tidak ada misi sama sekali
          }

          final allMissions = snapshot.data!;
          final groupedData = _groupAndFilterMissions(allMissions);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMissionTab(
                  MissionStatus.today, groupedData[MissionStatus.today] ?? {}),
              _buildMissionTab(MissionStatus.upcoming,
                  groupedData[MissionStatus.upcoming] ?? {}),
              _buildMissionTab(MissionStatus.completed,
                  groupedData[MissionStatus.completed] ?? {}),
            ],
          );
        },
      ),
    );
  }

  // LOGIKA BARU UNTUK MEMFILTER DAN MENGELOMPOKKAN
  Map<MissionStatus, Map<SkillModel, List<EnrichedMissionModel>>>
      _groupAndFilterMissions(List<EnrichedMissionModel> allMissions) {
    final now = DateTime.now();

    List<EnrichedMissionModel> todayMissions = [];
    List<EnrichedMissionModel> upcomingMissions = [];
    List<EnrichedMissionModel> completedMissions = [];

    // --- PENYESUAIAN LOGIKA UNTUK COMPLETED ---
    final Map<String, EnrichedMissionModel> latestCompletions = {};

    for (var enrichedMission in allMissions) {
      final mission = enrichedMission.mission;

      final bool wasCompletedToday = mission.lastCompleted != null &&
          DateUtils.isSameDay(mission.lastCompleted!.toDate(), now);

      // 1. Proses misi yang selesai HARI INI
      if (wasCompletedToday) {
        // Jika misi ini belum ada di map, atau yang ini lebih baru, tambahkan/perbarui.
        if (!latestCompletions.containsKey(mission.id) ||
            mission.lastCompleted!.toDate().isAfter(
                latestCompletions[mission.id]!
                    .mission
                    .lastCompleted!
                    .toDate())) {
          latestCompletions[mission.id] = enrichedMission;
        }
      }

      // 2. Tambahkan ke 'Hari Ini' jika dijadwalkan untuk hari ini DAN belum selesai.
      // Ini menangani misi berulang dan misi hasil reschedule.
      bool isScheduledToday = mission.isRescheduled
          ? DateUtils.isSameDay(mission.createdAt.toDate(), now)
          : mission.scheduleDays.contains(now.weekday);

      if (isScheduledToday && !wasCompletedToday) {
        todayMissions.add(enrichedMission);
      }

      // 3. Cari satu jadwal mendatang berikutnya dan tambahkan ke 'Akan Datang'.
      // Logika ini sekarang benar, bahkan jika jadwal hari ini sudah selesai.
      DateTime? nextUpcoming = _findNextUpcomingSchedule(mission, now);
      if (nextUpcoming != null) {
        upcomingMissions.add(EnrichedMissionModel(
            mission: mission,
            skill: enrichedMission.skill,
            specificUpcomingDate: nextUpcoming));
      }
    }

    completedMissions = latestCompletions.values.toList();

    // Urutkan daftar 'Akan Datang' berdasarkan tanggal terdekat.
    upcomingMissions.sort(
        (a, b) => a.specificUpcomingDate!.compareTo(b.specificUpcomingDate!));

    return {
      MissionStatus.today: groupBy(todayMissions, (m) => m.skill!),
      MissionStatus.upcoming: groupBy(upcomingMissions, (m) => m.skill!),
      MissionStatus.completed: groupBy(completedMissions, (m) => m.skill!),
    };
  }

  /// Helper untuk menemukan jadwal valid berikutnya yang akan datang.
  DateTime? _findNextUpcomingSchedule(MissionModel mission, DateTime now) {
    List<DateTime> potentialSchedules = [];

    // Jika misi di-reschedule, tanggal pembuatannya adalah jadwalnya.
    if (mission.isRescheduled) {
      final scheduledDate = mission.createdAt.toDate();
      // Hanya pertimbangkan jika jadwalnya di masa depan.
      if (scheduledDate.isAfter(now)) {
        return scheduledDate;
      }
      return null; // Abaikan jadwal reschedule yang sudah lewat.
    }

    // Untuk misi berulang, cari tanggal berikutnya.
    // Titik referensi adalah kapan terakhir selesai, atau saat ini jika belum pernah.
    DateTime referenceDate =
        (mission.lastCompleted != null) ? mission.lastCompleted!.toDate() : now;

    // Cari selama 7 hari ke depan dari titik referensi.
    for (int i = 1; i <= 7; i++) {
      final checkDate = referenceDate.add(Duration(days: i));
      if (mission.scheduleDays.contains(checkDate.weekday)) {
        final scheduleDateTime = DateTime(checkDate.year, checkDate.month,
            checkDate.day, mission.startTime.hour, mission.startTime.minute);

        // Jadwal harus di masa depan relatif terhadap 'sekarang'.
        if (scheduleDateTime.isAfter(now)) {
          potentialSchedules.add(scheduleDateTime);
        }
      }
    }

    if (potentialSchedules.isEmpty) return null;

    // Urutkan untuk mendapatkan yang paling dekat.
    potentialSchedules.sort();
    return potentialSchedules.first;
  }

  Widget _buildMissionTab(
      MissionStatus status, Map<SkillModel, List<EnrichedMissionModel>> data) {
    if (data.isEmpty) {
      // KEMBALIKAN DESAIN EMPTY STATE KUSTOM
      return _EmptyStateCard(status: status);
    }

    final skillGroups = data.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      // Tambah 1 untuk kartu "Forge Mission"
      itemCount: skillGroups.length + 1,
      itemBuilder: (context, index) {
        // KEMBALIKAN KARTU "FORGE MISSION" DI ATAS
        if (index == 0) {
          return _buildAddMissionCard();
        }

        final skill = skillGroups[index - 1].key;
        final missions = skillGroups[index - 1].value;
        return _SkillMissionGroup(
          skill: skill,
          missions: missions,
          status: status,
        );
      },
    );
  }

  // --- KARTU "FORGE MISSION" ---
  Widget _buildAddMissionCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 1.5,
            style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: () => showCreateMissionAltar(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text('Forge a New Mission',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // Widget _buildMissionList(
  //     String filter, Map<SkillModel, List<MissionModel>> allGroupedData) {
  //   final now = DateTime.now();
  //   final todayWeekday = now.weekday;

  //   final Map<SkillModel, List<MissionModel>> filteredGroupedData = {};

  //   allGroupedData.forEach((skill, missions) {
  //     List<MissionModel> filteredMissions = missions.where((m) {
  //       final isCompletedToday =
  //           m.lastCompleted != null && m.lastCompleted!.toDate().day == now.day;
  //       final isScheduledForToday = m.scheduleDays.contains(todayWeekday);

  //       switch (filter) {
  //         case 'today':
  //           return isScheduledForToday && !isCompletedToday;
  //         case 'upcoming':
  //           return !isScheduledForToday && !isCompletedToday;
  //         case 'completed':
  //           return isCompletedToday;
  //         default:
  //           return false;
  //       }
  //     }).toList();

  //     if (filteredMissions.isNotEmpty) {
  //       filteredGroupedData[skill] = filteredMissions;
  //     }
  //   });

  //   if (filteredGroupedData.isEmpty) {
  //     switch (filter) {
  //       case 'today':
  //         return const _EmptyStateCard(
  //           icon: Icons.nightlight_round,
  //           title: 'A Quiet Day',
  //           subtitle:
  //               'No missions are scheduled for today. Forge a new quest or enjoy your well-deserved peace!',
  //         );
  //       case 'upcoming':
  //         return const _EmptyStateCard(
  //           icon: Icons.map_outlined,
  //           title: 'The Path is Clear',
  //           subtitle:
  //               'You have no upcoming missions scheduled for other days. Plan your next adventure!',
  //         );
  //       case 'completed':
  //         return const _EmptyStateCard(
  //           icon: Icons.hourglass_empty_rounded,
  //           title: 'Log is Empty',
  //           subtitle:
  //               'No missions have been completed today. A new legend is waiting to be written.',
  //           showButton:
  //               false, // Tidak perlu tombol tambah misi di tab "Selesai"
  //         );
  //       default:
  //         return const Center(child: Text('No missions found.'));
  //     }
  //   }

  //   final skillGroups = filteredGroupedData.entries.toList();

  //   return ListView.builder(
  //     padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
  //     itemCount: skillGroups.length + 1,
  //     itemBuilder: (context, index) {
  //       if (index == 0) {
  //         return _buildAddMissionCard();
  //       }
  //       final skill = skillGroups[index - 1].key;
  //       final missions = skillGroups[index - 1].value;
  //       return _SkillMissionGroup(skill: skill, missions: missions);
  //     },
  //   );
  // }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Your Quest Log Awaits',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Forge your first mission and begin the adventure to mastery.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              icon: const Icon(Icons.add),
              label: const Text('Forge First Mission'),
              onPressed: () => showCreateMissionAltar(context),
            )
          ],
        ).animate().fadeIn(duration: 600.ms),
      ),
    );
  }
}

// --- WIDGET-WIDGET BARU UNTUK TAMPILAN JURNAL ---

class _SkillMissionGroup extends StatelessWidget {
  final SkillModel skill;
  final List<EnrichedMissionModel> missions;
  final MissionStatus status;

  const _SkillMissionGroup({
    required this.skill,
    required this.missions,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconData(int.parse(skill.icon), fontFamily: 'MaterialIcons'),
                  color: Color(skill.color), size: 20),
              const SizedBox(width: 12),
              Text(skill.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideX(begin: -0.1),
          const Divider(height: 16, thickness: 0.5),
          ...missions
              .map((enriched) => MissionTile(
                    enrichedMission: enriched,
                    status: status,
                  ))
              .toList()
              // Efek staggered (bertingkat) untuk setiap misi dalam grup
              .animate(interval: 100.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

// WIDGET UTAMA BARU: MissionTile
class MissionTile extends StatefulWidget {
  final EnrichedMissionModel enrichedMission;
  final MissionStatus status;

  const MissionTile(
      {super.key, required this.enrichedMission, required this.status});

  @override
  State<MissionTile> createState() => _MissionTileState();
}

class _MissionTileState extends State<MissionTile> {
  final MissionController _missionController = MissionController();
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _completeMission() {
    _confettiController.play();
    _missionController.completeMission(widget.enrichedMission.mission);
  }

  // FUNGSI BARU UNTUK DIALOG RESCHEDULE
  Future<void> _showRescheduleDialog(
      BuildContext context, MissionModel mission) async {
    final now = DateTime.now();

    // 1. Tampilkan DatePicker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null || !context.mounted) return;

    // 2. Tampilkan TimePicker
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );

    if (pickedTime == null) return;

    // 3. Gabungkan dan validasi
    final newDateTime = DateTime(pickedDate.year, pickedDate.month,
        pickedDate.day, pickedTime.hour, pickedTime.minute);

    if (newDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Tidak bisa menjadwalkan ulang ke masa lalu!"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // 4. Panggil controller
    await _missionController.rescheduleMission(mission, newDateTime);
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: <Widget>[
            if (widget.status != MissionStatus.completed)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Misi'),
                onTap: () {
                  Navigator.pop(ctx);
                  // Panggil fungsi untuk menampilkan panel edit
                  showEditMissionPanel(context,
                      enrichedMission: widget.enrichedMission);
                },
              ),
            if (widget.status != MissionStatus.completed)
              ListTile(
                leading: const Icon(Icons.event_repeat_rounded),
                title: const Text('Reschedule'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRescheduleDialog(
                      context, widget.enrichedMission.mission);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
              title: Text('Hapus Misi',
                  style: TextStyle(color: Colors.red.shade700)),
              onTap: () {
                Navigator.pop(ctx);
                _missionController
                    .deleteMission(widget.enrichedMission.mission.id);
              },
            ),
          ],
        );
      },
    );
  }

  // Helper untuk format keterangan waktu
  String _getSubtitle(BuildContext context) {
    final mission = widget.enrichedMission.mission;
    final now = DateTime.now();

    switch (widget.status) {
      case MissionStatus.today:
        return 'Hari ini pukul ${mission.startTime.format(context)}';
      case MissionStatus.upcoming:
        final nextDate = widget.enrichedMission.specificUpcomingDate;
        if (nextDate == null) return "Tidak ada jadwal";

        final difference = nextDate.difference(now);
        if (difference.inHours < 1) {
          return 'Dimulai dalam ${difference.inMinutes} menit lagi';
        }
        if (difference.inHours < 24) {
          return 'Dimulai dalam ${difference.inHours} jam lagi';
        }
        return 'Dimulai dalam ${difference.inDays} hari lagi (${DateFormat.EEEE().format(nextDate)})';
      case MissionStatus.completed:
        // Logika format waktu selesai tidak berubah
        final completedTime = mission.lastCompleted!.toDate();
        if (DateUtils.isSameDay(completedTime, now)) {
          return 'Selesai pada ${DateFormat.Hm().format(completedTime)}';
        }
        if (DateUtils.isSameDay(
            completedTime, now.subtract(const Duration(days: 1)))) {
          return 'Selesai kemarin';
        }
        if (completedTime.isAfter(now.subtract(const Duration(days: 7)))) {
          return 'Selesai pada ${DateFormat.EEEE().format(completedTime)}';
        }
        return 'Selesai pada ${DateFormat.yMd().format(completedTime)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mission = widget.enrichedMission.mission;
    final canBeChecked = widget.status == MissionStatus.today;

    return Stack(alignment: Alignment.center, children: [
      ListTile(
        onLongPress: () => _showOptions(context),
        onTap: () {
          // Navigasi ke detail misi
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MissionDetailPage(enrichedMission: widget.enrichedMission),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        leading: GestureDetector(
          onTap: canBeChecked ? _completeMission : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.status == MissionStatus.completed
                  ? colors.primary
                  : Colors.transparent,
              border: Border.all(
                color: canBeChecked ? colors.primary : Colors.grey,
                width: 2,
              ),
            ),
            child: widget.status == MissionStatus.completed
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        ),
        title: Text(mission.title),
        subtitle: Text(_getSubtitle(context),
            style: TextStyle(color: Colors.grey.shade600)),
        trailing: Text('+${mission.xp} XP',
            style:
                TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
      ),
      Align(
        alignment: Alignment.center,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 15,
          emissionFrequency: 0.02,
          maxBlastForce: 20,
          minBlastForce: 5,
          gravity: 0.2,
          colors: [
            Theme.of(context).colorScheme.primary,
            Color(widget.enrichedMission.skill?.color ?? Colors.amber.value),
            Colors.amber.shade700,
            Colors.white,
          ],
        ),
      ),
    ]);
  }
}

// Widget untuk state kosong per tab
class _EmptyStateCard extends StatelessWidget {
  final MissionStatus status;
  const _EmptyStateCard({required this.status});

  // Helper untuk mendapatkan ikon dan teks yang sesuai
  ({IconData icon, String title, String subtitle, bool showButton})
      _getContent() {
    switch (status) {
      case MissionStatus.today:
        return (
          icon: Icons.nightlight_round,
          title: 'A Quiet Day',
          subtitle:
              'No missions are scheduled for today. Forge a new quest or enjoy your well-deserved peace!',
          showButton: true, // Tampilkan tombol
        );
      case MissionStatus.upcoming:
        return (
          icon: Icons.map_outlined,
          title: 'The Path is Clear',
          subtitle:
              'You have no upcoming missions scheduled for other days. Plan your next adventure!',
          showButton: true, // Tampilkan tombol
        );
      case MissionStatus.completed:
        return (
          icon: Icons.hourglass_empty_rounded,
          title: 'Log is Empty',
          subtitle:
              'No missions have been completed today. A new legend is waiting to be written.',
          showButton: false, // Jangan tampilkan tombol
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _getContent();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(content.icon, size: 80, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            content.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              content.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          // --- PENAMBAHAN LOGIKA TOMBOL ---
          if (content.showButton) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              icon: const Icon(Icons.add),
              label: const Text('Forge a New Mission'),
              onPressed: () => showCreateMissionAltar(context),
            )
          ]
        ],
      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
