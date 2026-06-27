import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final testProvider = AsyncNotifierProviderFamily<TestNotifier, int, String>(TestNotifier.new);

class TestNotifier extends FamilyAsyncNotifier<int, String> {
  @override
  FutureOr<int> build(String arg) => 0;
}
