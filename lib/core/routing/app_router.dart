import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/widgets/subscription_screen.dart';
import 'package:ecommerece_app/core/widgets/no_account_screen.dart';
import 'package:ecommerece_app/core/widgets/receipt_setup_screen.dart';
import 'package:ecommerece_app/features/cart/order_complete.dart';
import 'package:ecommerece_app/features/cart/place_order.dart';
import 'package:ecommerece_app/features/cart/buy_now.dart';
import 'package:ecommerece_app/features/cart/registered_screen.dart';
import 'package:ecommerece_app/features/cart/cart.dart';
import 'package:ecommerece_app/features/address/ui/address_list_screen.dart';
import 'package:ecommerece_app/features/address/ui/add_address_screen.dart';
import 'package:ecommerece_app/features/home/add_post.dart';
import 'package:ecommerece_app/features/home/comments.dart';
import 'package:ecommerece_app/features/home/profile_tab.dart';
import 'package:ecommerece_app/features/chat/ui/edit_screen.dart';
import 'package:ecommerece_app/features/home/notifications.dart';
import 'package:ecommerece_app/features/review/ui/track_order.dart';
import 'package:ecommerece_app/features/review/ui/exchange_or_refund.dart';
import 'package:ecommerece_app/features/home/widgets/alerts.dart';
import 'package:ecommerece_app/features/mypage/ui/cancel_subscription.dart';
import 'package:ecommerece_app/features/mypage/ui/delete_account_screen.dart';
import 'package:ecommerece_app/features/navBar/nav_bar.dart';
import 'package:ecommerece_app/features/review/ui/review_screen.dart';
import 'package:ecommerece_app/features/shop/item_details.dart';
import 'package:ecommerece_app/features/home/search_screen.dart';
import 'package:ecommerece_app/landing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_comments.dart';
import 'package:ecommerece_app/features/chat/ui/chat_room_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: Routes.navBar,
    routes: [
      GoRoute(
        name: 'guestCommentsScreen',
        path: '/guest_comment',
        builder: (context, state) {
          final postId = state.uri.queryParameters['postId'] ?? '';
          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: SizedBox.shrink(),
                );
              }
              if (!snapshot.hasData || snapshot.data?.data() == null) {
                return const Scaffold(
                  body: Center(child: Text('Post not found')),
                );
              }
              final postMap = snapshot.data!.data() as Map<String, dynamic>;
              postMap['postId'] = postId;
              postMap['fromComments'] = true;
              return GuestComments(post: postMap);
            },
          );
        },
      ),

      // ── Bank registered deep link landing ─────────────────────────────────
      // Reached when OS intercepts www.pang2chocolate.com/bank-registered
      // after Payple bank account registration callback redirects here.
      // Top-level route (not nested under navBar) so it works from cold start.
      GoRoute(
        name: 'bankRegisteredScreen',
        path: Routes.bankRegisteredScreen, // '/bank-registered'
        builder: (context, state) {
          final success = state.uri.queryParameters['success'] ?? 'false';
          final userId = state.uri.queryParameters['userId'] ?? '';
          final paymentId = state.uri.queryParameters['paymentId'] ?? '';
          final message = state.uri.queryParameters['message'] ?? '';

          return BankRegisteredScreen(
            success: success == 'true',
            userId: userId,
            paymentId: paymentId,
            message: message,
            source: state.uri.queryParameters['source'] ?? 'shop',
          );
        },
      ),
      GoRoute(
        name: Routes.noBankAccountScreen,
        path: Routes.noBankAccountScreen,
        builder: (context, state) {
          return NoBankAccountScreen(
            source: state.uri.queryParameters['source'] ?? 'shop',
          );
        },
      ),
      GoRoute(
        name: Routes.receiptSetupScreen,
        path: Routes.receiptSetupScreen,
        builder: (context, state) {
          return ReceiptSetupScreen(
            source: state.uri.queryParameters['source'] ?? 'shop',
          );
        },
      ),

      GoRoute(
        name: Routes.navBar,
        path: Routes.navBar,
        builder: (context, state) => const NavBar(),
        routes: [
          GoRoute(
            name: Routes.reviewScreen,
            path: Routes.reviewScreen,
            builder: (context, state) => const ReviewScreen(),
          ),
          GoRoute(
            name: Routes.notificationsScreen,
            path: Routes.notificationsScreen,
            builder: (context, state) => const Notifications(),
          ),
          GoRoute(
            name: Routes.alertsScreen,
            path: Routes.alertsScreen,
            builder: (context, state) => const Alerts(),
          ),
          GoRoute(
            name: Routes.addPostScreen,
            path: Routes.addPostScreen,
            builder: (context, state) => const AddPost(),
          ),
          GoRoute(
            name: Routes.landingScreen,
            path: Routes.landingScreen,
            builder: (context, state) => const LandingScreen(),
          ),
          GoRoute(
            name: Routes.placeOrderScreen,
            path: Routes.placeOrderScreen,
            builder: (context, state) => const PlaceOrder(),
          ),
          GoRoute(
            name: Routes.orderCompleteScreen,
            path: Routes.orderCompleteScreen,
            builder: (context, state) => const OrderComplete(),
          ),
          GoRoute(
            name: Routes.shopSearchScreen,
            path: Routes.shopSearchScreen,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final tabIndex = extra?['initialTabIndex'] ?? 2;
              return HomeSearch(initialTabIndex: tabIndex);
            },
          ),
          GoRoute(
            name: Routes.commentsScreen,
            path: '/${Routes.commentsScreen}',
            builder: (context, state) {
              final postId = state.uri.queryParameters['postId'] ?? '';
              final commentId = state.uri.queryParameters['commentId'];
              return Comments(postId: postId, commentId: commentId);
            },
          ),
          GoRoute(
            name: Routes.chatScreen,
            path: '/chat/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              String name = '고객센터';
              bool isDeleted = false;
              final extra = state.extra;
              if (extra is Map) {
                if (extra['name'] is String &&
                    (extra['name'] as String).isNotEmpty) {
                  name = extra['name'] as String;
                }
                if (extra['isDeleted'] is bool) {
                  isDeleted = extra['isDeleted'] as bool;
                }
              }
              return ChatScreen(
                chatRoomId: id,
                chatRoomName: name,
                isDeleted: isDeleted,
              );
            },
          ),
          GoRoute(
            name: Routes.cancelSubscription,
            path: Routes.cancelSubscription,
            builder: (context, state) => const CancelSubscription(),
          ),
          GoRoute(
            name: Routes.deleteAccount,
            path: Routes.deleteAccount,
            builder: (context, state) => DeleteAccountScreen(),
          ),
          GoRoute(
            name: Routes.buyNowScreen,
            path: Routes.buyNowScreen,
            builder: (context, state) {
              final paymentId = state.uri.queryParameters['paymentId'];
              if (paymentId == null || paymentId.isEmpty) {
                return const Scaffold(
                  body: Center(child: Text('잘못된 접근입니다. (Missing paymentId)')),
                );
              }
              return BuyNow(paymentId: paymentId);
            },
          ),
          GoRoute(
            name: Routes.itemDetailsScreen,
            path: Routes.itemDetailsScreen,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ItemDetails(
                product: extra['product'] as Product,
                arrivalDay: extra['arrivalDay'] as String,
                isSub: extra['isSub'] as bool,
              );
            },
          ),
          GoRoute(
            name: Routes.cartScreen,
            path: Routes.cartScreen,
            builder: (context, state) => const Cart(),
          ),
          GoRoute(
            name: Routes.addressListScreen,
            path: Routes.addressListScreen,
            builder: (context, state) => const AddressListScreen(),
          ),
          GoRoute(
            name: Routes.addAddressScreen,
            path: Routes.addAddressScreen,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddAddressScreen(showSkip: extra?['showSkip'] ?? false);
            },
          ),
          GoRoute(
            name: Routes.trackorder,
            path: Routes.trackorder,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return TrackOrder(
                order: extra['order'],
                arrivalDate: extra['arrivalDate'],
              );
            },
          ),
          GoRoute(
            name: Routes.exchangeOrRefund,
            path: Routes.exchangeOrRefund,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ExchangeOrRefund(
                userId: extra['userId'],
                orderId: extra['orderId'],
              );
            },
          ),
          GoRoute(
            name: Routes.profileTabScreen,
            path: Routes.profileTabScreen,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return Scaffold(body: ProfileTab(userId: extra?['userId'] ?? ''));
            },
          ),
          GoRoute(
            name: Routes.editScreen,
            path: Routes.editScreen,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return EditScreen(initialTab: extra?['initialTab'] ?? 0);
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.subscriptionScreen,
        name: 'subscriptionScreen',
        builder: (context, state) => const SubscriptionScreen(),
      ),

      GoRoute(
        name: 'productDetails',
        path: '/product/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId'] ?? '';
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: SizedBox.shrink(),
                );
              }
              if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                return const Scaffold(
                  body: Center(child: Text('Product not found')),
                );
              }
              final productDoc = snapshot.data!;
              final productMap = productDoc.data() as Map<String, dynamic>;
              final product = Product.fromMap(productMap);

              return ItemDetails(
                product: product,
                arrivalDay: productMap['arrivalDay'] ?? '',
                isSub: false,
              );
            },
          );
        },
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(child: Text('No route defined for ${state.uri.path}')),
        ),
  );
}
