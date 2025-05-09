import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> reauthenticateAndDeleteUser({
  required String email,
  required String password,
}) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final user = auth.currentUser;

  if (user == null) {
    throw Exception("No user is currently signed in.");
  }

  try {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    await firestore.collection('users').doc(user.uid).delete();
    await user.delete();
    print('User deleted successfully.');
  } on FirebaseAuthException catch (e) {
    throw Exception(e.message);
  }
}

Future<void> signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    print("User signed out successfully.");
  } catch (e) {
    print("Error signing out: $e");
    // Optionally, show a dialog or snackbar with error message
  }
}
