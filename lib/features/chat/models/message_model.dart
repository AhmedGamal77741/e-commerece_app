// models/message_model.dart
class MessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String content;
  final String type; // 'text', 'image', 'file'
  final DateTime timestamp;
  final List<String> readBy;
  final String? replyToMessageId;
  final bool isEdited;
  final List<String> lovedBy;

  MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = 'text',
    required this.timestamp,
    this.readBy = const [],
    this.replyToMessageId,
    this.isEdited = false,
    this.lovedBy = const [],
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      readBy: List<String>.from(map['readBy'] ?? []),
      replyToMessageId: map['replyToMessageId'],
      isEdited: map['isEdited'] ?? false,
      lovedBy: List<String>.from(map['lovedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'readBy': readBy,
      'replyToMessageId': replyToMessageId,
      'isEdited': isEdited,
      'lovedBy': lovedBy,
    };
  }
}
