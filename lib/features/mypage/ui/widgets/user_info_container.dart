import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:ecommerece_app/features/home/data/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class UserInfoContainer extends StatefulWidget {
  UserInfoContainer({super.key});

  @override
  State<UserInfoContainer> createState() => _UserInfoContainerState();
}

class _UserInfoContainerState extends State<UserInfoContainer> {
  final passwordController = TextEditingController();

  final nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  IconData iconPassword = Icons.visibility;
  bool obscurePassword = true;
  bool signUpRequired = false;
  String imgUrl = "";
  String error = '';
  final fireBaseRepo = FirebaseUserRepo();

  MyUser? currentUser = MyUser(userId: "", email: "", name: "", url: "");
  bool liked = false;
  bool _isLoading = true;

  void initState() {
    super.initState();
    Provider.of<PostsProvider>(context, listen: false).startListening();

    _loadData(); // Call the async function when widget initializes
  }

  // Async function that uses await
  Future<void> _loadData() async {
    try {
      currentUser = await FirebaseUserRepo().user.first;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print(e);
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: ColorsManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: ColorsManager.primary100),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('닉네임', style: TextStyles.abeezee16px400wPblack),
                  Spacer(),
                  InkWell(
                    onTap: () async {
                      imgUrl = await uploadImageToImgBB();
                      setState(() {});
                    },
                    child:
                        _isLoading
                            ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            )
                            : ClipOval(
                              child: Image.network(
                                imgUrl.isEmpty ? currentUser!.url : imgUrl,
                                height: 55.h,
                                width: 56.w,
                                fit: BoxFit.cover, // Ensures proper filling
                              ),
                            ),
                  ),
                ],
              ),
              UnderlineTextField(
                controller: nameController,
                hintText: '팽이마켓',
                obscureText: false,
                keyboardType: TextInputType.name,
                validator: (val) {
                  if (val!.isEmpty) {
                    return '이 필드를 입력해 주세요';
                  } else if (val.length > 30) {
                    return '이름이 너무 깁니다';
                  }
                  return null;
                },
              ),
              verticalSpace(20),
              /*               Text('사용자 ID', style: TextStyles.abeezee16px400wPblack),
              UnderlineTextField(
                controller: nameController,
                hintText: '이름',
                obscureText: false,
                keyboardType: TextInputType.name,
                validator: (val) {
                  if (val!.isEmpty) {
                    return '이 필드를 입력해 주세요';
                  } else if (val.length > 30) {
                    return 'Name too long';
                  }
                  return null;
                },
              ),
              verticalSpace(20), */
              Text('비밀번호', style: TextStyles.abeezee16px400wPblack),
              Row(
                children: [
                  Spacer(),
                  BlackTextButton(
                    txt: '완료',
                    func: () async {
                      if (_formKey.currentState!.validate()) {
                        MyUser myUser = MyUser.empty;
                        myUser.email = currentUser!.email;
                        myUser.name = nameController.text;
                        myUser.url = imgUrl;
                        var result = await fireBaseRepo.updateUser(
                          myUser,
                          passwordController.text,
                        );
                        if (result == null) {
                          setState(() {
                            error = "이미 사용 중인 이메일입니다";
                          });
                        }
                      }
                    },
                    style: TextStyles.abeezee14px400wW,
                  ),
                ],
              ),
              UnderlineTextField(
                controller: passwordController,
                hintText: '영문,숫자 조합',
                obscureText: false,
                keyboardType: TextInputType.name,
                validator: (val) {
                  if (val!.isEmpty) {
                    return '이 필드를 작성해 주세요';
                  } else if (!RegExp(
                    r'^(?=.*[A-Za-z])(?=.*\d).{8,}$',
                  ).hasMatch(val)) {
                    return '유효한 비밀번호를 입력해 주세요';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
