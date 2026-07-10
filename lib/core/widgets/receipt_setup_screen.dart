// ignore_for_file: unused_element, unused_field, unused_local_variable
import 'package:ecommerece_app/features/mypage/domain/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';

class ReceiptSetupScreen extends ConsumerStatefulWidget {
  final String source; // 'shop' or 'sub'
  const ReceiptSetupScreen({super.key, this.source = 'shop'});

  @override
  ConsumerState<ReceiptSetupScreen> createState() => _ReceiptSetupScreenState();
}

class _ReceiptSetupScreenState extends ConsumerState<ReceiptSetupScreen> {
  // ── Receipt / invoice fields ──────────────────────────────────────────────
  final emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCachedValues();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // ── Pre-fill from cache if anything exists ────────────────────────────────
  Future<void> _loadCachedValues() async {
    final data =
        await ref.read(profileControllerProvider.notifier).getReceiptData();
    if (data == null || !mounted) return;
    setState(() {
      emailController.text = data['email'] ?? '';
    });
  }

  // ── Save to usercached_values ─────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(profileControllerProvider.notifier).saveReceiptData({
        'email': emailController.text.trim(),
        'selectedOption': 1,
      });

      if (mounted) {
        // Return true so the caller knows setup is complete
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: Text(
          '현금영수증 등록',
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info text ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '결제 및 구독을 이용하려면\n현금영수증 수령 이메일을 먼저 등록해주세요.',
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24.h),

              UnderlineTextField(
                controller: emailController,
                hintText: '이메일',
                obscureText: false,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return '이메일을 입력해주세요';
                  if (!RegExp(r'^.+@.+\..+$').hasMatch(val.trim())) {
                    return '유효한 이메일을 입력해주세요';
                  }
                  return null;
                },
                onChanged: (_) => null,
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Save button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: TextButton(
                  onPressed: _isSaving ? null : _save,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child:
                      _isSaving
                          ? const SizedBox.shrink()
                          : Text(
                            '저장하고 계속하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontFamily: 'NotoSans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),

              // ── Skip button — only for 'shop' source ─────────────────
              if (widget.source == 'shop') ...[
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: TextButton(
                    // Pops 'skip' → NavBar lets user into shop without saving
                    onPressed: () => Navigator.of(context).pop('skip'),
                    style: TextButton.styleFrom(foregroundColor: Colors.black),
                    child: Text(
                      '나중에 등록하기',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15.sp,
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.black54,
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
