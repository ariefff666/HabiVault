import 'package:habi_vault/models/mission_model.dart';
import 'package:habi_vault/models/skill_model.dart';

// Class ini hanya untuk menggabungkan data misi dan skill di dalam UI
class EnrichedMissionModel {
  final MissionModel mission;
  final SkillModel? skill;
  final DateTime? specificUpcomingDate;

  EnrichedMissionModel(
      {required this.mission, this.skill, this.specificUpcomingDate});
}
