import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/mypage/data/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});

class ProfileController {
  final Ref _ref;

  ProfileController(this._ref);

  Future<void> deleteAccount({
    required String reason,
  }) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) throw Exception("User not signed in");
    
    await _ref.read(profileRepositoryProvider).softDeleteUser(user.uid, reason);
  }

  Future<void> signOut() async {
    await _ref.read(profileRepositoryProvider).signOut();
  }

  Future<void> reauthenticateUser(String password) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null || user.email == null) throw Exception("User not signed in or missing email");
    
    await _ref.read(profileRepositoryProvider).reauthenticateUser(user.email!, password);
  }

  Future<void> cancelSubscription(String reason) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) throw Exception("User not signed in");
    
    await _ref.read(profileRepositoryProvider).cancelSubscription(user.uid, reason);
  }
}
