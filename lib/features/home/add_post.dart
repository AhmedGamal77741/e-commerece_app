import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/features/home/widgets/category_management_widgets.dart';
import 'package:ecommerece_app/features/home/widgets/post_text_input.dart';
import 'package:ecommerece_app/features/home/widgets/image_picker_grid.dart';
import 'package:ecommerece_app/features/home/widgets/add_post_bottom_bar.dart';

class AddPost extends ConsumerStatefulWidget {
  const AddPost({super.key});

  @override
  ConsumerState<AddPost> createState() => _AddPostState();
}

class _AddPostState extends ConsumerState<AddPost> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We only need to listen to _textController changes to update the button state
    // We could use a hook, but a simple ListenableBuilder is fine.

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottomNavigationBar: ListenableBuilder(
          listenable: _textController,
          builder: (context, _) {
            return AddPostBottomBar(textController: _textController);
          },
        ),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          titleSpacing: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "오늘의 이야기",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.5.h),
            child: Container(
              color: Theme.of(context).colorScheme.outlineVariant,
              height: 1.5.h,
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                verticalSpace(5),
                const CategoryBanner(),
                const CategoryList(),
                SizedBox(height: 12.h),
                ListenableBuilder(
                  listenable: _textController,
                  builder: (context, _) {
                    return PostTextInput(controller: _textController);
                  },
                ),
                SizedBox(height: 12.h),
                const ImagePickerGrid(),
                SizedBox(height: 120.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
