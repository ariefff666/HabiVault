import 'package:cloud_firestore/cloud_firestore.dart';

enum SkillLevel { beginner, amateur, expert, professional }

class SkillModel {
  final String id;
  final String name;
  final String icon;
  final int color;
  late final SkillLevel level;
  final int currentXp;
  final int xpForNextLevel;
  final Timestamp createdAt;

  SkillModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.level = SkillLevel.beginner,
    this.currentXp = 0,
    this.xpForNextLevel = 100,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'level': level.index,
      'currentXp': currentXp,
      'xpForNextLevel': xpForNextLevel,
      'createdAt': createdAt,
    };
  }

  factory SkillModel.fromMap(Map<String, dynamic> map) {
    return SkillModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '58269',
      color: map['color'] ?? 0xFF8A63D2,
      level: SkillLevel.values[map['level'] ?? 0],
      currentXp: map['currentXp'] ?? 0,
      xpForNextLevel: map['xpForNextLevel'] ?? 100,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
