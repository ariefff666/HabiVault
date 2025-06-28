// ignore_for_file: deprecated_member_use

// import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:habi_vault/controllers/mission_controller.dart';
// import 'package:habi_vault/controllers/mission_events.dart';
import 'package:habi_vault/models/enriched_mission_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MissionCard extends StatelessWidget {
  final EnrichedMissionModel enrichedMission;
  final VoidCallback onCompleted;
  final bool isCompleted;
  final Animation<double> animation;

  const MissionCard({
    super.key,
    required this.enrichedMission,
    required this.onCompleted,
    required this.isCompleted,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final skillColor = enrichedMission.skill != null
        ? Color(enrichedMission.skill!.color)
        : colors.primary;

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: isCompleted ? 0.6 : 1.0,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isCompleted ? 0 : 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color:
                isCompleted ? colors.surface.withOpacity(0.5) : colors.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  // Checkbox Kustom dengan animasi
                  GestureDetector(
                    onTap: isCompleted ? null : onCompleted,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isCompleted ? colors.primary : Colors.transparent,
                        border: Border.all(
                          color: isCompleted ? Colors.transparent : skillColor,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              .animate()
                              .scale(duration: 300.ms, curve: Curves.elasticOut)
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
                          enrichedMission.mission.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        if (enrichedMission.skill != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                  IconData(
                                      int.parse(enrichedMission.skill!.icon),
                                      fontFamily: 'MaterialIcons'),
                                  size: 14,
                                  color: skillColor.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Text(
                                enrichedMission.skill!.name,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: skillColor.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // XP Gain
                  Text(
                    '+${enrichedMission.mission.xp} XP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? Theme.of(context).disabledColor
                          : colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
