import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/add_post_notifier.dart';

class PostTextInput extends ConsumerWidget {
  final TextEditingController controller;

  const PostTextInput({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholderText = ref.watch(addPostNotifierProvider.select((s) => s.innerPlaceholderText));

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Visibility(
          visible: controller.text.isEmpty && placeholderText.isNotEmpty,
          child: Text(
            placeholderText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: null,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
