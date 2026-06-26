import 'package:ecommerece_app/core/helpers/firebase_auth_error_messages.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/auth/data/auth_repository.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// StreamProvider that listens to Firebase Auth state and fetches the user document.
final currentUserProvider = StreamProvider<MyUser?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    yield null;
  } else {
    final authRepo = ref.watch(authRepositoryProvider);
    final docStream = authRepo.usersCollection.doc(user.uid).snapshots();
    
    await for (final snapshot in docStream) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        yield MyUser.fromDocument(data);
      } else {
        yield null;
      }
    }
  }
});

/// Provider for user subscription status.
final isSubscribedProvider = Provider<AsyncValue<bool>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.whenData((user) => user?.isSub ?? false);
});

final getUserByIdProvider = FutureProvider.family<MyUser, String>((ref, userId) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final doc = await authRepo.usersCollection.doc(userId).get();
  if (doc.exists && doc.data() != null) {
    return MyUser.fromDocument(doc.data() as Map<String, dynamic>);
  }
  return MyUser.empty;
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(authRepository: ref.watch(authRepositoryProvider));
});

class AuthController {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Sign in and return an error message if failed, null if success.
  Future<String?> signIn(String email, String password) async {
    try {
      await _authRepository.signIn(email, password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return getFriendlyAuthError(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  /// Sign up and return an error message if failed, null if success.
  Future<String?> signUp(MyUser myUser, String password, XFile? image) async {
    try {
      // 1. Check uniqueness
      if (await _authRepository.isNicknameTaken(myUser.name)) {
        return "userId가 이미 사용 중입니다.";
      }
      if (myUser.phoneNumber != null && await _authRepository.isPhoneNumberTaken(myUser.phoneNumber!)) {
        return "전화번호가 이미 사용 중입니다.";
      }

      // 2. Create Auth User
      final userCredential = await _authRepository.signUpWithEmail(myUser.email, password);
      myUser.userId = userCredential.user!.uid;

      // 3. Upload Image if exists
      if (image != null) {
        final imageUrl = await _authRepository.uploadProfileImage(image, myUser.userId);
        myUser.url = imageUrl;
      }

      // 4. Save to Firestore
      await _authRepository.saveUserToFirestore(myUser);

      // 5. Update Auth Profile
      await _authRepository.updateAuthProfile(
        displayName: myUser.name,
        photoUrl: myUser.url,
      );

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "이미 사용 중인 이메일입니다";
      } else if (e.code == 'weak-password') {
        return "비밀번호가 너무 약합니다";
      }
      return "알 수 없는 오류가 발생했습니다";
    } catch (e) {
      return "알 수 없는 오류가 발생했습니다";
    }
  }

  /// Send password reset email
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _authRepository.sendPasswordReset(email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return getFriendlyAuthError(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  /// Update user profile
  Future<void> updateUser(MyUser myUser, String password) async {
    await _authRepository.updateUserInFirestore(myUser);
    
    // Check if name changed to update Auth profile
    await _authRepository.updateAuthProfile(displayName: myUser.name);

    if (password.isNotEmpty) {
      try {
        await _authRepository.updatePassword(password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception('비밀번호 업데이트를 위해 다시 로그인해 주세요');
        }
        rethrow;
      }
    }
  }
}
