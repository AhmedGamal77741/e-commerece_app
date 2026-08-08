import 'dart:async';
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

final getUserByIdProvider = FutureProvider.family<MyUser, String>((
  ref,
  userId,
) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final doc = await authRepo.usersCollection.doc(userId).get();
  if (doc.exists && doc.data() != null) {
    return MyUser.fromDocument(doc.data() as Map<String, dynamic>);
  }
  return MyUser.empty;
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<void> {
  late AuthRepository _authRepository;

  @override
  FutureOr<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await _authRepository.signIn(email, password);
      } on FirebaseAuthException catch (e) {
        throw Exception(getFriendlyAuthError(e.code));
      } catch (e) {
        throw Exception('알 수 없는 오류가 발생했습니다');
      }
    });
  }

  Future<void> signUp(MyUser myUser, String password, XFile? image) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final results = await Future.wait([
          _authRepository.isNicknameTaken(myUser.name),
          if (myUser.phoneNumber != null)
            _authRepository.isPhoneNumberTaken(myUser.phoneNumber!)
          else
            Future.value(false),
        ]);

        if (results[0]) {
          throw Exception("이미 사용 중인 닉네임입니다.");
        }
        if (results[1]) {
          throw Exception("전화번호가 이미 사용 중입니다.");
        }

        final userCredential = await _authRepository.signUpWithEmail(
          myUser.email,
          password,
        );
        myUser.userId = userCredential.user!.uid;

        if (image != null) {
          final imageUrl = await _authRepository.uploadProfileImage(
            image,
            myUser.userId,
          );
          myUser.url = imageUrl;
        }

        await _authRepository.saveUserToFirestore(myUser);

        await _authRepository.updateAuthProfile(
          displayName: myUser.name,
          photoUrl: myUser.url,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw Exception("이미 사용 중인 이메일입니다");
        } else if (e.code == 'weak-password') {
          throw Exception("비밀번호가 너무 약합니다");
        }
        throw Exception("알 수 없는 오류가 발생했습니다: ${e.message}");
      }
    });
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cleanEmail = email.trim();
      if (cleanEmail.isEmpty) {
        throw Exception('이메일을 입력해주세요.');
      }

      final isRegistered = await _authRepository.isEmailRegistered(cleanEmail);
      if (!isRegistered) {
        throw Exception('가입되지 않은 이메일입니다.');
      }

      try {
        await _authRepository.sendPasswordReset(cleanEmail);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          throw Exception('가입되지 않은 이메일입니다.');
        }
        throw Exception(getFriendlyAuthError(e.code));
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('알 수 없는 오류가 발생했습니다');
      }
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> updateUser(MyUser myUser, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _authRepository.updateUserInFirestore(myUser);
      await _authRepository.updateAuthProfile(displayName: myUser.name);

      if (password.isNotEmpty) {
        try {
          await _authRepository.updatePassword(password);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            throw Exception('비밀번호 업데이트를 위해 다시 로그인해 주세요');
          }
          throw Exception('비밀번호 변경 실패');
        }
      }
    });
  }
}
