// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Enum untuk Tier
enum SkillTier { beginner, amateur, expert, professional }

class SkillModel {
  final String id;
  final String name;
  final String icon;
  final int color;
  final int level;
  final int currentXp;
  final int xpForNextLevel;
  final Timestamp createdAt;

  SkillModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.level = 1,
    this.currentXp = 0,
    this.xpForNextLevel = 150,
    required this.createdAt,
  });

  // --- GETTER UNTUK TIER ---
  SkillTier get tier {
    if (level >= 30) return SkillTier.professional;
    if (level >= 20) return SkillTier.expert;
    if (level >= 10) return SkillTier.amateur;
    return SkillTier.beginner;
  }

  // --- GETTER UNTUK NAMA TIER ---
  String get tierName {
    switch (tier) {
      case SkillTier.amateur:
        return 'Amateur';
      case SkillTier.expert:
        return 'Expert';
      case SkillTier.professional:
        return 'Professional';
      case SkillTier.beginner:
        return 'Beginner';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'level': level,
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
      level: map['level'] ?? 1,
      currentXp: map['currentXp'] ?? 0,
      xpForNextLevel: map['xpForNextLevel'] ?? 150,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  factory SkillModel.empty() {
    // Ini adalah skill "kosong" sebagai fallback
    return SkillModel(
      id: '',
      name: 'Uncategorized',
      icon: '60100', // Codepoint untuk ikon 'help_outline'
      color: Colors.grey.value,
      createdAt: Timestamp.now(),
    );
  }
}
