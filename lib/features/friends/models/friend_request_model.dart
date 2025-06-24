// models/friend_request_model.dart
class FriendRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderProfileImage;
  final String receiverId;
  final String receiverName;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderProfileImage,
    required this.receiverId,
    required this.receiverName,
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
  });

  factory FriendRequestModel.fromMap(Map<String, dynamic> map) {
    return FriendRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderProfileImage: map['senderProfileImage'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      respondedAt:
          map['respondedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['respondedAt'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileImage': senderProfileImage,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
    };
  }
}
