import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';

import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/address/domain/models/address.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/cart/data/cart_repository.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:ecommerece_app/features/address/ui/add_address_screen.dart';
import 'package:ecommerece_app/features/address/ui/address_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ecommerece_app/features/cart/domain/checkout_controller.dart';
import 'package:ecommerece_app/features/cart/domain/bank_controller.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_section_card.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_multi_item_summary.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_address_card.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_delivery_request.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_payment_selector.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_receipt_option.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_bottom_bar.dart';
class PlaceOrder extends ConsumerStatefulWidget {
  const PlaceOrder({super.key});

  @override
  ConsumerState<PlaceOrder> createState() => _PlaceOrderState();
}

class _PlaceOrderState extends ConsumerState<PlaceOrder> {
  // ── Receipt / invoice fields ──────────────────────────────────────────────
  String invoiceeType = '사업자';
  final invoiceeCorpNumController = TextEditingController();
  final invoiceeCorpNameController = TextEditingController();
  final invoiceeCEONameController = TextEditingController();

  // ── Controllers ───────────────────────────────────────────────────────────
  final deliveryAddressController = TextEditingController();
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final _bottomSheetFormKey = GlobalKey<FormState>();

  // ── Address ───────────────────────────────────────────────────────────────
  Address address = Address(
    id: '',
    name: '',
    phone: '',
    address: '',
    detailAddress: '',
    isDefault: false,
    addressMap: {},
  );

  // ── Delivery request ──────────────────────────────────────────────────────
  final List<String> deliveryRequests = [
    '문앞',
    '직접 받고 부재 시 문앞',
    '택배함',
    '경비실',
    '직접입력',
  ];
  String selectedRequest = '문앞';
  String? manualRequest;

  // ── Receipt option ────────────────────────────────────────────────────────
  int selectedOption = 1;

  // ── Bank accounts ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get bankAccounts => ref.watch(bankAccountsStreamProvider).value ?? [];
  int selectedBankIndex = -1;

  // ── Payment state ─────────────────────────────────────────────────────────
  bool isProcessing = false;
  String? currentPaymentId;

  // ── Guards ────────────────────────────────────────────────────────────────
  // Prevents didChangeDependencies from re-fetching on every rebuild

  final formatCurrency = NumberFormat('#,###');

  // ───────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ───────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    invoiceeCorpNumController.dispose();
    invoiceeCorpNameController.dispose();
    invoiceeCEONameController.dispose();
    deliveryAddressController.dispose();
    phoneController.dispose();
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    // Run refreshCartPrices independently — don't block UI init on it
    ref.read(cartRepositoryProvider).refreshCartPrices(uid);

    // Load cached user values
    await _loadCachedUserValues();

    // After cache is loaded, fill in address from default if missing
    await _ensureCachedAddressAndInstructions(uid);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DATA FETCHING
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _loadCachedUserValues() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final data = await ref.read(checkoutControllerProvider.notifier).loadCachedValues(uid);
    if (data == null || !mounted) return;

