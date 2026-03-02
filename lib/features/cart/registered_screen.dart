import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CardRegisteredScreen
//
// Shown when the OS intercepts app.pang2chocolate.com/card-registered after
// Payple card registration. Reads success/failure from query params and:
//   • success=true  → shows snackbar "카드가 등록되었습니다 ✓"
//                   → navigates back to place-order or buy-now
//   • success=false → shows snackbar with error message
//                   → navigates back to place-order or buy-now
//
// This screen is intentionally minimal — it exists only to catch the deep
// link, show feedback, and get the user back to checkout immediately.
// ─────────────────────────────────────────────────────────────────────────────

class CardRegisteredScreen extends StatefulWidget {
  final bool success;
  final String userId;
  final String paymentId;
  final String message;

  const CardRegisteredScreen({
    super.key,
    required this.success,
    required this.userId,
    required this.paymentId,
    required this.message,
  });

  @override
  State<CardRegisteredScreen> createState() => _CardRegisteredScreenState();
}

class _CardRegisteredScreenState extends State<CardRegisteredScreen> {
  @override
  void initState() {
    super.initState();
    // Show snackbar + navigate after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleResult());
  }

  void _handleResult() {
    if (!mounted) return;

    if (widget.success) {
      // Card registered successfully — show snackbar then go back to checkout
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카드가 등록되었습니다 ✓'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // Registration failed — show error then go back to checkout
      final errorMsg =
          widget.message.isNotEmpty
              ? widget.message
              : '카드 등록에 실패했습니다. 다시 시도해 주세요.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // Navigate back to place-order so user can now pay with the new card.
    // Using go() replaces the stack so user can't back-navigate to this screen.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) context.go(Routes.placeOrderScreen);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Minimal loading screen — user sees this only for ~300ms before redirect
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.success
                ? const Icon(Icons.credit_card, size: 56, color: Colors.black)
                : const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              widget.success ? '카드 등록 완료' : '카드 등록 실패',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: 8),
            const CircularProgressIndicator(color: Colors.black),
          ],
        ),
      ),
    );
  }
}
