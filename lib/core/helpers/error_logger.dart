import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ErrorLogger {
  /// Logs an image loading error to the Firestore 'client_errors' collection.
  static Future<void> logImageError({
    required String url,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;

      final errorData = {
        'url': url,
        'error': error.toString(),
        'userId': userId,
        'platform': platform,
        'stackTrace': stackTrace?.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (kDebugMode) {
        print('[ErrorLogger] Image failed to load: $url. Error: $error');
      }

      await FirebaseFirestore.instance.collection('client_errors').add({
        'type': 'image_load_failure',
        'details': errorData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('[ErrorLogger] Failed to log error to Firestore: $e');
      }
    }
  }

  /// Logs generic application errors to the Firestore 'client_errors' collection.
  static Future<void> logGeneralError({
    required String message,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    // Ignore harmless Flutter Web engine disposal assertions
    final errStr = error.toString();
    if (errStr.contains('EngineFlutterView') || errStr.contains('!isDisposed')) {
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;

      final errorData = {
        'message': message,
        'error': error.toString(),
        'userId': userId,
        'platform': platform,
        'stackTrace': stackTrace?.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (kDebugMode) {
        print('[ErrorLogger] General error occurred: $message. Error: $error');
      }

      await FirebaseFirestore.instance.collection('client_errors').add({
        'type': 'general_error',
        'details': errorData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('[ErrorLogger] Failed to log general error to Firestore: $e');
      }
    }
  }
}
