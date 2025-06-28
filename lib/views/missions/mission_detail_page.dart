// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:habi_vault/controllers/mission_controller.dart';
import 'package:habi_vault/models/enriched_mission_model.dart';
import 'package:habi_vault/models/mission_model.dart';
import 'package:habi_vault/views/missions/edit_mission_panel.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MissionDetailPage extends StatefulWidget {
  final EnrichedMissionModel enrichedMission;

  const MissionDetailPage({super.key, required this.enrichedMission});

  @override
  State<MissionDetailPage> createState() => _MissionDetailPageState();
}

class _MissionDetailPageState extends State<MissionDetailPage> {
  final MissionController _missionController = MissionController();
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _completeMission() {
    _confettiController.play();
    _missionController.completeMission(widget.enrichedMission.mission);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });
  }

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
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Tidak bisa menjadwalkan ulang ke masa lalu!"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // 4. Panggil controller
    await _missionController.rescheduleMission(mission, newDateTime);
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.enrichedMission.mission;
    final skill = widget.enrichedMission.skill!;
    final colors = Theme.of(context).colorScheme;
    final skillColor = Color(skill.color);

    final bool isCompletedToday = mission.lastCompleted != null &&
        DateUtils.isSameDay(mission.lastCompleted!.toDate(), DateTime.now());
    final bool canBeCompleted = !isCompletedToday &&
        mission.scheduleDays.contains(DateTime.now().weekday);

    return Scaffold(
      body: Stack(
        children: [
          // Latar Belakang Gradien Tematik
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  skillColor.withOpacity(0.4),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
          ),
          // Konten Utama
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Center(
                    child: Icon(
                      IconData(int.parse(skill.icon),
                          fontFamily: 'MaterialIcons'),
                      size: 100,
                      color: skillColor.withOpacity(0.6),
                    ).animate().shimmer(
                        duration: 2.seconds,
                        color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Misi dan XP
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              mission.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Chip(
                            avatar: Icon(Icons.star, color: colors.primary),
                            label: Text('+${mission.xp} XP',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            backgroundColor: colors.primary.withOpacity(0.1),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2),

                      const SizedBox(height: 32),
                      // Kartu Informasi Jadwal
                      _InfoCard(
                        icon: Icons.calendar_today_rounded,
                        title: 'Jadwal Ritual',
                        content: _formatSchedule(mission),
                        iconColor: Colors.orange,
                      ),
                      // Kartu Informasi Durasi
                      if (mission.duration != null)
                        _InfoCard(
                          icon: Icons.hourglass_bottom_rounded,
                          title: 'Alokasi Waktu',
                          content: '${mission.duration!.inMinutes} menit',
                          iconColor: Colors.blue,
                        ),
                      // Kartu Informasi Catatan
                      if (mission.notes != null && mission.notes!.isNotEmpty)
                        _InfoCard(
                          icon: Icons.notes_rounded,
                          title: 'Gulungan Perintah',
                          content: mission.notes!,
                          iconColor: Colors.green,
                        ),
                      const SizedBox(height: 32),
                      _ChronicleLogHeader(),
                      const SizedBox(height: 8),
                      _buildChronicleLog(), // Widget untuk menampilkan log

                      const SizedBox(height: 120), // Spasi untuk FAB
                    ],
                  ),
                ),
              )
            ],
          ),
          // Tombol Aksi di bagian bawah
          if (canBeCompleted) _buildCompleteButton() else _buildActionButtons(),

          // Lapisan Konfeti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              emissionFrequency: 0.03,
              colors: [skillColor, colors.primary, Colors.white],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET UNTUK HEADER LOG ---
  // ignore: non_constant_identifier_names
  Widget _ChronicleLogHeader() {
    return Row(
      children: [
        Icon(Icons.history_edu_rounded,
            color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Text(
          "Gulungan Kronik",
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1);
  }

  // --- WIDGET UNTUK MEMBANGUN LOG ---
  Widget _buildChronicleLog() {
    return StreamBuilder<QuerySnapshot>(
      stream: _missionController
          .getCompletionLogStream(widget.enrichedMission.mission.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _InfoCard(
            icon: Icons.hourglass_empty,
            title: "Belum Ada Riwayat",
            content:
                "Selesaikan misi ini untuk pertama kali dan ukir sejarahmu!",
            iconColor: Colors.grey,
          );
        }

        final logDocs = snapshot.data!.docs;

        return Container(
          constraints: const BoxConstraints(
              maxHeight: 250), // Batasi tinggi agar bisa discroll
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16)),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: logDocs.length,
            itemBuilder: (context, index) {
              final logData = logDocs[index].data() as Map<String, dynamic>;
              final completedAt =
                  (logData['completedAt'] as Timestamp).toDate();

              return _ChronicleLogEntry(
                completedAt: completedAt,
                xpGained: logData['xpGained'],
              );
            },
          ),
        ).animate().fadeIn(delay: 700.ms);
      },
    );
  }

  Widget _buildCompleteButton() {
    return Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _completeMission,
        icon: const Icon(Icons.check_circle_outline, size: 28),
        label: const Text('Selesaikan Misi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      )
          .animate()
          .slideY(begin: 2, duration: 500.ms, curve: Curves.easeOutCubic)
          .scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
        bottom: 30,
        left: 24,
        right: 24,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
                onPressed: () => _showRescheduleDialog(
                    context, widget.enrichedMission.mission),
                icon: const Icon(Icons.event_repeat_rounded),
                label: const Text('Reschedule')),
            OutlinedButton.icon(
                onPressed: () => showEditMissionPanel(context,
                    enrichedMission: widget.enrichedMission),
                icon: const Icon(Icons.edit),
                label: const Text('Edit')),
          ],
        ).animate().fadeIn(delay: 400.ms));
  }

  String _formatSchedule(MissionModel mission) {
    if (mission.scheduleDays.isEmpty) return 'Tidak Dijadwalkan';
    final days = mission.scheduleDays
        .map((day) =>
            DateFormat('E', 'id_ID').format(DateTime(2023, 1, day + 1)))
        .toList()
        .join(', ');
    final time = mission.startTime.format(context);
    return '$days, pukul $time';
  }
}

class _ChronicleLogEntry extends StatelessWidget {
  final DateTime completedAt;
  final int xpGained;

  const _ChronicleLogEntry({required this.completedAt, required this.xpGained});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Ikon penanda waktu
          Icon(Icons.verified_user_outlined,
              color: Colors.green.shade300, size: 20),
          const SizedBox(width: 16),
          // Informasi tanggal dan waktu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMMd('id_ID').format(completedAt),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Pukul ${DateFormat.Hm().format(completedAt)}',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          // Informasi XP
          Text(
            '+$xpGained XP',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Widget kustom untuk kartu informasi
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color iconColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(content,
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2);
  }
}
