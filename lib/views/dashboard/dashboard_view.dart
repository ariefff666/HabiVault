// ignore_for_file: deprecated_member_use

import 'dart:async';
// import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:habi_vault/controllers/leveling_controller.dart';
import 'package:habi_vault/controllers/mission_events.dart';
import 'package:habi_vault/controllers/skill_controller.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:habi_vault/controllers/user_controller.dart';
import 'package:habi_vault/models/enriched_mission_model.dart';
import 'package:habi_vault/models/skill_model.dart';
import 'package:habi_vault/models/user_model.dart';
import 'package:habi_vault/controllers/mission_controller.dart';
// import 'package:habi_vault/models/mission_model.dart';
import 'package:habi_vault/views/dashboard/mission_card.dart';
import 'package:habi_vault/views/profile/profile_view.dart';
import 'package:habi_vault/views/skills/add_skill_panel.dart';
import 'package:habi_vault/views/skills/skill_detail_page.dart';

enum SkillSortType { level, name, recent }

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ValueNotifier<SkillSortType> _skillSortType =
      ValueNotifier(SkillSortType.level);
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // "Sumber Kebenaran" untuk data, diambil dari stream
  List<EnrichedMissionModel> _sourceMissions = [];
  // Set untuk melacak ID misi yang sudah selesai di sesi ini
  final Set<String> _completedMissionIds = {};

  // Controller dan Stream Subscription
  final UserController _userController = UserController();
  final MissionController _missionController = MissionController();
  final SkillController _skillController = SkillController();
  StreamSubscription? _missionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _listenToMissionUpdates();
  }

  void _listenToMissionUpdates() {
    _missionStreamSubscription?.cancel();
    _missionStreamSubscription = _missionController
        .getEnrichedTodaysMissions()
        .listen((missionsFromStream) {
      if (mounted) {
        setState(() {
          // Selalu perbarui sumber data utama dari stream
          _sourceMissions = missionsFromStream;
          // Perbarui juga set completed Ids berdasarkan data terbaru dari Firestore
          _completedMissionIds.clear();
          for (var mission in _sourceMissions) {
            if (mission.mission.lastCompleted != null &&
                DateUtils.isSameDay(
                    mission.mission.lastCompleted!.toDate(), DateTime.now())) {
              _completedMissionIds.add(mission.mission.id);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _skillSortType.dispose();
    _missionStreamSubscription?.cancel();
    super.dispose();
  }

  void _onMissionCompleted(EnrichedMissionModel missionToComplete) {
    // Cari index visual dari misi yang akan dihapus dari daftar yang BELUM SELESAI
    final sortedList = _getSortedMissions();
    final uncompletedList = sortedList
        .where((m) => !_completedMissionIds.contains(m.mission.id))
        .toList();
    final indexToRemove = uncompletedList
        .indexWhere((m) => m.mission.id == missionToComplete.mission.id);

    if (indexToRemove == -1) {
      return; // Misi tidak ditemukan, jangan lakukan apa-apa
    }

    // 1. Update state secara lokal
    setState(() {
      _completedMissionIds.add(missionToComplete.mission.id);
    });

    // 2. Animasikan penghapusan item dari posisi visualnya saat ini
    _listKey.currentState?.removeItem(
      indexToRemove,
      (context, animation) => MissionCard(
        enrichedMission: missionToComplete,
        onCompleted: () {},
        isCompleted: true, // Render sebagai completed selama animasi hilang
        animation: animation,
      ),
      duration: const Duration(milliseconds: 400),
    );

    // 3. Simpan ke database di latar belakang
    Future.delayed(const Duration(milliseconds: 100), () {
      _missionController.completeMission(missionToComplete.mission);
    });
  }

  // --- HELPER UNTUK MENGURUTKAN DAFTAR ---
  List<EnrichedMissionModel> _getSortedMissions() {
    List<EnrichedMissionModel> sorted = List.from(_sourceMissions);
    sorted.sort((a, b) {
      final aIsDone = _completedMissionIds.contains(a.mission.id);
      final bIsDone = _completedMissionIds.contains(b.mission.id);
      // Pindahkan yang selesai ke bawah
      if (aIsDone != bIsDone) return aIsDone ? 1 : -1;
      // Jika status sama, jaga urutan waktu asli
      final timeA = a.mission.startTime;
      final timeB = b.mission.startTime;
      final aMinutes = timeA.hour * 60 + timeA.minute;
      final bMinutes = timeB.hour * 60 + timeB.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: _userController.getUserData(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final userModel = userSnapshot.data!;

            // Urutkan daftar setiap kali build dipanggil
            final displayedMissions = _getSortedMissions();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              children: [
                _CharacterStatusHeader(userModel: userModel)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2),
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Rune Focus', _buildSkillFilter()),
                const SizedBox(height: 16),
                _buildSkillSummarySection(userModel),
                const SizedBox(height: 32),
                _buildSectionHeader(context, "Today's Missions"),
                const SizedBox(height: 16),
                _buildTodaysMissionsAnimatedList(displayedMissions),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget header section yang bisa menerima widget aksi (filter)
  Widget _buildSectionHeader(BuildContext context, String title,
      [Widget? action]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (action != null) action,
      ],
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1);
  }

  // Widget untuk filter skill
  Widget _buildSkillFilter() {
    return ValueListenableBuilder<SkillSortType>(
        valueListenable: _skillSortType,
        builder: (context, selectedType, child) {
          return Row(
            children: SkillSortType.values.map((type) {
              final isSelected = selectedType == type;
              IconData icon;
              switch (type) {
                case SkillSortType.level:
                  icon = Icons.military_tech;
                  break;
                case SkillSortType.name:
                  icon = Icons.sort_by_alpha;
                  break;
                case SkillSortType.recent:
                  icon = Icons.history;
                  break;
              }
              return Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: IconButton(
                  icon: Icon(icon),
                  iconSize: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  onPressed: () => _skillSortType.value = type,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          );
        });
  }

  // Widget _buildSectionTitle(BuildContext context, String title) {
  //   return Text(
  //     title,
  //     style: Theme.of(context)
  //         .textTheme
  //         .headlineSmall
  //         ?.copyWith(fontWeight: FontWeight.bold),
  //   ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1);
  // }

  // Widget untuk section Rune Focus
  Widget _buildSkillSummarySection(UserModel userModel) {
    return ValueListenableBuilder<SkillSortType>(
        valueListenable: _skillSortType,
        builder: (context, currentSortType, child) {
          return StreamBuilder<List<SkillModel>>(
            stream: _skillController.getSkills(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const _EmptyRuneFocusState();
              }

              final skills = snapshot.data!;
              // Logika pengurutan berdasarkan filter
              skills.sort((a, b) {
                switch (currentSortType) {
                  case SkillSortType.level:
                    return b.level.compareTo(a.level);
                  case SkillSortType.name:
                    return a.name.compareTo(b.name);
                  case SkillSortType.recent:
                    return b.createdAt.compareTo(a.createdAt);
                }
              });

              return SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: skills.length,
                  itemBuilder: (context, index) {
                    return _SkillCarouselCard(
                      skill: skills[index],
                      isFocus: index == 0,
                    );
                  },
                ),
              );
            },
          );
        });
  }

  // Widget untuk section Misi Hari Ini
  Widget _buildTodaysMissionsAnimatedList(List<EnrichedMissionModel> missions) {
    if (missions.isEmpty) {
      return const _EmptyMissionsTodayState();
    }

    return AnimatedList(
      key: _listKey,
      initialItemCount: missions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index, animation) {
        final enrichedMission = missions[index];
        return MissionCard(
          enrichedMission: enrichedMission,
          animation: animation,
          isCompleted:
              _completedMissionIds.contains(enrichedMission.mission.id),
          onCompleted: () => _onMissionCompleted(enrichedMission),
        );
      },
    );
  }
}

// WIDGET UNTUK ZONA 1: HEADER STATUS KARAKTER (HUD)
class _CharacterStatusHeader extends StatefulWidget {
  final UserModel userModel;
  const _CharacterStatusHeader({required this.userModel});

  @override
  State<_CharacterStatusHeader> createState() => __CharacterStatusHeaderState();
}

class __CharacterStatusHeaderState extends State<_CharacterStatusHeader> {
  // State lokal untuk data yang akan dianimasikan
  late int _level;
  late String _title;
  late int _currentXp;
  late int _xpToNextLevel;

  StreamSubscription? _missionCompletionSubscription;
  StreamSubscription? _levelUpSubscription;

  @override
  void initState() {
    super.initState();
    _syncStateWithWidget(widget.userModel);

    // Dengarkan penambahan XP
    _missionCompletionSubscription =
        missionCompletionBus.stream.listen((event) {
      if (mounted) {
        int newXp = _currentXp + event.xpGained;

        // --- LOGIKA LEVEL UP PENGGUNA ---
        if (newXp >= _xpToNextLevel) {
        } else {
          setState(() {
            _currentXp = newXp;
          });
        }
      }
    });

    // Dengarkan jika ada event level up dari LevelingController
    _levelUpSubscription = levelUpBus.stream.listen((event) {
      if (event.isUserLevelUp && mounted) {}
    });
  }

  // Helper untuk sinkronisasi state
  void _syncStateWithWidget(UserModel model) {
    _level = model.level;
    _title = model.title;
    _currentXp = model.xp;
    _xpToNextLevel = model.xpToNextLevel;
  }

  @override
  void didUpdateWidget(covariant _CharacterStatusHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sinkronkan state dengan data baru dari StreamBuilder utama
    if (widget.userModel.level != _level || widget.userModel.xp != _currentXp) {
      setState(() {
        _syncStateWithWidget(widget.userModel);
      });
    }
  }

  @override
  void dispose() {
    _missionCompletionSubscription?.cancel();
    _levelUpSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            // NOTE: Jika ProfileView ada di tab lain, ini perlu state management
            // untuk mengubah tab di MainView. Untuk saat ini, kita push halaman baru.
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileView()));
          },
          child: CircleAvatar(
            radius: 32,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: widget.userModel.photoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.userModel.photoUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading profile image: $error');
                        return _buildFallbackAvatar();
                      },
                    ),
                  )
                : _buildFallbackAvatar(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userModel.name.isNotEmpty
                    ? widget.userModel.name
                    : 'Anonymous User',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Level $_level · $_title', // Gunakan state lokal
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              // --- PANGGIL WIDGET XP BAR DI SINI ---
              _AnimatedXpBar(
                currentXp: _currentXp,
                maxXp: _xpToNextLevel,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '$_currentXp / $_xpToNextLevel XP', // Gunakan state lokal
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

  Widget _buildFallbackAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade300,
            Colors.purple.shade300,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getUserInitial(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getUserInitial() {
    if (widget.userModel.name.isNotEmpty) {
      return widget.userModel.name.substring(0, 1).toUpperCase();
    }
    return 'U'; // Default for "User"
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

class _SkillCarouselCard extends StatefulWidget {
  final SkillModel skill;
  final bool isFocus;
  const _SkillCarouselCard({required this.skill, this.isFocus = false});

  @override
  State<_SkillCarouselCard> createState() => _SkillCarouselCardState();
}

class _SkillCarouselCardState extends State<_SkillCarouselCard> {
  // State lokal untuk data yang akan dianimasikan
  late int _currentXp;
  late int _xpToNextLevel;

  StreamSubscription? _xpSubscription;

  @override
  void initState() {
    super.initState();
    _currentXp = widget.skill.currentXp;
    _xpToNextLevel = widget.skill.xpForNextLevel;

    _xpSubscription = missionCompletionBus.stream.listen((event) {
      if (event.skillId == widget.skill.id && mounted) {
        setState(() {
          _currentXp += event.xpGained;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SkillCarouselCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.skill.currentXp != oldWidget.skill.currentXp ||
        widget.skill.level != oldWidget.skill.level) {
      setState(() {
        _currentXp = widget.skill.currentXp;
        _xpToNextLevel = widget.skill.xpForNextLevel;
      });
    }
  }

  @override
  void dispose() {
    _xpSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _xpToNextLevel > 0 ? _currentXp / _xpToNextLevel : 1.0;
    final skillColor = Color(widget.skill.color);

    return Container(
      width: 150, // Lebar kartu
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [skillColor.withOpacity(0.5), skillColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: widget.isFocus
            ? [
                BoxShadow(
                  color: skillColor.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [],
        border: widget.isFocus
            ? Border.all(color: Colors.white.withOpacity(0.8), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SkillDetailPage(skillId: widget.skill.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                        IconData(int.parse(widget.skill.icon),
                            fontFamily: 'MaterialIcons'),
                        color: Colors.white,
                        size: 24),
                    const SizedBox(width: 8),
                    Text('Lv ${widget.skill.level}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.skill.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                    tween: Tween(end: progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 6,
                        ),
                      );
                    })
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- WIDGET-WIDGET UNTUK EMPTY STATE ---

class _EmptyRuneFocusState extends StatelessWidget {
  const _EmptyRuneFocusState();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.shield_moon_outlined,
                size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Ukir Rune Pertamamu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Ciptakan skill untuk memulai perjalananmu.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => showAddSkillPanel(context),
              child: const Text('Buat Skill'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

class _EmptyMissionsTodayState extends StatelessWidget {
  const _EmptyMissionsTodayState();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: Colors.grey.withOpacity(0.5), style: BorderStyle.solid),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.nightlight_round, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Hari yang Tenang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text(
                'Tidak ada misi yang dijadwalkan untuk hari ini. Nikmati istirahatmu atau buat tantangan baru!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}
