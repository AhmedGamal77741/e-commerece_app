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
import 'package:ecommerece_app/features/address/domain/models/address.dart';
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
            name: 'bankRegisteredScreen',
            path: Routes.bankRegisteredScreen,
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
            pageBuilder: (context, state) {
              final postId = state.uri.queryParameters['postId'] ?? '';
              final commentId = state.uri.queryParameters['commentId'];
              return CustomTransitionPage(
                key: state.pageKey,
                opaque: false,
                barrierDismissible: true,
                barrierColor: Colors.black54,
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                    ),
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 48),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Comments(postId: postId, commentId: commentId),
                  ),
                ),
              );
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
              final extra = state.extra as Map<String, dynamic>?;
              final productIdQuery = state.uri.queryParameters['productId'];
              if (extra != null && extra['product'] != null) {
                final product = extra['product'] as Product;
                RouteStateCache.product = product;
                RouteStateCache.arrivalDay = extra['arrivalDay'] as String?;
                RouteStateCache.isSub = extra['isSub'] as bool?;
                return ItemDetails(
                  product: product,
                  arrivalDay: extra['arrivalDay'] as String? ?? product.arrivalDate ?? '',
                  isSub: extra['isSub'] as bool? ?? false,
                );
              }
              final cachedProduct = RouteStateCache.product;
              if (cachedProduct != null) {
                return ItemDetails(
                  product: cachedProduct,
                  arrivalDay: RouteStateCache.arrivalDay ?? '',
                  isSub: RouteStateCache.isSub ?? false,
                );
              }
              if (productIdQuery != null && productIdQuery.isNotEmpty) {
                return _buildProductFromId(productIdQuery);
              }
              return const NavBar();
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
              return AddAddressScreen(
                showSkip: extra?['showSkip'] ?? false,
                initialAddress: extra?['address'] as Address?,
              );
            },
          ),
          GoRoute(
            name: Routes.trackorder,
            path: Routes.trackorder,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              if (extra != null && extra['order'] != null) {
                RouteStateCache.order = extra['order'];
                RouteStateCache.arrivalDate = extra['arrivalDate'] as String?;
              }
              final order = RouteStateCache.order;
              if (order == null) {
                return const NavBar();
              }
              return TrackOrder(
                order: order,
                arrivalDate: RouteStateCache.arrivalDate ?? '',
              );
            },
          ),
          GoRoute(
            name: Routes.exchangeOrRefund,
            path: Routes.exchangeOrRefund,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              if (extra != null && extra['userId'] != null) {
                RouteStateCache.userId = extra['userId'] as String?;
                RouteStateCache.orderId = extra['orderId'] as String?;
              }
              final userId = RouteStateCache.userId;
              if (userId == null) {
                return const NavBar();
              }
              return ExchangeOrRefund(
                userId: userId,
                orderId: RouteStateCache.orderId ?? '',
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
          final productId = state.pathParameters['productId'] ??
              state.uri.queryParameters['productId'] ??
              '';
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null && extra['product'] != null) {
            final product = extra['product'] as Product;
            RouteStateCache.product = product;
            RouteStateCache.arrivalDay = extra['arrivalDay'] as String?;
            RouteStateCache.isSub = extra['isSub'] as bool?;
            return ItemDetails(
              product: product,
              arrivalDay: extra['arrivalDay'] as String? ?? product.arrivalDate ?? '',
              isSub: extra['isSub'] as bool? ?? false,
            );
          }
          if (productId.isEmpty) {
            return const NavBar();
          }
          return _buildProductFromId(productId);
        },
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(child: Text('No route defined for ${state.uri.path}')),
        ),
  );
}

Widget _buildProductFromId(String productId) {
  return FutureBuilder<DocumentSnapshot>(
    future:
        FirebaseFirestore.instance.collection('products').doc(productId).get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
        );
      }
      if (!snapshot.hasData ||
          snapshot.data == null ||
          !snapshot.data!.exists ||
          snapshot.data!.data() == null) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (GoRouter.of(context).canPop()) {
                  GoRouter.of(context).pop();
                } else {
                  GoRouter.of(context).go(Routes.navBar);
                }
              },
            ),
          ),
          body: const Center(child: Text('상품을 찾을 수 없습니다.')),
        );
      }
      try {
        final productDoc = snapshot.data!;
        final productMap =
            Map<String, dynamic>.from(productDoc.data() as Map);
        productMap['product_id'] = productDoc.id;
        productMap['id'] = productDoc.id;
        final product = Product.fromMap(productMap);
        RouteStateCache.product = product;

        return ItemDetails(
          product: product,
          arrivalDay: productMap['arrivalDay'] ?? product.arrivalDate ?? '',
          isSub: false,
        );
      } catch (e, stack) {
        debugPrint('Error parsing product from deep link ($productId): $e\n$stack');
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (GoRouter.of(context).canPop()) {
                  GoRouter.of(context).pop();
                } else {
                  GoRouter.of(context).go(Routes.navBar);
                }
              },
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('상품 정보를 불러오는 중 오류가 발생했습니다.\n($e)'),
            ),
          ),
        );
      }
    },
  );
}

class RouteStateCache {
  static Product? product;
  static String? arrivalDay;
  static bool? isSub;

  static dynamic order;
  static String? arrivalDate;

  static String? userId;
  static String? orderId;
}
