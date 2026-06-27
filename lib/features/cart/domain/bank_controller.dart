import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecommerece_app/features/cart/domain/bank_repository.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

final bankAccountsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(bankRepositoryProvider);
  return repo.userBankAccountsStream(user.uid);
});

final bankControllerProvider = NotifierProvider<BankController, void>(() {
  return BankController();
});

class BankController extends Notifier<void> {
  @override
  void build() {}

  Future<void> deleteBankAccount(String payerId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    final repo = ref.read(bankRepositoryProvider);
    await repo.deleteBankAccount(user.uid, payerId);
  }

  Future<void> launchBankRegistration({
    required String phoneNo,
    required String option,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final regPaymentId = FirebaseFirestore.instance.collection('_tmp').doc().id;

    final url = Uri.parse(
      'https://pay.pang2chocolate.com/bank-register.html'
      '?userId=${Uri.encodeComponent(user.uid)}'
      '&paymentId=${Uri.encodeComponent(regPaymentId)}'
      '&phoneNo=${Uri.encodeComponent(phoneNo)}'
      '&option=${Uri.encodeComponent(option)}',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }
}
