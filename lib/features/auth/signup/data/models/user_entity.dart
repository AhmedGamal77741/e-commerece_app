class MyUserEntity {
  String userId;

  String email;

  String name;

  String url;
  List<String>? blocked = [];
  bool isSub;
  MyUserEntity({
    required this.userId,
    required this.email,
    required this.name,
    required this.url,
    this.blocked,
    this.isSub = false,
  });

  Map<String, Object?> toDocument() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'url': url,
      'blocked': blocked,
      'isSub': isSub,
    };
  }

  static MyUserEntity fromDocument(Map<String, dynamic> doc) {
    return MyUserEntity(
      userId: doc['userId'],
      email: doc['email'],
      name: doc['name'],
      url: doc['url'],
      blocked: doc['blocked'],
      isSub: doc['isSub'],
    );
  }
}
