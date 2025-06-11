import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String name;
  int level;
  int currentXp;
  int xpToNextLevel;
  final Timestamp createdAt;

  Habit({
    required this.id,
    required this.name,
    this.level = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 100, // XP awal untuk naik ke level 2
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'currentXp': currentXp,
      'xpToNextLevel': xpToNextLevel,
      'createdAt': createdAt,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      level: map['level'] ?? 1,
      currentXp: map['currentXp'] ?? 0,
      xpToNextLevel: map['xpToNextLevel'] ?? 100,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
