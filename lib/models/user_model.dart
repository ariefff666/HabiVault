class UserModel {
  final String uid;
  final String email;
  final String name;
  final String photoUrl;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final String title;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.photoUrl,
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 100,
    this.title = 'Novice',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'level': level,
      'xp': xp,
      'xpToNextLevel': xpToNextLevel,
      'title': title,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      xpToNextLevel: map['xpToNextLevel'] ?? 100,
      title: map['title'] ?? 'Novice',
    );
  }
}
