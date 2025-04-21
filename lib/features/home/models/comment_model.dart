import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String text;
  final Timestamp createdAt;
  final int likes;
  final String? userImage;
  final String? userName;
  final List<String> likedBy;

  Comment({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.userImage,
    this.userName,
    this.likedBy = const [],
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likes: data['likes'] ?? 0,
      userImage: data['userImage'],
      userName: data['userName'],
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'createdAt': createdAt,
      'likes': likes,
      'userImage': userImage,
      'userName': userName,
      'likedBy': likedBy,
    };
  }
}
