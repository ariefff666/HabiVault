class UserModel {
  final String uid;
  final String email;
  final String name;
  final String photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.photoUrl,
  });

  // Fungsi untuk mengubah data user menjadi map agar bisa disimpan di Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  // Fungsi untuk membuat objek UserModel dari map yang didapat dari Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
    );
  }
}
