import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';

import 'package:ecommerece_app/features/shop/widgets/item_image_carousel.dart';
import 'package:ecommerece_app/features/shop/widgets/item_details/shining_premium_banner.dart';
import 'package:ecommerece_app/features/shop/widgets/item_details/item_info_section.dart';
import 'package:ecommerece_app/features/shop/widgets/item_details/price_points_card.dart';
import 'package:ecommerece_app/features/shop/widgets/item_details/item_details_info_card.dart';
import 'package:ecommerece_app/features/shop/widgets/item_details/bottom_action_buttons.dart';
import 'package:ecommerece_app/features/shop/widgets/item_details/floating_chat_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ItemDetails extends ConsumerStatefulWidget {
  final Product product;
  final String arrivalDay;
  final bool isSub;
  
  const ItemDetails({
    super.key,
    required this.product,
    required this.arrivalDay,
    String? itemId,
    required this.isSub,
  });

  @override
  ConsumerState<ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends ConsumerState<ItemDetails> {
  String? _selectedOption;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    final defaultIndex = widget.product.pricePoints.indexWhere(
      (pricePoint) => pricePoint.quantity == 1,
    );
    if (defaultIndex != -1) {
      _selectedOption = defaultIndex.toString();
    } else if (widget.product.pricePoints.isNotEmpty) {
      _selectedOption = '0';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,###');
    final currentUser = ref.watch(authStateProvider).value;
    final isLoggedIn = currentUser != null;
    final isSub = isLoggedIn ? (ref.watch(isSubscribedProvider).value ?? widget.isSub) : false;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            children: [
              ItemImageCarousel(product: widget.product),
              if (!isSub)
                Container(
                  width: double.infinity,
                  height: 500.h,
                  color: Colors.black,
                  child: const Center(child: ShiningPremiumBanner()),
                ),
              ItemInfoSection(product: widget.product),
              PricePointsCard(
                product: widget.product,
                selectedOption: _selectedOption,
                onChanged: (value) => setState(() => _selectedOption = value),
                isSub: isSub,
                formatCurrency: formatCurrency,
              ),
              ItemDetailsInfoCard(product: widget.product),
            ],
          ),
          if (isLoggedIn)
            FloatingChatButton(product: widget.product),
        ],
      ),
      bottomNavigationBar: BottomActionButtons(
        product: widget.product,
        selectedOption: _selectedOption,
        isSub: isSub,
      ),
    );
  }
}
