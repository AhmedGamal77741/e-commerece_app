// payment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ecommerece_app/features/payment/payment_web_view_screen.dart';

class PaymentService {
  final String basePaymentUrl =
      'https://e-commerce-app-34fb2.web.app/payment.html';

  /// Launches the Payple flow and returns true if the subscription succeeded.
  Future<bool> startSubscription(BuildContext context, double amount) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final url = '$basePaymentUrl?amount=${amount.toInt()}&userId=$userId';

    // Push the WebView and await whether it popped true/false
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => PaymentWebView(url: url)));

    return result == true;
  }

  /// (Optional) you can still check your Firestore if needed
  Future<bool> checkActiveSubscription() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final doc =
        await FirebaseFirestore.instance
            .collection('subscriptions')
            .doc(userId)
            .get();

    return doc.exists && doc.data()?['status'] == 'active';
  }
}
