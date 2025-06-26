enum SkillLevel { beginner, amateur, expert, professional }

class SkillModel {
  final String id;
  final String name;
  final String icon;
  final int color;
  SkillLevel level;
  int currentXp;
  int xpForNextLevel;

  SkillModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.level = SkillLevel.beginner,
    this.currentXp = 0,
    this.xpForNextLevel = 100,
  });

  // Method untuk mengubah data menjadi Map, agar bisa disimpan di Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'level': level.index,
      'currentXp': currentXp,
      'xpForNextLevel': xpForNextLevel,
    };
  }

  factory SkillModel.fromMap(Map<String, dynamic> map) {
    return SkillModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? 'default_icon',
      color: map['color'] ?? 0xFFFFFFFF,
      level: SkillLevel.values[map['level'] ?? 0],
      currentXp: map['currentXp'] ?? 0,
      xpForNextLevel: map['xpForNextLevel'] ?? 100,
    );
  }
}
