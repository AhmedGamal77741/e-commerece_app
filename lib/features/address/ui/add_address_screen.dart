import 'package:ecommerece_app/features/cart/services/kakao_service.dart';
import 'package:ecommerece_app/features/address/ui/address_search_dialog.dart';
import 'package:ecommerece_app/features/address/domain/address_controller.dart';
import 'package:ecommerece_app/features/address/domain/models/address.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  /// When true, a "나중에 추가하기" skip action appears in the AppBar.
  /// The NavBar passes true; the address-list screen passes false (or omits it).
  final bool showSkip;
  final Address? initialAddress;

  const AddAddressScreen({
    super.key,
    this.showSkip = false,
    this.initialAddress,
  });

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailAddressController =
      TextEditingController();
  bool _isDefaultAddress = true;
  Map<String, dynamic> _address = {};

  final _formKey = GlobalKey<FormState>();

  String? _nameError;
  String? _phoneError;
  String? _addressError;
  String? _detailAddressError;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      final addr = widget.initialAddress!;
      _nameController.text = addr.name;
      _phoneController.text = addr.phone;
      _addressController.text = addr.address;
      _detailAddressController.text = addr.detailAddress;
      _isDefaultAddress = addr.isDefault;
      _address = addr.addressMap ?? {};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  void _searchAddress() async {
    final kakaoService = KakaoApiService(
      apiKey: '772742afea4cfac8c58ed62cfa7d1777',
    );

    final result = await showDialog(
      context: context,
      builder: (context) => AddressSearchDialog(kakaoService: kakaoService),
    );

    if (result != null) {
      setState(() {
        _addressController.text = result['address_name'];
        _address = result;
        _addressError = null;
      });
    }
  }

  bool _validateName() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = '받는 사람 이름을 입력해주세요');
      return false;
    }
    setState(() => _nameError = null);
    return true;
  }

  bool _validatePhone() {
    final phoneRegExp = RegExp(
      r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$',
    );
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _phoneError = '휴대폰 번호를 입력해주세요');
      return false;
    } else if (!phoneRegExp.hasMatch(_phoneController.text.trim())) {
      setState(() => _phoneError = '올바른 휴대폰 번호 형식이 아닙니다');
      return false;
    }
    setState(() => _phoneError = null);
    return true;
  }

  bool _validateAddress() {
    if (_addressController.text.trim().isEmpty) {
      setState(() => _addressError = '배송 주소를 입력해주세요');
      return false;
    }
    setState(() => _addressError = null);
    return true;
  }

  bool _validateDetailAddress() {
    if (_detailAddressController.text.trim().isEmpty) {
      setState(() => _detailAddressError = '상세 주소를 입력해주세요');
      return false;
    }
    setState(() => _detailAddressError = null);
    return true;
  }

  bool _validateAll() {
    return _validateName() &
        _validatePhone() &
        _validateAddress() &
        _validateDetailAddress();
  }

  Future<void> _saveAddress() async {
    if (!_validateAll()) return;

    setState(() => _isLoading = true);

    try {
      final userUid = ref.read(currentUserIdProvider);
      if (userUid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
          setState(() => _isLoading = false);
        }
        return;
      }

      if (widget.initialAddress != null) {
        await ref.read(addressControllerProvider.notifier).updateAddress(
          addressId: widget.initialAddress!.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          detailAddress: _detailAddressController.text.trim(),
          isDefaultAddress: _isDefaultAddress,
          addressMap: _address,
        );
      } else {
        await ref.read(addressControllerProvider.notifier).addAddress(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          detailAddress: _detailAddressController.text.trim(),
          isDefaultAddress: _isDefaultAddress,
          addressMap: _address,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialAddress != null
                  ? '배송지 정보가 수정되었습니다'
                  : '배송지가 저장되었습니다',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          widget.initialAddress != null ? '배송지 수정' : '배송지 추가',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
        // ── Skip action — only shown when launched from NavBar gate ──────
        actions:
            widget.showSkip
                ? [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      '나중에',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ]
                : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Center(
                  child: Text(
                    widget.initialAddress != null ? '배송지 수정' : '배송지 추가',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                const Divider(),

                // ── Recipient name ──────────────────────────────────────
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: '받는 사람',
                    hintStyle: const TextStyle(color: Color(0xFF86828B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    errorText: _nameError,
                  ),
                  onChanged: (_) => _validateName(),
                ),
                SizedBox(height: 12.h),

                // ── Phone ───────────────────────────────────────────────
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '휴대폰 번호',
                    hintStyle: const TextStyle(color: Color(0xFF86828B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    errorText: _phoneError,
                  ),
                  onChanged: (_) => _validatePhone(),
                ),
                SizedBox(height: 12.h),

                // ── Address search ──────────────────────────────────────
                TextField(
                  controller: _addressController,
                  readOnly: true,
                  onTap: _searchAddress,
                  decoration: InputDecoration(
                    hintText: '배송 주소',
                    hintStyle: const TextStyle(color: Color(0xFF86828B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: ImageIcon(
                      const AssetImage('assets/Frame 4.png'),
                      color: Colors.black,
                      size: 25.sp,
                    ),
                    errorText: _addressError,
                  ),
                ),
                SizedBox(height: 12.h),

                // ── Detail address ──────────────────────────────────────
                TextField(
                  controller: _detailAddressController,
                  decoration: InputDecoration(
                    hintText: '상세 주소',
                    hintStyle: const TextStyle(color: Color(0xFF86828B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    errorText: _detailAddressError,
                  ),
                  onChanged: (_) => _validateDetailAddress(),
                ),
                SizedBox(height: 16.h),

                // ── Default address checkbox ────────────────────────────
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isDefaultAddress,
                        onChanged: (value) {
                          setState(() => _isDefaultAddress = value ?? false);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(color: Colors.grey[400]!),
                        activeColor: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '기본 배송지로 설정',
                      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                // ── Save button ─────────────────────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : Text(
                            '저장',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
