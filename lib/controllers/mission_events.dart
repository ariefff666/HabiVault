import 'dart:async';

// Kelas untuk event penyelesaian misi
class MissionCompletedEvent {
  final String missionId;
  final int xpGained;
  final String skillId;

  MissionCompletedEvent({
    required this.missionId,
    required this.xpGained,
    required this.skillId,
  });
}

// StreamController global untuk menyiarkan event
final StreamController<MissionCompletedEvent> missionCompletionBus =
    StreamController.broadcast();
