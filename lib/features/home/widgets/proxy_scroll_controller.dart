import 'package:flutter/widgets.dart';

class ProxyScrollController extends ScrollController {
  ScrollController? activeController;

  @override
  bool get hasClients => activeController?.hasClients ?? false;

  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    if (activeController != null && activeController!.hasClients) {
      return activeController!.animateTo(offset, duration: duration, curve: curve);
    }
    return Future.value();
  }

  @override
  void jumpTo(double value) {
    if (activeController != null && activeController!.hasClients) {
      activeController!.jumpTo(value);
    }
  }
}
