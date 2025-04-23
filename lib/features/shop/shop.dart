import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';

import 'package:ecommerece_app/features/shop/fav_fnc.dart';

import 'package:ecommerece_app/features/shop/item_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class Shop extends StatefulWidget {
  const Shop({super.key});

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      List<Map<String, dynamic>> categories =
          snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'name': (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown',
            };
          }).toList();

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If no categories, show a message
    if (_categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Shop'),
          backgroundColor: ColorsManager.white,
        ),
        body: Center(child: Text('No categories available')),
      );
    }

    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 130.h,
          backgroundColor: ColorsManager.white,
          title: TabBar(
            labelStyle: TextStyle(
              fontSize: 16.sp,
              decoration: TextDecoration.none,
              fontFamily: 'ABeeZee',
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              color: ColorsManager.primaryblack,
            ),
            unselectedLabelColor: ColorsManager.primary600,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: ColorsManager.primaryblack,
            isScrollable:
                _categories.length > 4, // Make scrollable if many categories
            tabs:
                _categories
                    .map((category) => Tab(text: category['name']))
                    .toList(),
          ),
        ),
        body: TabBarView(
          children:
              _categories
                  .map(
                    (category) => CategoryProductsScreen(
                      categoryId: category['id'],
                      categoryName: category['name'],
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

// Create a CategoryProductsScreen widget to display products for each category
class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _CategoryProductsScreenState createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Display products in a grid
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed(Routes.shopSearchScreen);
        },
        elevation: 0,
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.search, color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('products')
                  .where('category', isEqualTo: widget.categoryId)
                  .snapshots(),

          builder: (context, snapshot) {
            print(snapshot);

            if (snapshot.hasError) {
              return Center(child: Text('오류: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('아직 제품이 없습니다'));
            }

            final products = snapshot.data!.docs;
            return ListView.separated(
              separatorBuilder: (context, index) {
                if (index == products.length - 1) {
                  return SizedBox.shrink();
                }
                return Divider();
              },
              itemCount: products.length,
              itemBuilder: (context, index) {
                final data2 = products[index].data() as Map<String, dynamic>;
                Product p = Product.fromMap(data2);

                return InkWell(
                  onTap: () async {
                    bool liked = isFavoritedByUser(
                      p: p,
                      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    );
                    String arrivalTime = await getArrivalDay(
                      p.meridiem,
                      p.baselineTime,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ItemDetails(
                              product: p,
                              arrivalDay: arrivalTime,
                            ),
                      ),
                    );

                    // context.pushNamed(
                    //   Routes.itemDetailsScreen,
                    //   arguments: {
                    // 'imgUrl': data['imgUrl'],
                    // 'sellerName': data['sellerName	'],
                    // 'price': data['price	'],
                    // 'product_id': data['product_id'],
                    // 'freeShipping': data['freeShipping	'],
                    // 'meridiem': data['meridiem'],
                    // 'baselinehour': data['baselinehour	'],
                    // 'productName': data['productName	'],
                    //   },
                    // );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          p.imgUrl!,
                          width: 105.w,
                          height: 105.h,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.sellerName,
                                style: TextStyles.abeezee14px400wP600,
                              ),
                              verticalSpace(5),
                              Text(
                                p.productName,
                                style: TextStyles.abeezee13px400wPblack,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              verticalSpace(3),
                              Text(
                                '${p.price ?? '0'} 원',
                                style: TextStyles.abeezee13px400wPblack,
                              ),
                              verticalSpace(2),
                              FutureBuilder<String>(
                                future: getArrivalDay(
                                  p.meridiem,
                                  p.baselineTime,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text(
                                      '로딩 중...',
                                      style: TextStyles.abeezee11px400wP600,
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Text(
                                      '오류 발생',
                                      style: TextStyles.abeezee11px400wP600,
                                    );
                                  }
                                  return Text(
                                    '${snapshot.data} . ${p.freeShipping == true ? '무료 배송' : '배송료가 부과됩니다'} ',
                                    style: TextStyles.abeezee11px400wP600,
                                  );
                                },
                              ),

                              verticalSpace(4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Create a ProductCard widget
