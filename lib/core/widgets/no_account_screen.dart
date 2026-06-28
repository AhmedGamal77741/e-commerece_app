import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/mypage/domain/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

class NoBankAccountScreen extends ConsumerStatefulWidget {
  final String source; // 'shop', 'sub', or 'signup'
  // Skip button only appears for 'shop' — other sources use the back arrow
  const NoBankAccountScreen({super.key, this.source = 'shop'});

  @override
  ConsumerState<NoBankAccountScreen> createState() => _NoBankAccountScreenState();
}

class _NoBankAccountScreenState extends ConsumerState<NoBankAccountScreen> {
  bool _isLaunching = false;

  Future<void> _launchBankRegistration() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid.isEmpty) return;

    String phoneNo = '';
    try {
      final cache = await ref.read(profileControllerProvider.notifier).getReceiptData();
      phoneNo = (cache?['phone'] as String?) ?? '';
    } catch (_) {}

    final uri = Uri.parse(
      'https://pay.pang2chocolate.com/web-payment.html'
      '?userId=${Uri.encodeComponent(uid)}'
      '&phoneNo=${Uri.encodeComponent(phoneNo)}'
      '&source=${Uri.encodeComponent(widget.source)}',
    );

    setState(() => _isLaunching = true);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  // Skip is only meaningful for 'shop' — user is being gated from something
  // they want. For 'signup' and 'sub', back arrow is the natural exit.
  bool get _canSkip => widget.source == 'shop';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: const Center(
        child: Text(
          '계좌 등록 후 이용가능합니다',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Register bank account button ──────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: TextButton(
                  onPressed: _isLaunching ? null : _launchBankRegistration,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child:
                      _isLaunching
                          ? const SizedBox.shrink()
                          : Text(
                            '계좌 등록하기',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18.sp,
                              fontFamily: 'NotoSans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),

              // ── Skip button — only shown for 'shop' source ───────────
              if (_canSkip) ...[
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: TextButton(
                    // Pops true → NavBar sees the skip and lets user into shop
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text(
                      '나중에 등록하기',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 15.sp,
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white60,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
