import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NaturalAspectPageView extends ConsumerStatefulWidget {
  final List imgUrls;
  final PageController pageController;
  final double? explicitWidth;

  const NaturalAspectPageView({
    super.key,
    required this.imgUrls,
    required this.pageController,
    this.explicitWidth,
  });

  @override
  ConsumerState<NaturalAspectPageView> createState() =>
      NaturalAspectPageViewState();
}

class NaturalAspectPageViewState extends ConsumerState<NaturalAspectPageView> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
