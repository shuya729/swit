import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String uid;
  final String tgt;
  final String type;

  const Message({
    required this.id,
    required this.uid,
    required this.tgt,
    required this.type,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      uid: data['uid'],
      tgt: data['tgt'],
      type: data['type'],
    );
  }

  static const request = 'request';
  static const friend = 'friend';
  static const error = 'error';
  static const types = [request, friend];
  bool get isCorrectType => types.contains(type);
  bool get isRequest => type == request;
  bool get isFriend => type == friend;
}
