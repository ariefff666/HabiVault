import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MissionDifficulty { easy, medium, hard }

class MissionModel {
  final String id;
  final String title;
  final String skillId;
  final int xp;
  final List<int> scheduleDays;
  final TimeOfDay startTime;
  final Duration? duration;
  final String? notes;
  final Timestamp createdAt;
  Timestamp? lastCompleted;
  final bool isRescheduled;
  final Timestamp? originalScheduledDate;

  MissionModel({
    required this.id,
    required this.title,
    required this.skillId,
    required this.xp,
    required this.scheduleDays,
    required this.startTime,
    this.duration,
    this.notes,
    required this.createdAt,
    this.lastCompleted,
    this.isRescheduled = false,
    this.originalScheduledDate,
  });

  // int get xp {
  //   switch (difficulty) {
  //     case MissionDifficulty.easy:
  //       return 25;
  //     case MissionDifficulty.medium:
  //       return 50;
  //     case MissionDifficulty.hard:
  //       return 75;
  //   }
  // }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'skillId': skillId,
      'xp': xp,
      'scheduleDays': scheduleDays,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'durationInMinutes': duration?.inMinutes,
      'notes': notes,
      'createdAt': createdAt,
      'lastCompleted': lastCompleted,
      'isRescheduled': isRescheduled,
      'originalScheduledDate': originalScheduledDate,
    };
  }

  factory MissionModel.fromMap(Map<String, dynamic> map) {
    final timeParts = (map['startTime'] as String? ?? '0:0').split(':');
    final durationInMinutes = map['durationInMinutes'] as int?;

    return MissionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      skillId: map['skillId'] ?? '',
      xp: map['xp'] ?? 25,
      scheduleDays: List<int>.from(map['scheduleDays'] ?? []),
      startTime: TimeOfDay(
          hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      duration: durationInMinutes != null
          ? Duration(minutes: durationInMinutes)
          : null,
      notes: map['notes'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      lastCompleted: map['lastCompleted'],
      isRescheduled: map['isRescheduled'] ?? false,
      originalScheduledDate: map['originalScheduledDate'],
    );
  }
}
