import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  const UserData({
    required this.uid,
    required this.name,
    required this.image,
    required this.bgndt,
  });

  final String uid;
  final String name;
  final String image;
  final DateTime? bgndt;

  UserData copyWith({
    String? uid,
    String? name,
    String? image,
    DateTime? bgndt,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      image: image ?? this.image,
      bgndt: bgndt ?? this.bgndt,
    );
  }

  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      bgndt:
          data['bgndt'] != null ? (data['bgndt'] as Timestamp).toDate() : null,
    );
  }

  Future<void> update({
    String? name,
    String? image,
  }) async {
    final DocumentReference ref = firestore.collection('users').doc(uid);
    name ??= this.name;
    image ??= this.image;
    await ref.update({
      'name': name,
      'image': image,
      'upddt': FieldValue.serverTimestamp(),
    });
  }
}
