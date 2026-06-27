import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class GuestPostActions extends ConsumerWidget {
  final Map<String, dynamic> post;

  const GuestPostActions({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