    setState(() {
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      phoneController.text = data['phone'] ?? '';

      invoiceeType = data['invoiceeType'] ?? '사업자';
      invoiceeCorpNumController.text = data['invoiceeCorpNum'] ?? '';
      invoiceeCorpNameController.text = data['invoiceeCorpName'] ?? '';
      invoiceeCEONameController.text = data['invoiceeCEOName'] ?? '';
      selectedOption = data['selectedOption'] ?? 1;

      // Restore delivery request — handles both preset options and 직접입력
      final cachedInstr = data['deliveryInstructions'] as String? ?? '';
      if (deliveryRequests.contains(cachedInstr)) {
        selectedRequest = cachedInstr;
        manualRequest = null;
      } else if (cachedInstr.isNotEmpty) {
        // Was a custom 직접입력 value
        selectedRequest = '직접입력';
        manualRequest = cachedInstr;
      }

      // Restore address from cache
      final cachedAddressId = (data['deliveryAddressId'] ?? '') as String;
      if (cachedAddressId.isNotEmpty) {
        address = Address(
          id: cachedAddressId,
          name: data['recipientName'] ?? '',
          phone: data['recipientPhone'] ?? '',
          address: data['deliveryAddress'] ?? '',
          detailAddress: data['deliveryAddressDetail'] ?? '',
          isDefault: false,
          addressMap: {},
        );
        deliveryAddressController.text = data['deliveryAddress'] ?? '';
      }
    });
  }

  // ── Resolve default address if cache has none (first-time user) ───────────
  Future<void> _ensureCachedAddressAndInstructions(String uid) async {
    // Only run if address wasn't restored from cache
    if (address.id.isNotEmpty) return;

    final resolvedData = await ref.read(checkoutControllerProvider.notifier).getUserDefaultAddress(uid);
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

      if (mounted) {
        setState(() {
          address = resolved;
          deliveryAddressController.text = resolved.address;
        });
      }

      // Persist into cache so it's available next time
      await ref.read(checkoutControllerProvider.notifier).saveCachedUserValues({
        'deliveryAddressId': resolved.id,
        'deliveryAddress': resolved.address,
        'deliveryAddressDetail': resolved.detailAddress,
        'recipientName': resolved.name,
        'recipientPhone': resolved.phone,
      });
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BANK ACCOUNT DELETE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _deleteBankAccount(String uid, String payerId) async {
    await ref.read(bankControllerProvider.notifier).deleteBankAccount(payerId);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CACHE SAVE
  // Called explicitly by the receipt/invoice 저장 button.
  // Also called automatically at payment time to capture latest state.
  // ───────────────────────────────────────────────────────────────────────────

  Future<bool> _saveCachedUserValues({bool showFeedback = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    
    final fields = {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'invoiceeType': invoiceeType,
      'invoiceeCorpNum': invoiceeCorpNumController.text.trim(),
      'invoiceeCorpName': invoiceeCorpNameController.text.trim(),
      'invoiceeCEOName': invoiceeCEONameController.text.trim(),
      'selectedOption': selectedOption,
      'deliveryAddressId': address.id,
      'deliveryAddress': address.address,
      'deliveryAddressDetail': address.detailAddress,
      'deliveryInstructions': selectedRequest == '직접입력'
          ? (manualRequest?.trim() ?? '')
          : selectedRequest,
      'recipientName': address.name,
      'recipientPhone': address.phone,
    };

    final success = await ref.read(checkoutControllerProvider.notifier).saveCachedUserValues(fields);
    
    if (success && showFeedback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('정보가 저장되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!success && showFeedback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장 실패'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return success;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ADDRESS SELECTION
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddressListScreen()),
    );
    if (result != null) {
      deliveryAddressController.text = result.address;
      setState(() => address = result);
      // Save immediately — address change is explicit user action
      _saveCachedUserValues();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RECEIPT FIELD VALIDATION
  // ───────────────────────────────────────────────────────────────────────────

  bool _validateReceiptTypeFields() {
    if (selectedOption == 1) {
      if (nameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현금 영수증: 이름, 이메일, 전화번호를 모두 입력해주세요')),
        );
        return false;
      }
    } else if (selectedOption == 2) {
      if (nameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty ||
          invoiceeType.isEmpty ||
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

  // ───────────────────────────────────────────────────────────────────────────
  // BANK REGISTRATION
  // ───────────────────────────────────────────────────────────────────────────

  void _launchBankRegistration(String uid) {
    ref.read(bankControllerProvider.notifier).launchBankRegistration(
      phoneNo: phoneController.text.trim(),
      option: selectedOption.toString(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ORDER PLACEMENT
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _handlePlaceOrder(int totalPrice, String uid) async {
    if (selectedOption != 1 && selectedOption != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현금 영수증 또는 세금 계산서를 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_validateReceiptTypeFields()) return;
    if (address.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('배송지를 먼저 등록해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (bankAccounts.isEmpty || selectedBankIndex < 0) {
      _showBankAccountBottomSheet(uid);
      return;
    }

    final payerId = bankAccounts[selectedBankIndex]['payerId'] as String? ?? '';
    if (payerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계좌 정보가 올바르지 않습니다. 계좌를 다시 등록해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isProcessing = true);
    _showLoadingModal();

    try {
      // 1. Stock Validation
      await ref.read(cartControllerProvider.notifier).validateStockAvailability();

      // 2. Price Change Validation
      await ref.read(cartControllerProvider.notifier).detectPriceChanges();
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Auto-save latest state before payment so CF has up-to-date cached values
    await _saveCachedUserValues();

    final paymentId = ref.read(checkoutControllerProvider.notifier).generateOrderId();
    currentPaymentId = paymentId;

    try {
      final response = await http.post(
        Uri.parse('https://pay.pang2chocolate.com/api/charge-bank'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': uid,
          'paymentId': paymentId,
          'payerId': payerId,
          'option': selectedOption.toString(),
        }),
      );

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['success'] == true) {
        try {
          final cartSnap = await ref.read(cartRepositoryProvider).userCartStream(uid).first;
          final items = cartSnap.docs.map((d) => {'docId': d.id, ...d.data()}).toList();
          final orderData = {
            'address': address.toFirestore(),
            'totalPrice': totalPrice,
            'buyerName': nameController.text.trim(),
            'buyerEmail': emailController.text.trim(),
            'buyerPhone': phoneController.text.trim(),
            'deliveryInstructions': selectedRequest == '직접입력' ? manualRequest : selectedRequest,
          };
          
          await ref.read(checkoutControllerProvider.notifier).processCheckoutTransaction(
            uid: uid,
            paymentId: paymentId,
            items: items,
            orderData: orderData,
            isCartCheckout: true,
          );
        } catch (e) {
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          if (mounted) {
            setState(() => isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        if (mounted) context.go(Routes.orderCompleteScreen);
      } else {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        final msg = result['message'] as String? ?? '결제에 실패했습니다. 다시 시도해 주세요.';
        if (mounted) {
          setState(() => isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제 중 오류가 발생했습니다. 다시 시도해 주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Non-dismissible loading modal ─────────────────────────────────────────
  void _showLoadingModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const PopScope(
            canPop: false,
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox.shrink(),
                      SizedBox(height: 16),
                      Text(
                        '결제 처리 중입니다...',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '잠시만 기다려 주세요',
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BANK ACCOUNT BOTTOM SHEET
  // ───────────────────────────────────────────────────────────────────────────

  void _showBankAccountBottomSheet(String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '계좌 선택',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  verticalSpace(16),
                  if (bankAccounts.isEmpty)
                    const Text(
                      '등록된 계좌가 없습니다.',
                      style: TextStyle(color: Colors.black),
                    ),
                  ...bankAccounts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final bank = entry.value;
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.account_balance,
                            color: Colors.black,
                          ),
                          title: Text(
                            '${bank['bankName']} (${bank['bankNum']})',
                            style: const TextStyle(color: Colors.black),
                          ),
                          tileColor:
                              idx == selectedBankIndex
                                  ? Colors.black12
                                  : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            setState(() => selectedBankIndex = idx);
                            setStateDialog(() {});
                            Navigator.of(context).pop();
                          },
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.black,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: const Text('계좌 삭제'),
                                      content: Text(
                                        '${bank['bankName']} (${bank['bankNum']}) '
                                        '계좌를 삭제하시겠습니까?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, false),
                                          child: const Text(
                                            '취소',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, true),
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.black,
                                          ),
                                          child: const Text(
                                            '삭제',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm != true) return;
                              await _deleteBankAccount(
                                uid,
                                bank['payerId'] as String,
                              );
                              setStateDialog(() {});
                              if (!mounted) return;
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        verticalSpace(5),
                      ],
                    );
                  }),
                  verticalSpace(8),
                  WideTextButton(
                    txt: '새 계좌 등록하기',
                    func: () {
                      Navigator.of(context).pop();
                      _launchBankRegistration(uid);
                    },
                    color: Colors.black,
                    txtColor: Colors.white,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: StreamBuilder(
        stream:
            ref.read(checkoutControllerProvider.notifier).getUserStream(uid),
        builder: (context, userSnapshot) {

          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios),
              ),
              title: Text(
                '주문 / 결제',
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            body: Padding(
              padding: EdgeInsets.only(left: 15.w, top: 10.h, right: 15.w),
              child: ListView(
                children: [
                  // ── Cart items ──────────────────────────────────────────
                  CheckoutSectionCard(
                    child: CheckoutMultiItemSummary(uid: uid),
                  ),
                  verticalSpace(10),

                  // ── Address ─────────────────────────────────────────────
                  CheckoutSectionCard(
                    child: CheckoutAddressCard(
                      uid: uid,
                      address: address,
                      onSelectAddress: _selectAddress,
                    ),
                  ),
                  verticalSpace(10),

                  // ── Delivery request ──────────────────────────────────────
                  CheckoutSectionCard(
                    child: StatefulBuilder(
                      builder: (context, setStateLocal) {
                        return CheckoutDeliveryRequest(
                          selectedRequest: selectedRequest,
                          manualRequest: manualRequest,
                          onManualRequestChanged: (text) {
                            setState(() => manualRequest = text);
                          },
                          onShowSheet: () => _showDeliveryRequestSheet(setStateLocal),
                        );
                      },
                    ),
                  ),
                  verticalSpace(10),

                  // ── Bank account ──────────────────────────────────────────
                  CheckoutSectionCard(
                    child: CheckoutPaymentSelector(
                      bankAccounts: bankAccounts,
                      selectedBankIndex: selectedBankIndex,
                      onShowBottomSheet: () => _showBankAccountBottomSheet(uid),
                    ),
                  ),
                  verticalSpace(10),

                  // ── Receipt / invoice ─────────────────────────────────────
                  CheckoutSectionCard(
                    child: CheckoutReceiptOption(
                      selectedOption: selectedOption,
                      onShowBottomSheet: _showReceiptBottomSheet,
                    ),
                  ),
                  verticalSpace(15.h),
                ],
              ),
            ),

            // ── Bottom bar ──────────────────────────────────────────────
            bottomNavigationBar: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  ref.read(checkoutControllerProvider.notifier)
                      .getUserCartStream(uid),
              builder: (context, cartSnapshot) {
                if (!cartSnapshot.hasData || cartSnapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Consumer(
                  builder: (context, ref, child) {
                    final totalPrice = ref.watch(cartTotalProvider);
                    return CheckoutBottomBar(
                      pendingPrice: totalPrice,
                      isProcessing: isProcessing,
                      onValidate: () async {
                        // Check receipt option
                        if (selectedOption != 1 && selectedOption != 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('현금 영수증 또는 세금 계산서를 선택해주세요'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return false;
                        }
                        if (!_validateReceiptTypeFields()) return false;
                        // ── Gate: address required before payment ────────────────────────
                        if (address.id.isEmpty) {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddAddressScreen(),
                            ),
                          );
                          if (result != true) {
                            return false; // user didn't add one, block payment
                          }
                          // Address was added — re-fetch it into state so the UI reflects it
                          await _ensureCachedAddressAndInstructions(uid);
                          return false; // return false here so the slider resets; user slides again
                        }
                        // No bank account — open sheet and snap back
                        if (bankAccounts.isEmpty ||
                            selectedBankIndex < 0) {
                          _showBankAccountBottomSheet(uid);
                          return false;
                        }
                        final payerId =
                            bankAccounts[selectedBankIndex]['payerId']
                                as String? ??
                            '';
                        if (payerId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '계좌 정보가 올바르지 않습니다. 계좌를 다시 등록해주세요.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return false;
                        }
                        return true;
                      },
                      onSlideComplete: () => _handlePlaceOrder(totalPrice, uid),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ───────────────────────────────────────────────────────────────────────────



  void _showDeliveryRequestSheet(StateSetter setStateLocal) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(15.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                deliveryRequests
                    .map(
                      (req) => ListTile(
                        title: Text(
                          req,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.sp,
                            fontFamily: 'NotoSans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        onTap: () {
                          setStateLocal(() {
                            selectedRequest = req;
                            if (req != '직접입력') manualRequest = null;
                          });
                          setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
          ),
        );
      },
    );
  }

  void _showReceiptBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20.h,
                left: 20.w,
                right: 20.w,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _bottomSheetFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRadioOption(
                            value: 1,
                            label: '현금 영수증',
                            setStateSheet: setStateSheet,
                          ),
                          _buildRadioOption(
                            value: 2,
                            label: '세금 계산서',
                            setStateSheet: setStateSheet,
                          ),
                        ],
                      ),
                      if (selectedOption == 1)
                        ..._buildCashReceiptFields()
                      else
                        ..._buildTaxInvoiceFields(setStateSheet),
                      verticalSpace(10),
                      // 저장 button — explicit save triggered by user
                      WideTextButton(
                        txt: '저장',
                        func: () async {
                          if (!_bottomSheetFormKey.currentState!.validate())
                            return;
                          final success = await _saveCachedUserValues(
                            showFeedback: true,
                          );
                          if (success && mounted) Navigator.pop(context);
                        },
                        color: Colors.black,
                        txtColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption({
    required int value,
    required String label,
    required StateSetter setStateSheet,
  }) {
    return Row(
      children: [
        Transform.scale(
          scale: 20.sp / 15,
          child: Radio<int>(
            value: value,
            groupValue: selectedOption,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            onChanged: (v) {
              setStateSheet(() => selectedOption = v!);
              setState(() {});
            },
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 20.sp,
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w800,
            color: ColorsManager.primaryblack,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCashReceiptFields() => [
    UnderlineTextField(
      controller: nameController,
      hintText: '이름',
      obscureText: false,
      keyboardType: TextInputType.text,
      validator:
          (val) => (val == null || val.trim().isEmpty) ? '이름을 입력해주세요' : null,
      onChanged: (_) => null,
    ),
    SizedBox(height: 10.h),
    UnderlineTextField(
      controller: emailController,
      hintText: '이메일',
      obscureText: false,
      keyboardType: TextInputType.emailAddress,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return '이메일을 입력해주세요';
        if (!RegExp(r'^.+@.+\..+$').hasMatch(val.trim())) {
          return '유효한 이메일을 입력해주세요';
        }
        return null;
      },
      onChanged: (_) => null,
    ),
    SizedBox(height: 10.h),
    UnderlineTextField(
      controller: phoneController,
      hintText: '전화번호',
      obscureText: false,
      keyboardType: TextInputType.phone,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return '전화번호를 입력해주세요';
        if (!RegExp(
          r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$',
        ).hasMatch(val)) {
          return '유효한 한국 전화번호를 입력하세요';
        }
        return null;
      },
      onChanged: (_) => null,
    ),
  ];

  List<Widget> _buildTaxInvoiceFields(StateSetter setStateSheet) => [
    DropdownButtonFormField<String>(
      dropdownColor: Colors.white,
      value: invoiceeType,
      items:
          [
            '사업자',
            '개인',
            '외국인',
          ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (val) {
        setStateSheet(() => invoiceeType = val ?? '사업자');
      },
      decoration: const InputDecoration(
        border: UnderlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
    ),
    SizedBox(height: 10.h),
    UnderlineTextField(
      obscureText: false,
      controller: invoiceeCorpNumController,
      hintText: '공급받는자 사업자번호',
      keyboardType: TextInputType.number,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return '사업자번호를 입력해주세요';
        final cleaned = val.trim().replaceAll('-', '');
        if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
          return '사업자번호는 숫자만 입력 가능합니다';
        }
        if (cleaned.length != 10) {
          return '사업자번호는 숫자 10자리여야 합니다 (예: 123-45-67890)';
        }
        return null;
      },
      onChanged: (_) => null,
    ),
    SizedBox(height: 10.h),
    UnderlineTextField(
      obscureText: false,
      controller: invoiceeCorpNameController,
      hintText: '공급받는자 상호',
      keyboardType: TextInputType.text,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return '이름을 입력해주세요';
        if (val.trim().length > 200) return '입력은 최대 200자까지 가능합니다';
        return null;
      },
      onChanged: (_) => null,
    ),
    SizedBox(height: 10.h),
    UnderlineTextField(
      obscureText: false,
      controller: invoiceeCEONameController,
      hintText: '공급받는자 대표자 성명',
      keyboardType: TextInputType.text,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return '대표자 성명을 입력해주세요';
        if (val.trim().length > 200) return '입력은 최대 200자까지 가능합니다';
        return null;
      },
      onChanged: (_) => null,
    ),
    SizedBox(height: 10.h),
    UnderlineTextField(
      controller: emailController,
      hintText: '이메일',
      obscureText: false,
      keyboardType: TextInputType.emailAddress,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return '이메일을 입력해주세요';
        if (!RegExp(r'^.+@.+\..+$').hasMatch(val.trim())) {
          return '유효한 이메일을 입력해주세요';
        }
        return null;
      },
      onChanged: (_) => null,
    ),
    SizedBox(height: 10.h),
    UnderlineTextField(
      controller: phoneController,
      hintText: '전화번호',
      obscureText: false,
      keyboardType: TextInputType.phone,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return '전화번호를 입력해주세요';
        if (!RegExp(
          r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$',
        ).hasMatch(val)) {
          return '유효한 한국 전화번호를 입력하세요';
        }
        return null;
      },
      onChanged: (_) => null,
    ),
  ];
}
