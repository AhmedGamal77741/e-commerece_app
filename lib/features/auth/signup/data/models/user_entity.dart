class MyUserEntity {
  String userId;

  String email;

  String name;

  String url;

  MyUserEntity({
    required this.userId,
    required this.email,
    required this.name,
    required this.url,
  });

  Map<String, Object?> toDocument() {
    return {'userId': userId, 'email': email, 'name': name, 'url': url};
  }

  static MyUserEntity fromDocument(Map<String, dynamic> doc) {
    return MyUserEntity(
      userId: doc['userId'],
      email: doc['email'],
      name: doc['name'],
      url: doc['url'],
    );
  }
}
