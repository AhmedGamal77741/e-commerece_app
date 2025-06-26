class MyUser {
  String userId;
  String email;
  String name;
  String url;
  List<String>? blocked;
  bool isSub;
  String? defaultAddressId;
  String? payerId;
  final bool isOnline;
  final DateTime lastSeen;
  final List<String> chatRooms;
  final List<String> friends; // Added field
  final List<String> friendRequestsSent; // Added field
  final List<String> friendRequestsReceived; // Added field
  final int followerCount;
  final int followingCount;

  MyUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.url,
    this.blocked,
    this.isSub = false,
    this.defaultAddressId,
    this.payerId,
    this.isOnline = false,
    required this.lastSeen,
    this.chatRooms = const [],
    this.friends = const [],
    this.friendRequestsSent = const [],
    this.friendRequestsReceived = const [],
    this.followerCount = 0,
    this.followingCount = 0,
  });

  static final empty = MyUser(
    userId: '',
    email: '',
    name: '',
    url: '',
    blocked: [],
    defaultAddressId: '',
    isSub: false,
    payerId: '',
    isOnline: false,
    lastSeen: DateTime.now(),
    chatRooms: const [],
    friends: const [],
    friendRequestsSent: const [],
    friendRequestsReceived: const [],
    followerCount: 0,
    followingCount: 0,
  );

  // Database serialization methods (from MyUserEntity)
  Map<String, Object?> toDocument() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'url': url,
      'blocked': blocked,
      'isSub': isSub,
      'defaultAddressId': defaultAddressId ?? '',
      'payerId': payerId,
      'isOnline': isOnline,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'chatRooms': chatRooms,
      'friends': friends,
      'friendRequestsSent': friendRequestsSent,
      'friendRequestsReceived': friendRequestsReceived,
      'followerCount': followerCount,
      'followingCount': followingCount,
    };
  }

  static MyUser fromDocument(Map<String, dynamic> doc) {
    return MyUser(
      userId: doc['userId'],
      email: doc['email'],
      name: doc['name'],
      url: doc['url'],
      blocked:
          (doc['blocked'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isSub: doc['isSub'],
      defaultAddressId: doc['defaultAddressId'],
      payerId: doc['payerId'],
      isOnline: doc['isOnline'] ?? false,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(doc['lastSeen'] ?? 0),
      chatRooms: List<String>.from(doc['chatRooms'] ?? []),
      friends: List<String>.from(doc['friends'] ?? []),
      friendRequestsSent: List<String>.from(doc['friendRequestsSent'] ?? []),
      friendRequestsReceived: List<String>.from(
        doc['friendRequestsReceived'] ?? [],
      ),
      followerCount: doc['followerCount'] ?? 0,
      followingCount: doc['followingCount'] ?? 0,
    );
  }

  // Keep these methods for backward compatibility if needed elsewhere
  MyUser toEntity() {
    return this; // Returns itself since it's now the same class
  }

  static MyUser fromEntity(MyUser entity) {
    return entity; // Returns the same instance
  }

  @override
  String toString() {
    return 'MyUser:$userId,$email,$name,$url';
  }
}
