import 'package:ecommerece_app/features/shop/widgets/item_details/shining_premium_banner.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/mypage/domain/profile_controller.dart';
import 'package:ecommerece_app/features/mypage/ui/widgets/profile_type.dart';
import 'package:ecommerece_app/features/mypage/ui/widgets/user_info_container.dart';
import 'package:ecommerece_app/features/mypage/ui/widgets/user_options_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPage extends ConsumerStatefulWidget {
  final MyUser currentUser;
  const MyPage({super.key, required this.currentUser});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  late TextEditingController _nicknameController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.currentUser.name);
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(
      text:
          (widget.currentUser.phoneNumber != null &&
                  widget.currentUser.phoneNumber!.isNotEmpty)
              ? widget.currentUser.phoneNumber!
              : '',
    );
  }

  @override
  void didUpdateWidget(MyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser) {
      if (widget.currentUser.name.isNotEmpty) {
        _nicknameController.text = widget.currentUser.name;
      }
      if (widget.currentUser.phoneNumber != null &&
          widget.currentUser.phoneNumber!.isNotEmpty) {
        _phoneController.text = widget.currentUser.phoneNumber!;
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myuser = widget.currentUser;
    final bool isSub = myuser.isSub; 
              padding: EdgeInsets.fromLTRB(12.w, isSub ? 20.h : 0, 12.w, 20.h),
              child: Column(
                children: [
                  ProfileType(
                    isPrivate: myuser.isPrivate,
                    userId: myuser.userId,
                    nicknameController: _nicknameController,
                  ),
                  verticalSpace(20),
                  isSub
                      ? Text('멤버십 회원', style: TextStyles.abeezee17px800wPblack)
                      : Text('일반 회원', style: TextStyles.abeezee17px800wPblack),
                  verticalSpace(20),
                  UserOptionsContainer(isSub: isSub),
                  verticalSpace(20),
                  Text('개인정보', style: TextStyles.abeezee17px800wPblack),
                  verticalSpace(20),
                  UserInfoContainer(
                    currentUser: myuser,
                    passwordController: _passwordController,
                    phoneController: _phoneController,
                  ),
                  verticalSpace(20),
                  WideTextButton(
                    txt: '저장',
                    func: () async {
                      String? currentPassword;
                      if (_passwordController.text.isNotEmpty) {
                        currentPassword = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            final controller = TextEditingController();
                            bool obscure = true;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Text(
                                    '현재 비밀번호 확인',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '안전한 정보 변경을 위해 현재 비밀번호를 입력해 주세요.',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      TextField(
                                        controller: controller,
                                        obscureText: obscure,
                                        decoration: InputDecoration(
                                          hintText: '현재 비밀번호',
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              obscure
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                obscure = !obscure;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        '취소',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(
                                            context,
                                            controller.text,
                                          ),
                                      child: const Text(
                                        '확인',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );

                        if (currentPassword == null ||
                            currentPassword.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '비밀번호 변경이 취소되었습니다',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ),
                            );
                          }
                          return;
                        }
                      }

                      try {
                        await ref
                            .read(profileControllerProvider.notifier)
                            .performUpdate(
                              currentUser: widget.currentUser,
                              newNickname: _nicknameController.text,
                              currentPassword: currentPassword,
                              password: _passwordController.text,
                              phone: _phoneController.text,
                            );
                        if (!context.mounted) return;
                        _passwordController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '업데이트가 성공적으로 완료되었습니다',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        _nicknameController.text = widget.currentUser.name;
                        _phoneController.text =
                            widget.currentUser.phoneNumber ?? '';
                        _passwordController.clear();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        );
                      }
                    },
                    color: Colors.black,
                    txtColor: Colors.white,
                  ),
                  verticalSpace(20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _launchTermsPage();
                        },
                        child: Text(
                          '이용약관',
                          style: TextStyles.abeezee13px400wP600,
                        ),
                      ),
                      horizontalSpace(5),
                      Text('/', style: TextStyles.abeezee13px400wP600),
                      horizontalSpace(5),
                      GestureDetector(
                        onTap: () async {
                          final shouldSignOut = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                title: Text(
                                  '로그아웃 확인',
                                  style: TextStyle(color: Colors.black),
                                ),
                                content: Text(
                                  '정말 로그아웃 하시겠습니까?',
                                  style: TextStyle(color: Colors.black),
                                ),
                                actions: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.black,
                                    ),
                                    onPressed:
                                        () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                    child: Text(
                                      '취소',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.black,
                                    ),
                                    onPressed:
                                        () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                    child: Text(
                                      '로그아웃',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          if (shouldSignOut == true) {
                            await ref
                                .read(profileControllerProvider.notifier)
                                .signOut();
                          }
                        },
                        child: Text(
                          '로그아웃',
                          style: TextStyles.abeezee13px400wP600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _launchTermsPage() async {
  final url = Uri.parse(
    'https://flowery-tub-f11.notion.site/1d938af9230b80fa9d64ce280f6eacbd',
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}
