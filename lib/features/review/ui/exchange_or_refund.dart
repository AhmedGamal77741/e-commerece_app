// ignore_for_file: deprecated_member_use
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/review/data/review_repository.dart';
import 'package:ecommerece_app/features/review/domain/review_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ExchangeOrRefund extends ConsumerStatefulWidget {
  final String userId;
  final String orderId;

  const ExchangeOrRefund({
    super.key,
    required this.userId,
    required this.orderId,
  });

  @override
  ConsumerState<ExchangeOrRefund> createState() => _ExchangeOrRefundState();
}

class _ExchangeOrRefundState extends ConsumerState<ExchangeOrRefund> {
  int _currentStep = 1;
  bool _isLoading = true;

  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _productData;

  // Page 1 Data
  String? _reasonType; // 'change_mind' or 'other'
  final _detailReasonController = TextEditingController();

  // Page 2 Data
  String? _resolutionType; // 'refund' or 'exchange'
  String? _collectionSpot; // '문 앞', '경비실', '그 외 장소'
  final _otherSpotController = TextEditingController();
  String? _collectionDate; // '내일', '다른 날 선택하기'
  DateTime? _customDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {

      final repo = ref.read(reviewRepositoryProvider);
      final order = await repo.getOrder(widget.orderId);
      if (order != null) {
        final product = await repo.getProduct(order['productId']);
        setState(() {
          _orderData = order;
          _productData = product;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터를 불러오지 못했습니다.')));
        context.pop();
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_reasonType == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('사유를 선택해주세요.')));
        return;
      }
      if (_detailReasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('상세 사유를 입력해주세요.')));
        return;
      }
      if (_reasonType == 'change_mind') {
        _resolutionType = 'refund'; // Only refund allowed
      }
    } else if (_currentStep == 2) {
      if (_resolutionType == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('해결 방법을 선택해주세요.')));
        return;
      }
      if (_collectionSpot == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('상품 회수지를 선택해주세요.')));
        return;
      }
      if (_collectionSpot == '그 외 장소' &&
          _otherSpotController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('상세 장소를 입력해주세요.')));
        return;
      }
      if (_collectionDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('회수 예정일을 선택해주세요.')));
        return;
      }
      if (_collectionDate == '다른 날 선택하기' && _customDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('날짜를 선택해주세요.')));
        return;
      }
    }
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
  }

  Future<void> _submit() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final expectedRefund = _calculateRefund();

      final requestData = {
        'type': _resolutionType,
        'reasonType': _reasonType,
        'detailReason': _detailReasonController.text.trim(),
        'collectionSpot':
            _collectionSpot == '그 외 장소'
                ? _otherSpotController.text.trim()
                : _collectionSpot,
        'collectionDate':
            _collectionDate == '내일' ? '내일' : _customDate?.toIso8601String(),
        'expectedRefund': expectedRefund,
      };

      await ref
          .read(reviewControllerProvider.notifier)
          .submitRequest(widget.orderId, requestData);

      if (!mounted) return;
      Navigator.pop(context); // close dialog

      setState(() {
        _currentStep = 4; // completion step
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  int _calculateRefund() {
    final totalPrice = _orderData?['totalPrice'] ?? 0;
    if (_reasonType == 'change_mind') {
      final shippingFee = _productData?['deliveryPrice'] ?? 4000;
      return totalPrice - shippingFee;
    }
    return totalPrice;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('교환/반품 요청', style: TextStyles.abeezee16px400wPblack),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(color: ColorsManager.primary500),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('교환/반품 요청', style: TextStyles.abeezee16px400wPblack),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 1 && _currentStep < 4) {
              _prevStep();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentStep < 4) ...[
                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        height: 4.h,
                        decoration: BoxDecoration(
                          color:
                              _currentStep > index
                                  ? ColorsManager.primary500
                                  : ColorsManager.primary100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                verticalSpace(20),
              ],

              if (_currentStep == 1) _buildStep1(),
              if (_currentStep == 2) _buildStep2(),
              if (_currentStep == 3) _buildStep3(),
              if (_currentStep == 4) _buildStep4(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('사유 선택', style: TextStyles.abeezee20px400wPblack),
        verticalSpace(20),

        RadioListTile<String>(
          title: Text('단순변심으로 반품하기', style: TextStyles.abeezee16px400wPblack),
          value: 'change_mind',
          groupValue: _reasonType,
          activeColor: ColorsManager.primary500,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) => setState(() => _reasonType = value),
        ),
        if (_reasonType == 'change_mind') ...[
          Padding(
            padding: EdgeInsets.only(left: 32.w),
            child: Text(
              '* 제품의 훼손ㆍ사용 흔적이 있을 경우 단순변심으로 반품은 불가합니다.',
              style: TextStyle(
                color: ColorsManager.primary400,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],

        RadioListTile<String>(
          title: Text('기타 사유', style: TextStyles.abeezee16px400wPblack),
          value: 'other',
          groupValue: _reasonType,
          activeColor: ColorsManager.primary500,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) => setState(() => _reasonType = value),
        ),
        if (_reasonType == 'other') ...[
          Padding(
            padding: EdgeInsets.only(left: 32.w),
            child: Text(
              '* 상품하자, 오배송, 파손 등',
              style: TextStyle(
                color: ColorsManager.primary400,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],

        if (_reasonType != null) ...[
          verticalSpace(20),
          Container(
            decoration: ShapeDecoration(
              color: ColorsManager.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: ColorsManager.primary100),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: TextFormField(
              controller: _detailReasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '상세 사유를 입력해 주세요.',
                hintStyle: TextStyles.abeezee14px400wP600,
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),
        ],

        verticalSpace(40),
        WideTextButton(
          txt: '다음',
          color: ColorsManager.primary500,
          txtColor: ColorsManager.white,
          func: _nextStep,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_reasonType == 'other') ...[
          Text('해결 방법 선택', style: TextStyles.abeezee20px400wPblack),
          verticalSpace(10),
          RadioListTile<String>(
            title: Text('새상품 교환', style: TextStyles.abeezee16px400wPblack),
            value: 'exchange',
            groupValue: _resolutionType,
            activeColor: ColorsManager.primary500,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(() => _resolutionType = value),
          ),
          RadioListTile<String>(
            title: Text('반품 후 환불', style: TextStyles.abeezee16px400wPblack),
            value: 'refund',
            groupValue: _resolutionType,
            activeColor: ColorsManager.primary500,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(() => _resolutionType = value),
          ),
          verticalSpace(30),
        ],

        Text('상품 회수지', style: TextStyles.abeezee20px400wPblack),
        verticalSpace(10),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorsManager.primary100.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이름: ${_orderData?['customerName'] ?? ''}',
                style: TextStyles.abeezee13px400wPblack,
              ),
              verticalSpace(5),
              Text(
                '전화번호: ${_orderData?['phoneNo'] ?? ''}',
                style: TextStyles.abeezee13px400wPblack,
              ),
              verticalSpace(5),
              Text(
                '주소: ${_orderData?['deliveryAddress'] ?? ''} ${_orderData?['deliveryAddressDetail'] ?? ''}',
                style: TextStyles.abeezee13px400wPblack,
              ),
            ],
          ),
        ),
        verticalSpace(10),
        RadioListTile<String>(
          title: Text('문 앞', style: TextStyles.abeezee16px400wPblack),
          value: '문 앞',
          groupValue: _collectionSpot,
          activeColor: ColorsManager.primary500,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) => setState(() => _collectionSpot = value),
        ),
        RadioListTile<String>(
          title: Text('경비실', style: TextStyles.abeezee16px400wPblack),
          value: '경비실',
          groupValue: _collectionSpot,
          activeColor: ColorsManager.primary500,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) => setState(() => _collectionSpot = value),
        ),
        RadioListTile<String>(
          title: Text('그 외 장소', style: TextStyles.abeezee16px400wPblack),
          value: '그 외 장소',
          groupValue: _collectionSpot,
          activeColor: ColorsManager.primary500,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) => setState(() => _collectionSpot = value),
        ),
        if (_collectionSpot == '그 외 장소') ...[
          Container(
            margin: EdgeInsets.only(left: 32.w, right: 10.w, bottom: 10.h),
            decoration: ShapeDecoration(
              color: ColorsManager.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: ColorsManager.primary100),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: TextFormField(
              controller: _otherSpotController,
              decoration: InputDecoration(
                hintText: '장소를 정확히 입력해주세요',
                hintStyle: TextStyles.abeezee14px400wP600,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],

        verticalSpace(30),
        Text('회수 예정일', style: TextStyles.abeezee20px400wPblack),
        verticalSpace(5),
        Text(
          '* 상품은 회수 예정일 오전 09시까지 회수지에 놓아주세요.',
          style: TextStyle(color: ColorsManager.primary400, fontSize: 12.sp),
        ),
        verticalSpace(10),
        RadioListTile<String>(
          title: Text('내일', style: TextStyles.abeezee16px400wPblack),
          value: '내일',
          groupValue: _collectionDate,
          activeColor: ColorsManager.primary500,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) => setState(() => _collectionDate = value),
        ),
        RadioListTile<String>(
          title: Text('다른 날 선택하기', style: TextStyles.abeezee16px400wPblack),
          value: '다른 날 선택하기',
          groupValue: _collectionDate,
          activeColor: ColorsManager.primary500,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) async {
            setState(() => _collectionDate = value);
            if (value == '다른 날 선택하기') {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(Duration(days: 2)),
                firstDate: DateTime.now().add(Duration(days: 1)),
                lastDate: DateTime.now().add(Duration(days: 30)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: ColorsManager.primary500,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _customDate = date);
              }
            }
          },
        ),
        if (_collectionDate == '다른 날 선택하기' && _customDate != null) ...[
          Padding(
            padding: EdgeInsets.only(left: 32.w, bottom: 10.h),
            child: Text(
              '선택됨: ${DateFormat('yyyy-MM-dd').format(_customDate!)}',
              style: TextStyles.abeezee13px400wPblack,
            ),
          ),
        ],

        verticalSpace(40),
        WideTextButton(
          txt: '다음',
          color: ColorsManager.primary500,
          txtColor: ColorsManager.white,
          func: _nextStep,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final totalPrice = _orderData?['totalPrice'] ?? 0;
    final expectedRefund = _calculateRefund();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_reasonType == 'change_mind') ...[
          Text('단순변심 환불 규정 안내', style: TextStyles.abeezee20px400wPblack),
          verticalSpace(10),
          Text(
            '* 제품의 훼손ㆍ사용 흔적이 있을 경우 단순변심으로 반품은 불가합니다.',
            style: TextStyles.abeezee13px400wPblack,
          ),
          verticalSpace(5),
          Text(
            '* 제품의 훼손ㆍ사용 흔적 여부 검수 후 상품 금액에서 반품 배송비를 차감한 금액이 환불 됩니다.',
            style: TextStyles.abeezee13px400wPblack,
          ),
          verticalSpace(30),
        ],

        Text('예상 환불금액 확인하기', style: TextStyles.abeezee20px400wPblack),
        verticalSpace(10),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorsManager.primary100.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_reasonType == 'change_mind') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('상품 금액', style: TextStyles.abeezee13px400wPblack),
                    Text(
                      '${NumberFormat('#,###').format(totalPrice)}원',
                      style: TextStyles.abeezee13px400wPblack,
                    ),
                  ],
                ),
                verticalSpace(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('반품 배송비', style: TextStyles.abeezee13px400wPblack),
                    Text(
                      '- ${NumberFormat('#,###').format(totalPrice - expectedRefund)}원',
                      style: TextStyle(color: Colors.red, fontSize: 14.sp),
                    ),
                  ],
                ),
                verticalSpace(10),
                Divider(color: ColorsManager.primary400),
                verticalSpace(10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '예상 환불금액',
                    style: TextStyles.abeezee16px400wPblack.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,###').format(expectedRefund)}원',
                    style: TextStyles.abeezee18px400wPblack,
                  ),
                ],
              ),
            ],
          ),
        ),

        verticalSpace(40),
        WideTextButton(
          txt: '요청 완료하기',
          color: ColorsManager.primary500,
          txtColor: ColorsManager.white,
          func: _submit,
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          verticalSpace(50),
          Icon(
            Icons.check_circle,
            color: ColorsManager.primary500,
            size: 80.sp,
          ),
          verticalSpace(20),
          Text(
            _resolutionType == 'exchange'
                ? '교환 요청이 완료되었습니다.'
                : '반품 요청이 완료되었습니다.',
            style: TextStyles.abeezee20px400wPblack,
          ),
          verticalSpace(40),
          WideTextButton(
            txt: '돌아가기',
            color: ColorsManager.primaryblack,
            txtColor: ColorsManager.white,
            func: () {
              context.pop(); // go back
            },
          ),
        ],
      ),
    );
  }
}
