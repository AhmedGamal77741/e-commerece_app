import 'dart:convert';
import 'package:ecommerece_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ecommerece_app/core/routing/app_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print('Handling background FCM message: ${message.messageId}');
  }
}

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'custom_sound_channel',
    'Custom Sound Notifications',
    description: 'Channel for custom sound push notifications',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('custom_sound'),
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 0. Register background messaging handler
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (response) {
            if (response.payload != null && response.payload!.isNotEmpty) {
              try {
                final data =
                    Map<String, dynamic>.from(jsonDecode(response.payload!));
                final message = RemoteMessage(data: data);
                _handleMessageNavigation(message);
              } catch (_) {}
            }
          },
        );

        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImplementation != null) {
          await androidImplementation.createNotificationChannel(_channel);
        }
      }

      // 1. Explicitly request Android runtime notification permission (POST_NOTIFICATIONS)
      if (!kIsWeb) {
        try {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            await Permission.notification.request();
          }
        } catch (e) {
          if (kDebugMode) {
            print('Android notification permission request info: $e');
          }
        }
      }

      // 2. Request Push Notification permissions
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

      // 6. Handle foreground messages with heads-up banner pop-up
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print(
            'Foreground FCM Message received: ${message.notification?.title}',
          );
        }
        if (!kIsWeb) {
          final notification = message.notification;
          if (notification != null) {
            _localNotifications.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  _channel.id,
                  _channel.name,
                  channelDescription: _channel.description,
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  sound:
                      const RawResourceAndroidNotificationSound('custom_sound'),
                  icon: '@mipmap/ic_launcher',
                ),
                iOS: const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                  sound: 'custom_sound.mp3',
                ),
              ),
              payload: jsonEncode(message.data),
            );
          }
        }
      });

      // 7. Handle message when user taps notification from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('FCM Message opened app: ${message.notification?.title}');
        }
        _handleMessageNavigation(message);
      });

      // 8. Handle message when user taps notification while app was terminated
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print(
            'FCM Initial message opened app: ${initialMessage.notification?.title}',
          );
        }
        _handleMessageNavigation(initialMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  Future<void> _handleMessageNavigation(RemoteMessage message) async {
    final data = message.data;
    if (data.isEmpty) return;

    final type = data['type']?.toString();
    final postId = data['postId']?.toString();
    final commentId = data['commentId']?.toString();
    final chatRoomId = data['chatRoomId']?.toString();
    final senderId = data['senderId']?.toString();

    if (kDebugMode) {
      print(
        'Navigating from FCM notification payload: type=$type, postId=$postId, chatRoomId=$chatRoomId',
      );
    }

    // Set root location to Main Feed first so popping target route returns to feed
    AppRouter.router.go(Routes.navBar);

    if (type == 'chat' || (chatRoomId != null && chatRoomId.isNotEmpty)) {
      if (chatRoomId != null && chatRoomId.isNotEmpty) {
        String partnerName = '채팅';
        try {
          final currentUid = _auth.currentUser?.uid;
          final roomDoc =
              await _firestore.collection('chatRooms').doc(chatRoomId).get();
          if (roomDoc.exists && roomDoc.data() != null) {
            final roomData = roomDoc.data()!;
            final roomName = roomData['name'] as String?;
            if (roomName != null && roomName.trim().isNotEmpty) {
              partnerName = roomName;
            } else {
              final participants =
                  List<String>.from(roomData['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != currentUid,
                orElse: () => senderId ?? '',
              );
              if (otherUserId.isNotEmpty) {
                final userDoc =
                    await _firestore.collection('users').doc(otherUserId).get();
                if (userDoc.exists && userDoc.data() != null) {
                  partnerName = userDoc.data()!['name'] ?? '채팅';
                }
              }
            }
          }
        } catch (_) {}

        AppRouter.router.pushNamed(
          Routes.chatScreen,
          pathParameters: {'id': chatRoomId},
          extra: {'name': partnerName},
        );
      }
    } else if (type == 'comment' ||
        type == 'post' ||
        type == 'like' ||
        (postId != null && postId.isNotEmpty)) {
      if (postId != null && postId.isNotEmpty) {
        // 1. Root: SNS Home feed
        AppRouter.router.go(Routes.navBar);
        // 2. Middle: Notifications tab
        AppRouter.router.pushNamed(Routes.alertsScreen);
        // 3. Top: Comment section modal for postId
        final queryParams = <String, String>{
          'postId': postId,
          if (commentId != null && commentId.isNotEmpty) 'commentId': commentId,
        };
        final uri = Uri(path: '/comment', queryParameters: queryParams);
        AppRouter.router.push(uri.toString());
      }
    }
  }

  Future<void> updateUserToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      String? token;
      if (kIsWeb) {
        try {
          token = await _fcm.getToken(
            vapidKey:
                'BMxY_KRLCi-zPnzBt2_zopKfWFHQvBhOkErjM_bKsPjh1KJPZywqsBIlO0xinCqcbOBrqhsplIbUkVUf2tm8weY',
          );
        } catch (e) {
          if (kDebugMode) {
            print('FCM Web token with VAPID key info: $e');
          }
          try {
            token = await _fcm.getToken();
          } catch (fallbackErr) {
            if (kDebugMode) {
              print('FCM Web token fallback info: $fallbackErr');
            }
          }
        }
      } else {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          final apnsToken = await _fcm.getAPNSToken().timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );
          if (apnsToken == null) {
            if (kDebugMode) {
              print('APNs token is not ready or running on iOS Simulator. Skipping FCM getToken.');
            }
            return;
          }
        }
        token = await _fcm.getToken().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
      }

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
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
      final notifRef =
          _firestore
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
