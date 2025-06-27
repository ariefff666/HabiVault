// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:habi_vault/models/enriched_mission_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MissionCard extends StatelessWidget {
  final EnrichedMissionModel enrichedMission;
  final VoidCallback onCompleted;

  const MissionCard(
      {super.key, required this.enrichedMission, required this.onCompleted});

  bool _isCompletedToday() {
    if (enrichedMission.mission.lastCompleted == null) return false;
    final now = DateTime.now();
    final last = enrichedMission.mission.lastCompleted!.toDate();
    return now.year == last.year &&
        now.month == last.month &&
        now.day == last.day;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = _isCompletedToday();
    final colors = Theme.of(context).colorScheme;
    final skillColor = enrichedMission.skill != null
        ? Color(enrichedMission.skill!.color)
        : colors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDone ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDone ? colors.surface.withOpacity(0.5) : colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Checkbox Kustom dengan animasi
            GestureDetector(
              onTap: isDone ? null : onCompleted,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? colors.primary : Colors.transparent,
                  border: Border.all(
                    color: isDone
                        ? Colors.transparent
                        : colors.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                        .animate()
                        .scale(duration: 300.ms, curve: Curves.elasticOut)
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            // Info Misi
            Expanded(
              child: Opacity(
                opacity: isDone ? 0.6 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enrichedMission.mission.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Tampilkan ikon skill yang benar
                        Icon(
                            enrichedMission.skill != null
                                ? IconData(
                                    int.parse(enrichedMission.skill!.icon),
                                    fontFamily: 'MaterialIcons')
                                : Icons.star_rounded,
                            size: 14,
                            color: skillColor.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        // Tampilkan nama skill yang benar
                        Text(
                          enrichedMission.skill?.name ?? 'General',
                          style: TextStyle(
                              fontSize: 12, color: skillColor.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // XP Gain
            Text(
              '+${enrichedMission.mission.xp} XP',
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
