import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/core/helpers/image_picker_helper.dart';
import 'package:ecommerece_app/core/helpers/loading_dialog.dart';
import 'package:ecommerece_app/features/home/domain/add_post_notifier.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:go_router/go_router.dart';

class AddPostBottomBar extends ConsumerWidget {
  final TextEditingController textController;

  const AddPostBottomBar({
    super.key,
    required this.textController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPostNotifierProvider);

    final isPublishDisabled = (textController.text.isEmpty && state.images.isEmpty) ||
        state.images.any((img) => img.isUploading);

    return Padding(
      padding: EdgeInsets.only(
        top: 20.h,
        left: 20.w,
        right: 20.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () async {
              final pickedFiles = await ImagePickerHelper.pickMultiImage();
              if (pickedFiles.isEmpty) return;
              ref.read(addPostNotifierProvider.notifier).addImages(pickedFiles);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: const Text("사진 첨부", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isEmpty && state.images.isEmpty) return;
              if (state.images.any((img) => img.isUploading)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('사진이 아직 업로드 중입니다. 잠시만 기다려주세요.')),
                );
                return;
              }

              showLoadingDialog(context);
              try {
                await ref.read(addPostNotifierProvider.notifier).submitPost(textController.text);
                
                if (!context.mounted) return;
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('성공')),
                );
                context.pop(); // Close screen
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('게시물 게시에 실패했습니다: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPublishDisabled
                  ? ColorsManager.primary200
                  : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: const Text("게시", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
