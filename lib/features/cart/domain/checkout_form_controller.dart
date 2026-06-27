import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ecommerece_app/features/address/domain/models/address.dart';
import 'package:ecommerece_app/features/cart/domain/checkout_controller.dart';
import 'package:ecommerece_app/features/cart/domain/bank_controller.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:ecommerece_app/features/cart/data/cart_repository.dart';

class CheckoutFormState {
  final String invoiceeType;
  final Address address;
  final String selectedRequest;
  final String? manualRequest;
  final int selectedOption;
  final int selectedBankIndex;
  final Map<String, dynamic>? pendingBuynowData;
  final int pendingPrice;
  final int pendingQuantity;
  final bool isProcessing;
  final String? currentPaymentId;

  const CheckoutFormState({
    this.invoiceeType = '사업자',
    required this.address,
    this.selectedRequest = '문앞',
    this.manualRequest,
    this.selectedOption = 1,
    this.selectedBankIndex = -1,
    this.pendingBuynowData,
    this.pendingPrice = 0,
    this.pendingQuantity = 0,
    this.isProcessing = false,
    this.currentPaymentId,
  });

  static Address emptyAddress() => Address(
    id: '',
    name: '',
    phone: '',
    address: '',
    detailAddress: '',
    isDefault: false,
    addressMap: {},
  );

  CheckoutFormState copyWith({
    String? invoiceeType,
    Address? address,
    String? selectedRequest,
    String? manualRequest,
    int? selectedOption,
    int? selectedBankIndex,
    Map<String, dynamic>? pendingBuynowData,
    int? pendingPrice,
    int? pendingQuantity,
    bool? isProcessing,
    String? currentPaymentId,
  }) {
    return CheckoutFormState(
      invoiceeType: invoiceeType ?? this.invoiceeType,
      address: address ?? this.address,
      selectedRequest: selectedRequest ?? this.selectedRequest,
      manualRequest: manualRequest ?? this.manualRequest,
      selectedOption: selectedOption ?? this.selectedOption,
      selectedBankIndex: selectedBankIndex ?? this.selectedBankIndex,
      pendingBuynowData: pendingBuynowData ?? this.pendingBuynowData,
      pendingPrice: pendingPrice ?? this.pendingPrice,
      pendingQuantity: pendingQuantity ?? this.pendingQuantity,
      isProcessing: isProcessing ?? this.isProcessing,
      currentPaymentId: currentPaymentId ?? this.currentPaymentId,
    );
  }
}

final checkoutFormPaymentIdProvider = Provider<String?>((ref) => null);

final checkoutFormControllerProvider = AsyncNotifierProvider<
    CheckoutFormController, CheckoutFormState>(
  CheckoutFormController.new,
);

