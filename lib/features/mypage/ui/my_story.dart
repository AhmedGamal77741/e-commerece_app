import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:ecommerece_app/features/home/data/post_provider.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MyStory extends StatefulWidget {
  const MyStory({super.key});

  @override
  State<MyStory> createState() => _MyStoryState();
}

class _MyStoryState extends State<MyStory> {
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
    return _isLoading
        ? Center(child: CircularProgressIndicator(color: Colors.black))
        : Selector<PostsProvider, List<String>>(
          selector: (_, provider) => provider.postIds,
          builder: (context, postIds, child) {
            if (postIds.isEmpty) {
              return Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
              itemCount: postIds.length,
              itemBuilder: (context, index) {
                final postId = postIds[index];
                final postData = Provider.of<PostsProvider>(
                  context,
                  listen: false,
                ).getPost(postId);
                if (postData!['userId'] != currentUser!.userId) {
                  return SizedBox.shrink();
                }
                return Column(
                  children: [
                    if (index != 0) Divider(color: ColorsManager.primary100),
                    PostItem(postId: postId, fromComments: false),
                  ],
                );
              },
            );
          },
        );
  }
}
