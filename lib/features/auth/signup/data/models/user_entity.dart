class MyUserEntity {
  String userId;

  String email;

  String name;

  String url;
  List<String>? blocked = [];

  MyUserEntity({
    required this.userId,
    required this.email,
    required this.name,
    required this.url,
    this.blocked,
  });

  Map<String, Object?> toDocument() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'url': url,
      'blocked': blocked,
    };
  }

  static MyUserEntity fromDocument(Map<String, dynamic> doc) {
    return MyUserEntity(
      userId: doc['userId'],
      email: doc['email'],
      name: doc['name'],
      url: doc['url'],
      blocked: doc['blocked'],
    );
  }
}
