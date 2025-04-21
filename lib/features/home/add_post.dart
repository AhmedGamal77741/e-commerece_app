import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart'
    as sp;
import 'package:ecommerece_app/features/home/data/home_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  String imgUrl = "";
  MyUser? currentUser = MyUser(userId: "", email: "", name: "", url: "");
  TextEditingController _textController = TextEditingController();
  bool _isLoading = true;

  void initState() {
    super.initState();

    _loadData(); // Call the async function when widget initializes
  }

  // Async function that uses await
  Future<void> _loadData() async {
    try {
      currentUser = await sp.FirebaseUserRepo().user.first;
      print(currentUser!.userId);
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
    return SafeArea(
      child: Scaffold(
        floatingActionButton: ElevatedButton(
          onPressed: () async {
            if (_textController.text.isEmpty && imgUrl.isEmpty) return;

            try {
              await uploadPost(text: _textController.text, imgUrl: imgUrl);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Success')));
              Navigator.pop(context); // Close after posting
            } catch (e) {
              print(e.toString());

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to post: ${e.toString()}')),
              );
            }
          },

          style: ElevatedButton.styleFrom(
            backgroundColor:
                _textController.text.isEmpty && imgUrl.isEmpty
                    ? ColorsManager.primary200
                    : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Circular edges
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ), // Width/height
            elevation: 0,
          ),
          child: Text("Post", style: TextStyle(color: Colors.white)),
        ),
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false, // Don't show the leading button
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios),
              ),
              Text(
                "Today’s Story",
                style: TextStyle(
                  color: const Color(0xFF121212),
                  fontSize: 16,
                  fontFamily: 'ABeeZee',
                  fontWeight: FontWeight.w400,
                  height: 1.40,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(4.0.h),
            child: Container(color: ColorsManager.primary100, height: 1.0.h),
          ),
        ),
        body:
            _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.black))
                : Column(
                  children: [
                    verticalSpace(20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child: Container(
                            width: 56.w,
                            height: 55.h,
                            decoration: ShapeDecoration(
                              image: DecorationImage(
                                image: NetworkImage(currentUser!.url),
                                fit: BoxFit.cover,
                              ),
                              shape: OvalBorder(),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 15.h,
                            children: [
                              Text(
                                currentUser!.name,
                                style: TextStyles.abeezee16px400wPblack,
                              ),
                              TextField(
                                controller: _textController,
                                onChanged: (value) {
                                  setState(() {}); // Handle text changes
                                },
                                decoration: InputDecoration(
                                  hintText: 'Any Updates?', // Placeholder text
                                  border:
                                      InputBorder.none, // Removes all borders
                                  contentPadding:
                                      EdgeInsets
                                          .zero, // Removes default padding
                                  isDense: true, // Reduces vertical padding
                                  hintStyle: TextStyle(
                                    // Matches your text style
                                    color: const Color(0xFF5F5F5F),
                                    fontSize: 13.sp,
                                    fontFamily: 'ABeeZee',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                style: TextStyle(
                                  color: const Color(0xFF5F5F5F),
                                  fontSize: 13.sp,
                                  fontFamily: 'ABeeZee',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  imgUrl = await uploadImageToImgBB();
                                  setState(() {});
                                },
                                child:
                                    imgUrl.isEmpty
                                        ? ImageIcon(
                                          AssetImage('assets/image_icon.png'),
                                          size: 17.sp,
                                        )
                                        : Image.network(
                                          imgUrl,
                                          height: 272.h,
                                          width: 200.w,
                                          fit: BoxFit.cover,
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }
}
