// lib/services/payment_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Authenticate with Payple
  Future<Map<String, dynamic>> authenticatePayple() async {
    try {
      print('Calling authenticatePayple function');
      final result =
          await _functions.httpsCallable('authenticatePayple').call();
      print('Auth result: ${result.data}');
      return result.data;
    } catch (e) {
      print('Error authenticating with Payple: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get subscription status for current user
  Future<Map<String, dynamic>> getUserSubscription() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return {'active': false, 'error': 'User not logged in'};
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists || !userDoc.data()!.containsKey('subscription')) {
        return {'active': false};
      }

      return {
        'active': userDoc.data()!['subscription']['active'] ?? false,
        'details': userDoc.data()!['subscription'],
      };
    } catch (e) {
      print('Error getting subscription status: $e');
      return {'active': false, 'error': e.toString()};
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return false;
      }

      // Update user subscription status
      await _firestore.collection('users').doc(userId).update({
        'subscription.active': false,
        'subscription.cancelledAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  // Listen to subscription changes
  Stream<Map<String, dynamic>> subscriptionStream() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value({'active': false, 'error': 'User not logged in'});
    }

    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || !snapshot.data()!.containsKey('subscription')) {
        return {'active': false};
      }

      final subscription = snapshot.data()!['subscription'];
      return {
        'active': subscription['active'] ?? false,
        'details': subscription,
      };
    });
  }
}

// Add this to lib/services/payment_service.dart

extension PaymentServiceExtensions on PaymentService {
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('paymentResults')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .limit(10)
              .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }
}
