import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/cart/models/address.dart';
import 'package:ecommerece_app/features/cart/sub_screens/address_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceOrder extends StatefulWidget {
  const PlaceOrder({super.key});

  @override
  State<PlaceOrder> createState() => _PlaceOrderState();
}

class _PlaceOrderState extends State<PlaceOrder> {
  void _showBankAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '계좌 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (bankAccounts.isEmpty)
                      Text(
                        '등록된 계좌가 없습니다.',
                        style: TextStyle(color: Colors.black),
                      ),
                    ...bankAccounts.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var acc = entry.value;
                      return ListTile(
                        title: Text(
                          '${acc['bankName']} / ${acc['bankNumber']}',
                          style: TextStyle(color: Colors.black),
                        ),
                        subtitle: Text(
                          'Payer ID: ${acc['payerId']}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        tileColor:
                            idx == selectedBankIndex
                                ? Colors.black12
                                : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () {
                          setState(() {
                            selectedBankIndex = idx;
                            isAddingNewBank = false;
                          });
                          setStateDialog(() {});
                          Navigator.of(context).pop();
                        },
                      );
                    }).toList(),
                    Divider(height: 32, color: Colors.black),
                    ListTile(
                      title: Text(
                        '새 계좌로 결제',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      tileColor:
                          selectedBankIndex == -1
                              ? Colors.black12
                              : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () {
                        setState(() {
                          selectedBankIndex = -1;
                          isAddingNewBank = true;
                        });
                        setStateDialog(() {});
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchBankAccounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data();
    if (data != null && data['bankAccounts'] != null) {
      final accounts = List<Map<String, dynamic>>.from(data['bankAccounts']);
      setState(() {
        bankAccounts = accounts;
        selectedBankIndex = accounts.isNotEmpty ? 0 : -1;
      });
    } else {
      setState(() {
        bankAccounts = [];
        selectedBankIndex = -1;
      });
    }
  }

  List<Map<String, dynamic>> bankAccounts = [];
  int selectedBankIndex = -1;
  bool isAddingNewBank = false;
  final deliveryAddressController = TextEditingController();
  final deliveryInstructionsController = TextEditingController();
  final cashReceiptController = TextEditingController();
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final emailController =
      TextEditingController(); // NEW: email field controller
  int selectedOption = 1;
  final _formKey = GlobalKey<FormState>();
  Address address = Address(
    id: '',
    name: '',
    phone: '',
    address: '',
    detailAddress: '',
    isDefault: false,
    addressMap: {},
  );
  final List<String> deliveryRequests = [
    '문앞',
    '직접 받고 부재 시 문앞',
    '택배함',
    '경비실',
    '직접입력',
  ];
  String selectedRequest = '문앞';
  String? manualRequest;
  bool isProcessing = false;
  String? currentPaymentId;
  final Set<String> _finalizedPayments = {};
  int paymentMethod = 0;
  Map<String, dynamic>? userBank;
  Map<String, dynamic>? userCard;
  Timer? _paymentTimeoutTimer;
  String? _timeoutPaymentId;

  Future<void> _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddressListScreen()),
    );
    if (result != null) {
      deliveryAddressController.text = result.address;
      setState(() {
        address = result;
      });
    }
  }

  final formatCurrency = NumberFormat('#,###');

  Future<void> _handlePlaceOrder(int totalPrice, String uid) async {
    if (!_formKey.currentState!.validate()) return;
    // Save name/phone/email to cache before placing order
    await _saveCachedUserValues();
    setState(() {
      isProcessing = true;
    });
    try {
      if (deliveryAddressController.text.isEmpty) {
        final userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get();
        if (userData['defaultAddressId'] == null ||
            userData['defaultAddressId'] == '') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('배송 주소를 선택해주세요.')));
          setState(() {
            isProcessing = false;
          });
          return;
        } else {
          final defaultAddressDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('addresses')
                  .doc(userData['defaultAddressId'])
                  .get();
          final defaultAddress =
              defaultAddressDoc.data() as Map<String, dynamic>;
          deliveryAddressController.text = defaultAddress['address'];
          address = Address(
            id: defaultAddress['id'],
            name: defaultAddress['name'],
            phone: defaultAddress['phone'],
            address: defaultAddress['address'],
            detailAddress: defaultAddress['detailAddress'],
            isDefault: defaultAddress['isDefault'],
            addressMap: defaultAddress['addressMap'],
          );
        }
      }

      final cartSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('cart')
              .get();
      final cartItems = cartSnapshot.docs.map((doc) => doc.data()).toList();
      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('장바구니가 비어 있습니다.')));
        setState(() {
          isProcessing = false;
        });
        return;
      }
      for (var item in cartItems) {
        final productId = item['product_id'];
        final quantityOrdered = item['quantity'];
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(productId);
        final productSnapshot = await productRef.get();
        if (!productSnapshot.exists) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('상품이 더 이상 존재하지 않습니다.')));
          setState(() {
            isProcessing = false;
          });
          return;
        }
        final currentStock = productSnapshot.data()?['stock'] ?? 0;
        if (quantityOrdered is! int || quantityOrdered <= 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('주문 수량이 올바르지 않습니다.')));
          setState(() {
            isProcessing = false;
          });
          return;
        }
        if (currentStock < quantityOrdered) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '재고가 부족한 상품이 있습니다. (주문 수량: $quantityOrdered, 남은 재고: $currentStock)',
              ),
            ),
          );
          setState(() {
            isProcessing = false;
          });
          return;
        }
      }
      final docRef = FirebaseFirestore.instance.collection('orders').doc();
      final paymentId = docRef.id;
      currentPaymentId = paymentId;
      final pendingOrderRef =
          FirebaseFirestore.instance.collection('pending_orders').doc();
      final productIds = cartItems.map((item) => item['product_id']).toList();
      final quantities = cartItems.map((item) => item['quantity']).toList();
      final prices = cartItems.map((item) => item['price']).toList();
      final deliveryManagerIds =
          cartItems.map((item) => item['deliveryManagerId']).toList();
      final orderData = {
        'pendingOrderId': pendingOrderRef.id,
        'userId': uid,
        'paymentId': paymentId,
        'deliveryAddressId': address.id,
        'deliveryAddress': deliveryAddressController.text.trim(),
        'deliveryAddressDetail': address.detailAddress,
        'deliveryInstructions':
            selectedRequest == '직접입력'
                ? manualRequest?.trim() ?? ''
                : selectedRequest.trim(),
        'cashReceipt': cashReceiptController.text.trim(),
        'paymentMethod': 'bank',
        'orderDate': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'totalPrice': totalPrice,
        'productIds': productIds,
        'quantities': quantities,
        'prices': prices,
        'orderStatus': 'pending',
        'status': 'pending',
        'isRequested': false,
        'deliveryManagerIds': deliveryManagerIds,
        'carrierId': '',
        'isSent': false,
        'confirmed': false,
        'phoneNo': phoneController.text.trim(),
      };
      await pendingOrderRef.set(orderData);
      String? payerId;
      if (bankAccounts.isNotEmpty &&
          selectedBankIndex >= 0 &&
          selectedBankIndex < bankAccounts.length) {
        payerId = bankAccounts[selectedBankIndex]['payerId'] as String?;
      } else {
        payerId = null;
      }
      _startPaymentTimeout(paymentId, pendingOrderRef);

      if (payerId != null && payerId.isNotEmpty) {
        _launchBankRpaymentPage(
          totalPrice.toString(),
          uid,
          phoneController.text.trim(),
          paymentId,
          payerId,
          nameController.text.trim(), // pass name
          emailController.text.trim(), // pass email
        );
      } else {
        _launchBankPaymentPage(
          totalPrice.toString(),
          uid,
          phoneController.text.trim(),
          paymentId,
          nameController.text.trim(), // pass name
          emailController.text.trim(), // pass email
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('주문 처리 중 오류가 발생했습니다. 다시 시도해주세요.')));
      setState(() {
        isProcessing = false;
      });
    }
  }

  Stream<QuerySnapshot>? get _pendingOrdersStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (currentPaymentId == null || uid == null) return null;
    return FirebaseFirestore.instance
        .collection('pending_orders')
        .where('userId', isEqualTo: uid)
        .where('paymentId', isEqualTo: currentPaymentId)
        .snapshots();
  }

  Widget _buildPaymentButton(int totalPrice, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('pending_orders')
              .where('userId', isEqualTo: uid)
              .where('paymentId', isEqualTo: currentPaymentId)
              .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final pendingDoc = docs.isNotEmpty ? docs.first : null;
        final status =
            pendingDoc != null ? pendingDoc['status'] as String : null;
        if (pendingDoc == null) {
          return WideTextButton(
            txt: '주문',
            func: () => _handlePlaceOrder(totalPrice, uid),
            color: Colors.black,
            txtColor: Colors.white,
          );
        }
        if (status == 'failed') {
          _cancelPaymentTimeoutIfNeeded(
            pendingDoc['paymentId'] as String?,
            status,
          );
          return Column(
            children: [
              WideTextButton(
                txt: '주문',
                func: () async {
                  await pendingDoc.reference.update({'status': 'pending'});
                  final data = pendingDoc.data() as Map<String, dynamic>;
                  final payerId =
                      (userBank != null
                          ? userBank!['payerId'] as String?
                          : null);

                  if (payerId != null && payerId.isNotEmpty) {
                    _launchBankRpaymentPage(
                      (data['totalPrice'] ?? '').toString(),
                      data['userId'] ?? uid,
                      data['phoneNo'] ?? '',
                      data['paymentId'] ?? '',
                      payerId,
                      nameController.text.trim(), // pass name
                      emailController.text.trim(), // pass email
                    );
                  } else {
                    _launchBankPaymentPage(
                      (data['totalPrice'] ?? '').toString(),
                      data['userId'] ?? uid,
                      data['phoneNo'] ?? '',
                      data['paymentId'] ?? '',
                      nameController.text.trim(), // pass name
                      emailController.text.trim(), // pass email
                    );
                  }
                },
                color: Colors.black,
                txtColor: Colors.white,
              ),
              SizedBox(height: 8.h),
              Text('결제 실패. 다시 시도해주세요.', style: TextStyle(color: Colors.red)),
            ],
          );
        }
        if (status == 'success') {
          _cancelPaymentTimeoutIfNeeded(
            pendingDoc['paymentId'] as String?,
            status,
          );
          final paymentId = pendingDoc['paymentId'] as String?;
          if (paymentId != null && !_finalizedPayments.contains(paymentId)) {
            _finalizedPayments.add(paymentId);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _finalizeOrderAfterPayment([pendingDoc], uid);
            });
          }
          return Column(
            children: [
              SizedBox(height: 8.h),
              Text(
                isProcessing
                    ? '결제 성공! 주문을 완료 처리 중입니다...'
                    : '주문이 성공적으로 완료되었습니다!',
                style: TextStyle(color: Colors.green),
              ),
              if (isProcessing) ...[
                SizedBox(height: 8.h),
                CircularProgressIndicator(),
              ],
            ],
          );
        }
        if (status == 'pending') {
          return Column(
            children: [
              WideTextButton(
                txt: '결제 진행 중... 취소',
                func: () async {
                  // Cancel the pending order and reset state
                  await pendingDoc.reference.delete();
                  setState(() {
                    currentPaymentId = null;
                    isProcessing = false;
                  });
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                color: Colors.grey.shade400, // Keep original color
                txtColor: Colors.white,
              ),
              SizedBox(height: 8.h),
              CircularProgressIndicator(),
              SizedBox(height: 8.h),
              Text(
                '결제 대기 중입니다. 결제를 취소하려면 위 버튼을 누르세요.',
                style: TextStyle(color: Colors.black),
              ),
            ],
          );
        }
        return WideTextButton(
          txt: '주문',
          func: () => _handlePlaceOrder(totalPrice, uid),
          color: Colors.black,
          txtColor: Colors.white,
        );
      },
    );
  }

  Future<void> _finalizeOrderAfterPayment(
    List<QueryDocumentSnapshot> pendingDocs,
    String uid,
  ) async {
    if (!mounted) return;
    setState(() {
      isProcessing = true;
    });
    try {
      if (pendingDocs.isEmpty) return;
      final doc = pendingDocs.first;
      final data = doc.data() as Map<String, dynamic>;
      final productIds = List.from(data['productIds'] ?? []);
      final quantities = List.from(data['quantities'] ?? []);
      final prices = List.from(data['prices'] ?? []);
      final deliveryManagerIds = List.from(data['deliveryManagerIds'] ?? []);
      for (int i = 0; i < productIds.length; i++) {
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(productIds[i]);
        final productSnapshot = await productRef.get();
        final currentStock = productSnapshot.data()?['stock'] ?? 0;
        final orderQty = quantities[i];
        if (currentStock < orderQty || orderQty <= 0) {
          continue;
        }
        final orderRef = FirebaseFirestore.instance.collection('orders').doc();
        final orderData = {
          'orderId': orderRef.id,
          'userId': data['userId'],
          'paymentId': data['paymentId'],
          'deliveryAddressId': data['deliveryAddressId'],
          'deliveryAddress': data['deliveryAddress'],
          'deliveryAddressDetail': data['deliveryAddressDetail'],
          'deliveryInstructions': data['deliveryInstructions'],
          'cashReceipt': data['cashReceipt'],
          'paymentMethod': data['paymentMethod'],
          'orderDate': data['orderDate'],
          'totalPrice': prices[i],
          'productId': productIds[i],
          'quantity': orderQty,
          'courier': '',
          'trackingNumber': '',
          'trackingEvents': {},
          'orderStatus': 'orderComplete',
          'isRequested': data['isRequested'],
          'deliveryManagerId': deliveryManagerIds[i],
          'carrierId': '',
          'isSent': false,
          'confirmed': false,
          'phoneNo': data['phoneNo'],
        };
        await orderRef.set(orderData);
        await productRef.update({'stock': FieldValue.increment(-orderQty)});

        // Add to order_settlement collection for settlement automation
        final settlementRef = FirebaseFirestore.instance
            .collection('order_settlement')
            .doc(orderRef.id);
        await settlementRef.set({
          'orderId': orderRef.id,
          'price': prices[i],
          'deliveryManagerId': deliveryManagerIds[i],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await doc.reference.delete();
      final cartSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('cart')
              .get();
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        setState(() {
          isProcessing = false;
          currentPaymentId = null;
        });
        context.go(Routes.orderCompleteScreen);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('주문 완료 처리 중 오류가 발생했습니다.')));
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _startPaymentTimeout(
    String paymentId,
    DocumentReference pendingOrderRef,
  ) {
    _paymentTimeoutTimer?.cancel();
    _timeoutPaymentId = paymentId;
    _paymentTimeoutTimer = Timer(Duration(minutes: 2), () async {
      final doc = await pendingOrderRef.get();
      if (doc.exists &&
          (doc.data() as Map<String, dynamic>)['status'] == 'pending') {
        await pendingOrderRef.update({'status': 'failed'});
        if (mounted) setState(() {});
      }
    });
  }

  void _cancelPaymentTimeoutIfNeeded(String? paymentId, String? status) {
    if (_paymentTimeoutTimer != null &&
        _timeoutPaymentId == paymentId &&
        status != 'pending') {
      _paymentTimeoutTimer?.cancel();
      _paymentTimeoutTimer = null;
      _timeoutPaymentId = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
    _fetchUserPaymentInfo();
    _loadCachedUserValues(); // NEW: load cached name/phone
  }

  Future<void> _loadCachedUserValues() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('usercached_values')
            .doc(uid)
            .get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
      }
    }
  }

  Future<void> _saveCachedUserValues() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('usercached_values')
        .doc(uid)
        .set({
          'userId': uid,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
        }, SetOptions(merge: true));
  }

  Future<void> _fetchUserPaymentInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data();
    print('Fetched user data:');
    print(data);
    setState(() {
      userBank = data?['bank'] as Map<String, dynamic>?;
      print('userBank:');
      print(userBank);
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios),
          ),
          title: Text("주문 결제", style: TextStyle(fontFamily: 'NotoSans')),
        ),
        body: Padding(
          padding: EdgeInsets.only(left: 15.w, top: 30.h, right: 15.w),
          child: ListView(
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: 15.w,
                  top: 15.h,
                  bottom: 15.h,
                  right: 15.w,
                ),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 0.27,
                      color: const Color(0xFF747474),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.only(bottom: 5.h),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: ColorsManager.primary400,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child:
                                  address.name.isEmpty
                                      ? FutureBuilder(
                                        future:
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(
                                                  FirebaseAuth
                                                      .instance
                                                      .currentUser!
                                                      .uid,
                                                )
                                                .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }

                                          if (snapshot.hasError) {
                                            return Center(
                                              child: Text(
                                                'Error loading user address: ${snapshot.error}',
                                              ),
                                            );
                                          }

                                          if (!snapshot.hasData ||
                                              !snapshot.data!.exists) {
                                            return Center(
                                              child: Text(
                                                'User data not found',
                                              ),
                                            );
                                          }

                                          final userData =
                                              snapshot.data?.data();
                                          if (userData == null ||
                                              userData['defaultAddressId'] ==
                                                  null ||
                                              userData['defaultAddressId'] ==
                                                  '') {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                    color: Color(0xFF9E9E9E),
                                                    fontFamily: 'NotoSans',
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          return FutureBuilder(
                                            future:
                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(
                                                      FirebaseAuth
                                                          .instance
                                                          .currentUser!
                                                          .uid,
                                                    )
                                                    .collection('addresses')
                                                    .doc(
                                                      userData['defaultAddressId'],
                                                    )
                                                    .get(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }

                                              if (snapshot.hasError) {
                                                return Center(
                                                  child: Text(
                                                    'Error loading user address: ${snapshot.error}',
                                                  ),
                                                );
                                              }

                                              if (!snapshot.hasData ||
                                                  !snapshot.data!.exists) {
                                                return Center(
                                                  child: Text(
                                                    'User data not found',
                                                  ),
                                                );
                                              }

                                              final addressData =
                                                  snapshot.data?.data();
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '베송지 | ${addressData!['name']}',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15.sp,
                                                      fontFamily: 'NotoSans',
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      height: 1.40.h,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8.h),

                                                  Text(
                                                    addressData['phone'],
                                                    style: TextStyle(
                                                      fontSize: 15.sp,
                                                      color: Color(0xFF9E9E9E),
                                                      fontFamily: 'NotoSans',
                                                    ),
                                                  ),
                                                  Text(
                                                    addressData['address'],
                                                    style: TextStyle(
                                                      fontSize: 15.sp,
                                                      color: Color(0xFF9E9E9E),
                                                      fontFamily: 'NotoSans',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      )
                                      : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '베송지 | ${address.name}',
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
                                            address.phone,
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              color: Color(0xFF9E9E9E),
                                              fontFamily: 'NotoSans',
                                            ),
                                          ),
                                          Text(
                                            address.detailAddress,
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              color: Color(0xFF9E9E9E),
                                              fontFamily: 'NotoSans',
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                            TextButton(
                              onPressed: _selectAddress,
                              style: TextButton.styleFrom(
                                fixedSize: Size(48.w, 30.h),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              child: Text(
                                '변경',
                                style: TextStyle(
                                  color: ColorsManager.primaryblack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        '배송 요청사항',
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 16.sp,
                          fontFamily: 'NotoSans',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),
                      StatefulBuilder(
                        builder: (context, setStateDropdown) {
                          return DropdownButtonFormField<String>(
                            value: selectedRequest,
                            dropdownColor: Colors.white,
                            items:
                                deliveryRequests
                                    .map(
                                      (request) => DropdownMenuItem(
                                        value: request,
                                        child: Text(
                                          request,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16.sp,
                                            fontFamily: 'NotoSans',
                                            fontWeight: FontWeight.w400,
                                            height: 1.40.h,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              setStateDropdown(() {
                                selectedRequest = value!;
                                // clear manual text when switching away
                                if (selectedRequest != '직접입력')
                                  manualRequest = null;
                              });
                              // also notify parent state if needed:
                              setState(() {});
                            },
                            icon: Icon(Icons.keyboard_arrow_down),
                          );
                        },
                      ),
                      // only show when “직접입력” is selected:
                      if (selectedRequest == '직접입력') ...[
                        SizedBox(height: 12.h),
                        TextFormField(
                          initialValue: manualRequest,
                          onChanged:
                              (text) => setState(() => manualRequest = text),
                          decoration: InputDecoration(
                            labelText: '직접 입력',
                            hintText: '배송 요청을 입력하세요',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 14.h,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 15.h),
                      Text(
                        paymentMethod == 0 ? '간편 계좌 결제' : '간편 카드 결제',
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 16.sp,
                          fontFamily: 'NotoSans',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: ColorsManager.primary400,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: TextFormField(
                                controller: cashReceiptController,
                                enabled: false,
                                decoration: InputDecoration(
                                  hintText:
                                      (bankAccounts.isNotEmpty &&
                                              selectedBankIndex >= 0 &&
                                              selectedBankIndex <
                                                  bankAccounts.length)
                                          ? '${bankAccounts[selectedBankIndex]['bankName']} / ${bankAccounts[selectedBankIndex]['bankNumber']}'
                                          : '등록된 계좌가 없습니다.',
                                  hintStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: ColorsManager.primary400,
                                  ),
                                  border: InputBorder.none,
                                ),
                                obscureText: false,
                                keyboardType: TextInputType.text,
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  isProcessing ? null : _showBankAccountDialog,
                              style: TextButton.styleFrom(
                                fixedSize: Size(48.w, 30.h),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                              child: Text(
                                '변경',
                                style: TextStyle(
                                  color: ColorsManager.primaryblack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatefulBuilder(
                        builder: (context, setStateRadio) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Radio(
                                    value: 1,
                                    groupValue: selectedOption,
                                    onChanged: (value) {
                                      setStateRadio(() {
                                        selectedOption = value!;
                                        print("Button value: $value");
                                      });
                                    },
                                  ),
                                  Text(
                                    '현금 영수증',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w400,
                                      color: ColorsManager.primaryblack,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio(
                                    value: 2,
                                    groupValue: selectedOption,
                                    onChanged: (value) {
                                      setStateRadio(() {
                                        selectedOption = value!;
                                        print("Button value: $value");
                                      });
                                    },
                                  ),
                                  Text(
                                    '세금 계산서',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w400,
                                      color: ColorsManager.primaryblack,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      UnderlineTextField(
                        controller: nameController,
                        hintText: '이름',
                        obscureText: false,
                        keyboardType: TextInputType.text,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return '이름을 입력해주세요';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          _saveCachedUserValues();
                        },
                      ),
                      SizedBox(height: 10.h),
                      UnderlineTextField(
                        controller: emailController,
                        hintText: '이메일',
                        obscureText: false,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return '이메일을 입력해주세요';
                          }
                          // Simple email validation
                          if (!RegExp(r'^.+@.+\..+$').hasMatch(val.trim())) {
                            return '유효한 이메일을 입력해주세요';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          _saveCachedUserValues();
                        },
                      ),
                      SizedBox(height: 10.h),
                      UnderlineTextField(
                        controller: phoneController,
                        hintText: '전화번호 ',
                        obscureText: false,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return '전화번호를 입력해주세요';
                          }
                          final koreanReg = RegExp(
                            r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$',
                          );
                          if (!koreanReg.hasMatch(val)) {
                            return '유효한 한국 전화번호를 입력하세요';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          _saveCachedUserValues();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              verticalSpace(20.h),
              Container(
                padding: EdgeInsets.only(left: 15.w, top: 15.h, bottom: 15.h),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 0.27,
                      color: const Color(0xFF747474),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('구매목록', style: TextStyles.abeezee16px400wPblack),
                    verticalSpace(10.h),
                    StreamBuilder(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                              .collection('cart')
                              .snapshots(),
                      builder: (context6, cartSnapshot) {
                        if (cartSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final cartDocs = cartSnapshot.data!.docs;

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          separatorBuilder: (context5, index) {
                            if (index == cartDocs.length - 1) {
                              return SizedBox.shrink();
                            }
                            return Divider();
                          },
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
                              builder: (context4, productSnapshot) {
                                if (!productSnapshot.hasData) {
                                  return ListTile(title: Text('로딩 중...'));
                                }
                                final productData =
                                    productSnapshot.data!.data()
                                        as Map<String, dynamic>;

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${productData['productName']} / 수량 : ${cartData['quantity'].toString()}',
                                      style: TextStyle(
                                        color: const Color(0xFF747474),
                                        fontSize: 14.sp,
                                        fontFamily: 'NotoSans',
                                        fontWeight: FontWeight.w400,
                                        height: 1.40.h,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      '${formatCurrency.format(cartData['price'] ?? 0)} 원',
                                      style: TextStyle(
                                        color: const Color(0xFF747474),
                                        fontSize: 14.sp,
                                        fontFamily: 'NotoSans',
                                        fontWeight: FontWeight.w600,
                                        height: 1.40.h,
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
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                        .collection('cart')
                        .snapshots(),
                builder: (context3, cartSnapshot) {
                  if (!cartSnapshot.hasData ||
                      cartSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return FutureBuilder<int>(
                    future: calculateCartTotal(cartSnapshot.data!.docs),
                    builder: (context2, totalSnapshot) {
                      final totalPrice = totalSnapshot.data ?? 0;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          verticalSpace(20.h),
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
                                  : CircularProgressIndicator(),
                            ],
                          ),
                          _buildPaymentButton(totalPrice, uid),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> calculateCartTotalPay() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('No user logged in');
    }
    final querySnap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('cart')
            .get();
    var total = 0;
    for (final doc in querySnap.docs) {
      final data = doc.data();
      final price = data['price'];
      if (price is num) {
        total += price.toInt();
      }
    }
    return total;
  }

  Future<int> calculateCartTotal(List<QueryDocumentSnapshot> cartDocs) async {
    int total = 0;
    for (final cartDoc in cartDocs) {
      final cartData = cartDoc.data() as Map<String, dynamic>;
      final price = cartData['price'];
      try {
        total += price as int;
      } catch (e) {}
    }
    return total;
  }

  void _launchBankPaymentPage(
    String amount,
    String userId,
    String phoneNo,
    String paymentId,
    String userName,
    String email,
  ) async {
    final url = Uri.parse(
      'https://pay.pang2chocolate.com/b-payment.html?paymentId=$paymentId&amount=$amount&userId=$userId&phoneNo=$phoneNo&userName=$userName&email=$email',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchBankRpaymentPage(
    String amount,
    String userId,
    String phoneNo,
    String paymentId,
    String payerId,
    String userName,
    String email,
  ) async {
    final url = Uri.parse(
      'https://pay.pang2chocolate.com/r-b-payment.html?paymentId=$paymentId&amount=$amount&userId=$userId&phoneNo=$phoneNo&payerId=$payerId&userName=$userName&email=$email',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
