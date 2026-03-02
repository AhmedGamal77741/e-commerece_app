import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/cart/models/address.dart';
import 'package:ecommerece_app/features/cart/services/cart_service.dart';
import 'package:ecommerece_app/features/cart/sub_screens/address_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceOrder extends StatefulWidget {
  const PlaceOrder({super.key});

  @override
  State<PlaceOrder> createState() => _PlaceOrderState();
}

class _PlaceOrderState extends State<PlaceOrder> {
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

  // ── Card accounts ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> cardAccounts = [];
  int selectedCardIndex = -1;

  // ── Payment state ─────────────────────────────────────────────────────────
  bool isProcessing = false;
  String? currentPaymentId;

  // ── Card registration tracking ────────────────────────────────────────────
  // Tracks a pending_orders doc created during card-register.html flow so we
  // can detect when handleCardRegCallback marks it "registered" or "failed".
  StreamSubscription<QuerySnapshot>? _cardRegSub;
  String?
  _cardRegPaymentId; // paymentId used for registration (not for payment)

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
    _cardRegSub?.cancel();
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
    if (uid.isNotEmpty) await refreshCartPrices(uid);
    await _fetchCardAccounts();
    await _loadCachedUserValues();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DATA FETCHING
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _fetchCardAccounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data();
    if (data != null && data['cardAccounts'] != null) {
      final accounts = List<Map<String, dynamic>>.from(data['cardAccounts']);
      if (mounted) {
        setState(() {
          cardAccounts = accounts;
          selectedCardIndex = accounts.isNotEmpty ? 0 : -1;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          cardAccounts = [];
          selectedCardIndex = -1;
        });
      }
    }
  }

  Future<void> _loadCachedUserValues() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('usercached_values')
            .doc(uid)
            .get();
    if (!doc.exists || !mounted) return;
    final data = doc.data();
    if (data == null) return;
    setState(() {
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      phoneController.text = data['phone'] ?? '';
      invoiceeType = data['invoiceeType'] ?? '사업자';
      invoiceeCorpNumController.text = data['invoiceeCorpNum'] ?? '';
      invoiceeCorpNameController.text = data['invoiceeCorpName'] ?? '';
      invoiceeCEONameController.text = data['invoiceeCEOName'] ?? '';
      selectedOption = data['selectedOption'] ?? 1;

      final cachedRequest = data['deliveryInstructions'] as String?;
      if (cachedRequest != null && deliveryRequests.contains(cachedRequest)) {
        selectedRequest = cachedRequest;
      }

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

  // ───────────────────────────────────────────────────────────────────────────
  // CACHE SAVE
  // ───────────────────────────────────────────────────────────────────────────

  Future<bool> _saveCachedUserValues({bool showFeedback = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      await FirebaseFirestore.instance
          .collection('usercached_values')
          .doc(uid)
          .set({
            'userId': uid,
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
            'deliveryInstructions':
                selectedRequest == '직접입력'
                    ? (manualRequest?.trim() ?? '')
                    : selectedRequest,
            'recipientName': address.name,
            'recipientPhone': address.phone,
          }, SetOptions(merge: true));
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정보가 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
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
  // CARD REGISTRATION FLOW
  //
  // Launches card-register.html in external browser.
  // A stream subscription on pending_orders watches for the callback result
  // ("registered" or "failed") set by handleCardRegCallback.
  // ───────────────────────────────────────────────────────────────────────────

  void _launchCardRegistration(String uid) {
    // Create a fresh paymentId just for the registration step
    final regPaymentId = FirebaseFirestore.instance.collection('_tmp').doc().id;
    _cardRegPaymentId = regPaymentId;

    // Watch for the callback result
    _cardRegSub?.cancel();
    _cardRegSub = FirebaseFirestore.instance
        .collection('pending_orders')
        .where('userId', isEqualTo: uid)
        .where('paymentId', isEqualTo: regPaymentId)
        .snapshots()
        .listen((snap) async {
          if (snap.docs.isEmpty || !mounted) return;
          final status = snap.docs.first['status'] as String?;

          if (status == 'registered') {
            _cardRegSub?.cancel();
            _cardRegSub = null;
            // Refresh card list so new card appears immediately
            await _fetchCardAccounts();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('카드가 등록되었습니다 ✓'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (status == 'failed') {
            _cardRegSub?.cancel();
            _cardRegSub = null;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('카드 등록에 실패했습니다. 다시 시도해 주세요.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });

    // Launch registration page
    launchUrl(
      Uri.parse(
        'https://pay.pang2chocolate.com/card-register.html'
        '?userId=${Uri.encodeComponent(uid)}'
        '&paymentId=${Uri.encodeComponent(regPaymentId)}'
        '&phoneNo=${Uri.encodeComponent(phoneController.text.trim())}'
        '&option=${Uri.encodeComponent(selectedOption.toString())}',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ORDER PLACEMENT — calls chargeCardBillingKey CF directly
  //
  // Shows a non-dismissible modal barrier while the HTTP call is in flight.
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

    // Must have a card selected
    if (cardAccounts.isEmpty || selectedCardIndex < 0) {
      _showCardAccountBottomSheet(uid);
      return;
    }

    final payerId = cardAccounts[selectedCardIndex]['payerId'] as String? ?? '';
    if (payerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카드 정보가 올바르지 않습니다. 카드를 다시 등록해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('orders').doc();
    final paymentId = docRef.id;
    currentPaymentId = paymentId;

    // Show non-dismissible loading modal
    _showLoadingModal();

    try {
      final response = await http.post(
        Uri.parse('https://pay.pang2chocolate.com/api/charge-card'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': uid,
          'paymentId': paymentId,
          'payerId': payerId,
          'option': selectedOption.toString(),
        }),
      );

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (mounted)
        Navigator.of(context, rootNavigator: true).pop(); // close modal

      if (result['success'] == true) {
        if (mounted) context.go(Routes.orderCompleteScreen);
      } else {
        final msg = result['message'] as String? ?? '결제에 실패했습니다. 다시 시도해 주세요.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
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
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.black),
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
  // CARD ACCOUNT BOTTOM SHEET
  // ───────────────────────────────────────────────────────────────────────────

  void _showCardAccountBottomSheet(String uid) {
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
                    '카드 선택',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  verticalSpace(16),
                  if (cardAccounts.isEmpty)
                    const Text(
                      '등록된 카드가 없습니다.',
                      style: TextStyle(color: Colors.black),
                    ),
                  ...cardAccounts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final card = entry.value;
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.credit_card,
                            color: Colors.black,
                          ),
                          title: Text(
                            '${card['cardName']} (${card['cardNum']})',
                            style: const TextStyle(color: Colors.black),
                          ),
                          tileColor:
                              idx == selectedCardIndex
                                  ? Colors.black12
                                  : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            setState(() => selectedCardIndex = idx);
                            setStateDialog(() {});
                            Navigator.of(context).pop();
                          },
                        ),
                        verticalSpace(5),
                      ],
                    );
                  }),
                  verticalSpace(8),
                  WideTextButton(
                    txt: '새 카드 등록하기',
                    func: () {
                      Navigator.of(context).pop();
                      _launchCardRegistration(uid);
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
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          final isSub = userSnapshot.data?.get('isSub') ?? false;

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
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '구매목록',
                          style: TextStyles.abeezee16px400wPblack.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        verticalSpace(10.h),
                        StreamBuilder(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('cart')
                                  .snapshots(),
                          builder: (context, cartSnapshot) {
                            if (cartSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final cartDocs = cartSnapshot.data!.docs;
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              separatorBuilder:
                                  (_, index) =>
                                      index == cartDocs.length - 1
                                          ? const SizedBox.shrink()
                                          : verticalSpace(10),
                              itemCount: cartDocs.length,
                              itemBuilder: (ctx, index) {
                                final cartData = cartDocs[index].data();
                                final productId = cartData['product_id'];
                                return FutureBuilder<DocumentSnapshot>(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection('products')
                                          .doc(productId)
                                          .get(),
                                  builder: (context, productSnapshot) {
                                    if (!productSnapshot.hasData) {
                                      return const ListTile(
                                        title: Text('로딩 중...'),
                                      );
                                    }
                                    final productData =
                                        productSnapshot.data!.data()
                                            as Map<String, dynamic>;
                                    return Row(
                                      children: [
                                        Image.network(
                                          productData['imgUrl'] ?? '',
                                          width: 80.w,
                                          height: 80.h,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => SizedBox(
                                                width: 80.w,
                                                height: 80.h,
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                ),
                                              ),
                                        ),
                                        horizontalSpace(10),
                                        Flexible(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${productData['productName']}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16.sp,
                                                  fontFamily: 'NotoSans',
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.40.h,
                                                ),
                                              ),
                                              verticalSpace(8),
                                              StreamBuilder<int>(
                                                stream: getProductQuantityStream(
                                                  cartData['product_id'],
                                                  cartData['pricePointIndex'],
                                                ),
                                                builder: (context, snapshot) {
                                                  final quan =
                                                      snapshot.data ?? 0;
                                                  return Text(
                                                    '$quan 개',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16.sp,
                                                      fontFamily: 'NotoSans',
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      height: 1.40.h,
                                                    ),
                                                  );
                                                },
                                              ),
                                              SizedBox(height: 8.h),
                                              StreamBuilder<double>(
                                                stream: getProductPriceStream(
                                                  cartData['product_id'],
                                                  cartData['pricePointIndex'],
                                                  isSub,
                                                ),
                                                builder: (context, snapshot) {
                                                  final price =
                                                      snapshot.data ?? 0.0;
                                                  return Text(
                                                    '${formatCurrency.format(price)} 원',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16.sp,
                                                      fontFamily: 'NotoSans',
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      height: 1.40.h,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  verticalSpace(10),

                  // ── Address ─────────────────────────────────────────────
                  _buildSectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child:
                              address.name.isEmpty
                                  ? FutureBuilder(
                                    future:
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(uid)
                                            .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError ||
                                          !snapshot.hasData ||
                                          !snapshot.data!.exists) {
                                        return const Center(
                                          child: Text('User data not found'),
                                        );
                                      }
                                      final userData = snapshot.data!.data()!;
                                      if ((userData['defaultAddressId'] ?? '')
                                          .isEmpty) {
                                        return _buildNoAddress();
                                      }
                                      return FutureBuilder(
                                        future:
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(uid)
                                                .collection('addresses')
                                                .doc(
                                                  userData['defaultAddressId'],
                                                )
                                                .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                          if (!snapshot.hasData ||
                                              !snapshot.data!.exists) {
                                            return const Center(
                                              child: Text(
                                                'User data not found',
                                              ),
                                            );
                                          }
                                          final d = snapshot.data!.data()!;
                                          return _buildAddressText(
                                            label: '배송지 정보 (기본 배송지)',
                                            name: d['name'] ?? '',
                                            phone: d['phone'] ?? '',
                                            address: d['address'] ?? '',
                                          );
                                        },
                                      );
                                    },
                                  )
                                  : _buildAddressText(
                                    label: '배송지 정보 (기본 배송지)',
                                    name: address.name,
                                    phone: address.phone,
                                    address: address.detailAddress,
                                  ),
                        ),
                        IconButton(
                          onPressed: _selectAddress,
                          icon: Icon(
                            Icons.arrow_forward_ios_sharp,
                            size: 30.r,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  verticalSpace(10),

                  // ── Delivery request ─────────────────────────────────────
                  _buildSectionCard(
                    child: StatefulBuilder(
                      builder: (context, setStateLocal) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '배송 요청사항',
                                    style: TextStyles.abeezee16px400wPblack
                                        .copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  verticalSpace(5),
                                  Text(
                                    selectedRequest,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 16.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  if (selectedRequest == '직접입력') ...[
                                    SizedBox(height: 12.h),
                                    TextFormField(
                                      initialValue: manualRequest,
                                      onChanged: (text) {
                                        setState(() => manualRequest = text);
                                        _saveCachedUserValues();
                                      },
                                      decoration: InputDecoration(
                                        labelText: '직접 입력',
                                        hintText: '배송 요청을 입력하세요',
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 14.h,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 30.r,
                                color: Colors.black,
                              ),
                              onPressed:
                                  () =>
                                      _showDeliveryRequestSheet(setStateLocal),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  verticalSpace(10),

                  // ── Card account ─────────────────────────────────────────
                  _buildSectionCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '결제 카드',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.sp,
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w800,
                                  height: 1.40.h,
                                ),
                              ),
                              verticalSpace(5),
                              Text(
                                cardAccounts.isEmpty
                                    ? '등록된 카드가 없습니다'
                                    : (selectedCardIndex >= 0 &&
                                        selectedCardIndex < cardAccounts.length)
                                    ? '${cardAccounts[selectedCardIndex]['cardName']} '
                                        '(${cardAccounts[selectedCardIndex]['cardNum']})'
                                    : '카드를 선택해주세요',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color:
                                      cardAccounts.isEmpty
                                          ? Colors.red[300]
                                          : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showCardAccountBottomSheet(uid),
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            size: 30.r,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  verticalSpace(10),

                  // ── Receipt / invoice ────────────────────────────────────
                  _buildSectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '현금영수증 · 세금계산서',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.sp,
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w800,
                                  height: 1.40.h,
                                ),
                              ),
                              verticalSpace(5),
                              Text(
                                selectedOption == 1
                                    ? '현금 영수증'
                                    : selectedOption == 2
                                    ? '세금 계산서'
                                    : '필요 없음',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showReceiptBottomSheet(),
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            size: 30.r,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  verticalSpace(15.h),
                ],
              ),
            ),

            // ── Bottom bar ─────────────────────────────────────────────────
            bottomNavigationBar: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('cart')
                      .snapshots(),
              builder: (context, cartSnapshot) {
                if (!cartSnapshot.hasData || cartSnapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }
                return StreamBuilder<int>(
                  stream: calculateCartTotal(cartSnapshot.data!.docs, isSub),
                  builder: (context, totalSnapshot) {
                    final totalPrice = totalSnapshot.data ?? 0;
                    return Container(
                      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 28.h),
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '총 결제 금액 ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.sp,
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.40.h,
                                ),
                              ),
                              totalSnapshot.hasData
                                  ? Text(
                                    '${formatCurrency.format(totalPrice)} 원',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w400,
                                      height: 1.40.h,
                                    ),
                                  )
                                  : const CircularProgressIndicator(),
                            ],
                          ),
                          verticalSpace(8),
                          WideTextButton(
                            txt: '주문',
                            func:
                                isProcessing
                                    ? () {}
                                    : () => _handlePlaceOrder(totalPrice, uid),
                            color: Colors.black,
                            txtColor: Colors.white,
                          ),
                          if (cardAccounts.isEmpty) ...[
                            verticalSpace(8),
                            Text(
                              '* 카드 등록 후 결제가 진행됩니다',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                                fontFamily: 'NotoSans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.fromLTRB(15.w, 15.h, 0, 15.h),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.5, color: Colors.black),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: child,
    );
  }

  Widget _buildNoAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '배송지 미설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15.sp,
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w400,
            height: 1.40.h,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '배송지를 설정해주세요',
          style: TextStyle(
            fontSize: 15.sp,
            color: const Color(0xFF9E9E9E),
            fontFamily: 'NotoSans',
          ),
        ),
      ],
    );
  }

  Widget _buildAddressText({
    required String label,
    required String name,
    required String phone,
    required String address,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.abeezee16px400wPblack.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        verticalSpace(5),
        Text(name, style: _greyStyle()),
        Text(phone, style: _greyStyle()),
        Text(address, style: _greyStyle()),
      ],
    );
  }

  TextStyle _greyStyle() => TextStyle(
    fontSize: 15.sp,
    color: Colors.grey[800],
    fontFamily: 'NotoSans',
    fontWeight: FontWeight.w400,
    height: 1.40.h,
  );

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
                          _saveCachedUserValues();
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
                      WideTextButton(
                        txt: '저장',
                        func: () async {
                          if (!_bottomSheetFormKey.currentState!.validate())
                            return;
                          final success = await _saveCachedUserValues(
                            showFeedback: true,
                          );
                          if (success && mounted) {
                            Navigator.pop(context);
                          }
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
