import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Request Push Notification permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('FCM Permission Status: ${settings.authorizationStatus}');
      }

      // 2. Set foreground presentation options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Register current user's FCM token
      await updateUserToken();

      // 4. Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });

      // 5. Auth state listener to re-sync token on login
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          updateUserToken();
        }
      });

      // 6. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Foreground FCM Message received: ${message.notification?.title}');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  Future<void> updateUserToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching FCM Token: $e');
      }
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token to Firestore: $e');
      }
    }
  }

  /// Create a notification record in Firestore for a recipient
  Future<void> sendInAppNotification({
    required String recipientId,
    required String type, // 'chat', 'post', 'comment'
    required String title,
    required String body,
    String? postId,
    String? commentId,
    String? chatRoomId,
    String? senderId,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (recipientId.isEmpty || recipientId == currentUserId) return;

    try {
      final notifRef = _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .doc();

      final data = <String, dynamic>{
        'id': notifRef.id,
        'type': type,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      if (postId != null) data['postId'] = postId;
      if (commentId != null) data['commentId'] = commentId;
      if (chatRoomId != null) data['chatRoomId'] = chatRoomId;
      if (senderId != null) data['senderId'] = senderId;

      await notifRef.set(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending in-app notification to $recipientId: $e');
      }
    }
  }
}
