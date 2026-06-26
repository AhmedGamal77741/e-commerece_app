import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostActions extends ConsumerStatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostActions({super.key, required this.postId, required this.postData});

  @override
  ConsumerState<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends ConsumerState<PostActions> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