class CheckoutFormController
    extends AsyncNotifier<CheckoutFormState> {
  final invoiceeCorpNumController = TextEditingController();
  final invoiceeCorpNameController = TextEditingController();
  final invoiceeCEONameController = TextEditingController();
  final deliveryAddressController = TextEditingController();
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final List<String> deliveryRequests = [
    '문앞',
    '직접 받고 부재 시 문앞',
    '택배함',
    '경비실',
    '직접입력',
  ];

  @override
  FutureOr<CheckoutFormState> build() async {
    ref.onDispose(() {
      invoiceeCorpNumController.dispose();
      invoiceeCorpNameController.dispose();
      invoiceeCEONameController.dispose();
      deliveryAddressController.dispose();
      phoneController.dispose();
      nameController.dispose();
      emailController.dispose();
    });

    final paymentId = ref.watch(checkoutFormPaymentIdProvider);
    return _init(paymentId);
  }

  Future<CheckoutFormState> _init(String? paymentId) async {
    var state = CheckoutFormState(
      address: CheckoutFormState.emptyAddress(),
      currentPaymentId: paymentId,
    );

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || paymentId == null) return state;

    // 1. Load pending buynow
    try {
      final data = await ref
          .read(checkoutControllerProvider.notifier)
          .getPendingBuynow(uid, paymentId);
      if (data != null) {
        state = state.copyWith(
          pendingBuynowData: data,
          pendingPrice: data['price'] ?? 0,
          pendingQuantity: data['quantity'] ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Error loading pending_buynow: $e');
    }

    // 2. Load cached user values
    final cachedData = await ref
        .read(checkoutControllerProvider.notifier)
        .loadCachedValues(uid);
    if (cachedData != null) {
      nameController.text = cachedData['name'] ?? '';
      emailController.text = cachedData['email'] ?? '';
      phoneController.text = cachedData['phone'] ?? '';

      state = state.copyWith(
        invoiceeType: cachedData['invoiceeType'] ?? '사업자',
        selectedOption: cachedData['selectedOption'] ?? 1,
      );

      invoiceeCorpNumController.text = cachedData['invoiceeCorpNum'] ?? '';
      invoiceeCorpNameController.text = cachedData['invoiceeCorpName'] ?? '';
      invoiceeCEONameController.text = cachedData['invoiceeCEOName'] ?? '';

      final cachedInstr = cachedData['deliveryInstructions'] as String? ?? '';
      if (deliveryRequests.contains(cachedInstr)) {
        state = state.copyWith(
          selectedRequest: cachedInstr,
          manualRequest: null,
        );
      } else if (cachedInstr.isNotEmpty) {
        state = state.copyWith(
          selectedRequest: '직접입력',
          manualRequest: cachedInstr,
        );
      }

      final cachedAddressId = (cachedData['deliveryAddressId'] ?? '') as String;
      if (cachedAddressId.isNotEmpty) {
        final address = Address(
          id: cachedAddressId,
          name: cachedData['recipientName'] ?? '',
          phone: cachedData['recipientPhone'] ?? '',
          address: cachedData['deliveryAddress'] ?? '',
          detailAddress: cachedData['deliveryAddressDetail'] ?? '',
          isDefault: false,
          addressMap: {},
        );
        state = state.copyWith(address: address);
        deliveryAddressController.text = cachedData['deliveryAddress'] ?? '';
      }
    }

    // 3. Ensure cached address and instructions
    state = await _ensureCachedAddressAndInstructions(uid, paymentId, state);

    return state;
  }

  Future<CheckoutFormState> _ensureCachedAddressAndInstructions(
    String uid,
    String paymentId,
    CheckoutFormState currentState,
  ) async {
    var newState = currentState;
    final hasAddress = newState.address.id.isNotEmpty;
    final hasInstr =
        newState.selectedRequest != '문앞' ||
        (newState.manualRequest != null && newState.manualRequest!.isNotEmpty);

    if (hasAddress && hasInstr) return newState;

    if (!hasAddress) {
      final resolvedData = await ref
          .read(checkoutControllerProvider.notifier)
          .getUserDefaultAddress(uid);
      if (resolvedData != null) {
        final resolved = Address(
          id: resolvedData['id'] ?? '',
          name: resolvedData['name'] ?? '',
          phone: resolvedData['phone'] ?? '',
          address: resolvedData['address'] ?? '',
          detailAddress: resolvedData['detailAddress'] ?? '',
          isDefault: resolvedData['isDefault'] ?? false,
          addressMap: resolvedData['addressMap'] ?? {},
        );

        newState = newState.copyWith(address: resolved);
        deliveryAddressController.text = resolved.address;

        final addressPatch = {
          'deliveryAddressId': resolved.id,
          'deliveryAddress': resolved.address,
          'deliveryAddressDetail': resolved.detailAddress,
          'recipientName': resolved.name,
          'recipientPhone': resolved.phone,
        };
        await ref
            .read(checkoutControllerProvider.notifier)
            .saveCachedUserValues(addressPatch);
        _patchPendingBuynow(paymentId, addressPatch);
      }
    }

    if (!hasInstr) {
      final instrFromOrder =
          (newState.pendingBuynowData?['deliveryInstructions'] ?? '') as String;
      if (instrFromOrder.isNotEmpty) {
        if (deliveryRequests.contains(instrFromOrder)) {
          newState = newState.copyWith(selectedRequest: instrFromOrder);
        } else {
          newState = newState.copyWith(
            selectedRequest: '직접입력',
            manualRequest: instrFromOrder,
          );
        }
        await ref
            .read(checkoutControllerProvider.notifier)
            .saveCachedUserValues({'deliveryInstructions': instrFromOrder});
      }
    }

    return newState;
  }

  Future<void> reloadAddressAndInstructions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final stateValue = state.value;
    if (uid == null ||
        stateValue == null ||
        stateValue.currentPaymentId == null) {
      return;
    }
    final newState = await _ensureCachedAddressAndInstructions(
      uid,
      stateValue.currentPaymentId!,
      stateValue,
    );
    state = AsyncData(newState);
  }

  void _patchPendingBuynow(String paymentId, Map<String, dynamic> fields) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    ref
        .read(checkoutControllerProvider.notifier)
        .patchPendingBuynow(uid, paymentId, fields)
        .catchError((e) => debugPrint('Failed to patch pending_buynow: $e'));
  }

  void setInvoiceeType(String type) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(invoiceeType: type));
    }
  }

  void setSelectedRequest(String request) {
    if (state.value != null) {
      state = AsyncData(
        state.value!.copyWith(
          selectedRequest: request,
          manualRequest: request != '직접입력' ? null : state.value!.manualRequest,
        ),
      );
    }
  }

  void setManualRequest(String? manualRequest) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(manualRequest: manualRequest));
    }
  }

  void setSelectedOption(int option) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(selectedOption: option));
    }
  }

  void setSelectedBankIndex(int index) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(selectedBankIndex: index));
    }
  }

  Future<void> deleteBankAccount(String payerId) async {
    await ref.read(bankControllerProvider.notifier).deleteBankAccount(payerId);
  }

  void setAddress(Address newAddress, String paymentId) {
    deliveryAddressController.text = newAddress.address;
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(address: newAddress));
    }
    final patch = {
      'deliveryAddressId': newAddress.id,
      'deliveryAddress': newAddress.address,
      'deliveryAddressDetail': newAddress.detailAddress,
      'recipientName': newAddress.name,
      'recipientPhone': newAddress.phone,
    };
    _patchPendingBuynow(paymentId, patch);
    saveCachedUserValues();
  }

  Future<bool> saveCachedUserValues() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final stateValue = state.value;
    if (uid == null || stateValue == null) return false;

    final fields = {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'invoiceeType': stateValue.invoiceeType,
      'invoiceeCorpNum': invoiceeCorpNumController.text.trim(),
      'invoiceeCorpName': invoiceeCorpNameController.text.trim(),
      'invoiceeCEOName': invoiceeCEONameController.text.trim(),
      'selectedOption': stateValue.selectedOption,
      'deliveryAddressId': stateValue.address.id,
      'deliveryAddress': stateValue.address.address,
      'deliveryAddressDetail': stateValue.address.detailAddress,
      'deliveryInstructions':
          stateValue.selectedRequest == '직접입력'
              ? (stateValue.manualRequest?.trim() ?? '')
              : stateValue.selectedRequest,
      'recipientName': stateValue.address.name,
      'recipientPhone': stateValue.address.phone,
    };

    return await ref
        .read(checkoutControllerProvider.notifier)
        .saveCachedUserValues(fields);
  }

  bool validateReceiptTypeFields(BuildContext context) {
    final stateValue = state.value;
    if (stateValue == null) return false;

    if (stateValue.selectedOption == 1) {
      if (nameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현금 영수증: 이름, 이메일, 전화번호를 모두 입력해주세요')),
        );
        return false;
      }
    } else if (stateValue.selectedOption == 2) {
      if (nameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty ||
          stateValue.invoiceeType.isEmpty ||
          invoiceeCorpNumController.text.trim().isEmpty ||
          invoiceeCorpNameController.text.trim().isEmpty ||
          invoiceeCEONameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('세금 계산서: 모든 필수 필드를 입력해주세요')),
        );
        return false;
      }
    }
    return true;
  }

  void launchBankRegistration() {
    final stateValue = state.value;
    if (stateValue == null) return;
    ref
        .read(bankControllerProvider.notifier)
        .launchBankRegistration(
          phoneNo: phoneController.text.trim(),
          option: stateValue.selectedOption.toString(),
        );
  }

  Future<void> handlePlaceOrder({
    required BuildContext context,
    required String uid,
    required List<Map<String, dynamic>> bankAccounts,
    bool isCartCheckout = false,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    final stateValue = state.value;
    if (stateValue == null) return;

    if (stateValue.selectedOption != 1 && stateValue.selectedOption != 2) {
      onError('현금 영수증 또는 세금 계산서를 선택해주세요');
      return;
    }
    if (!validateReceiptTypeFields(context)) return;

    if (stateValue.address.id.isEmpty) {
      onError('배송지를 먼저 등록해주세요');
      return;
    }
    if (bankAccounts.isEmpty || stateValue.selectedBankIndex < 0) {
      onError('계좌를 선택해주세요');
      return;
    }

    final payerId =
        bankAccounts[stateValue.selectedBankIndex]['payerId'] as String? ?? '';
    if (payerId.isEmpty) {
      onError('계좌 정보가 올바르지 않습니다. 계좌를 다시 등록해주세요.');
      return;
    }

    if (isCartCheckout) {
      try {
        await ref.read(cartControllerProvider.notifier).validateStockAvailability();
        await ref.read(cartControllerProvider.notifier).detectPriceChanges();
      } catch (e) {
        onError(e.toString().replaceAll('Exception: ', ''));
        return;
      }
    }

    // Generate a new paymentId if it's cart checkout, otherwise use the existing one from BuyNow
    final paymentId = isCartCheckout
        ? ref.read(checkoutControllerProvider.notifier).generateOrderId()
        : stateValue.currentPaymentId;

    if (paymentId == null || paymentId.isEmpty) {
      onError('주문 처리 중 오류가 발생했습니다. 다시 시도해 주세요.');
      return;
    }

    final dm =
        stateValue.pendingBuynowData?['deliveryManagerId']?.toString() ?? '';

    await saveCachedUserValues();

    if (!isCartCheckout) {
      _patchPendingBuynow(paymentId, {
        'deliveryInstructions':
            stateValue.selectedRequest == '직접입력'
                ? (stateValue.manualRequest?.trim() ?? '')
                : stateValue.selectedRequest,
      });
    }

    state = AsyncData(stateValue.copyWith(isProcessing: true, currentPaymentId: paymentId));

    try {
      final response = await http.post(
        Uri.parse('https://pay.pang2chocolate.com/api/charge-bank'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': uid,
          'paymentId': paymentId,
          'payerId': payerId,
          'option': stateValue.selectedOption.toString(),
          if (dm.isNotEmpty && !isCartCheckout) 'dm': dm,
        }),
      );

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['success'] == true) {
        try {
          List<Map<String, dynamic>> items;
          if (isCartCheckout) {
            final cartSnap = await ref.read(cartRepositoryProvider).userCartStream(uid).first;
            items = cartSnap.docs.map((d) => {'docId': d.id, ...d.data()}).toList();
          } else {
            items = [
              {
                'product_id': stateValue.pendingBuynowData?['product_id'],
                'productName': stateValue.pendingBuynowData?['product_name'],
                'quantity': stateValue.pendingBuynowData?['quantity'],
                'pricePointIndex': stateValue.pendingBuynowData?['pricePointIndex'],
                'price': stateValue.pendingBuynowData?['price'],
                'imgUrl': stateValue.pendingBuynowData?['imgUrl'],
              },
            ];
          }

          // For cart checkout, we need the total price from the cart, not the pendingBuynowData price
          final totalPrice = isCartCheckout
              ? ref.read(cartTotalProvider)
              : stateValue.pendingPrice;

          final orderData = {
            'address': stateValue.address.toFirestore(),
            'totalPrice': totalPrice,
            'buyerName': nameController.text.trim(),
            'buyerEmail': emailController.text.trim(),
            'buyerPhone': phoneController.text.trim(),
            'deliveryInstructions':
                stateValue.selectedRequest == '직접입력'
                    ? stateValue.manualRequest
                    : stateValue.selectedRequest,
          };
          
          await ref
              .read(checkoutControllerProvider.notifier)
              .processCheckoutTransaction(
                uid: uid,
                paymentId: paymentId,
                items: items,
                orderData: orderData,
                isCartCheckout: isCartCheckout,
              );
          onSuccess();
        } catch (e) {
          state = AsyncData(stateValue.copyWith(isProcessing: false));
          onError(e.toString().replaceAll('Exception: ', ''));
        }
      } else {
        final msg = result['message'] as String? ?? '결제에 실패했습니다. 다시 시도해 주세요.';
        state = AsyncData(stateValue.copyWith(isProcessing: false));
        onError(msg);
      }
    } catch (e) {
      state = AsyncData(stateValue.copyWith(isProcessing: false));
      onError('결제 중 오류가 발생했습니다. 다시 시도해 주세요.');
    }
  }
}
