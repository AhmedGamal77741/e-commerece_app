import 'package:ecommerece_app/features/auth/signup/data/models/user_entity.dart';

class MyUser {
  String userId;

  String email;

  String name;

  String url;
  MyUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.url,
  });

  static final empty = MyUser(userId: '', email: '', name: '', url: '');

  MyUserEntity toEntity() {
    return MyUserEntity(userId: userId, email: email, name: name, url: url);
  }

  static MyUser fromEntity(MyUserEntity entity) {
    return MyUser(
      userId: entity.userId,
      email: entity.email,
      name: entity.name,
      url: entity.url,
    );
  }

  @override
  String toString() {
    return 'MyUser:$userId,$email,$name,$url';
  }
}
