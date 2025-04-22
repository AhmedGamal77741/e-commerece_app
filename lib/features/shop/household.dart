import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/shop/fav_fnc.dart';
import 'package:ecommerece_app/features/shop/item_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Household extends StatefulWidget {
  const Household({super.key});

  @override
  State<Household> createState() => _HouseholdState();
}

class _HouseholdState extends State<Household> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed(Routes.shopSearchScreen);
        },
        elevation: 0,
        backgroundColor: Colors.black,
        shape: CircleBorder(),
        child: Icon(
          Icons.search,
          color: Colors.white,
        ), // Explicit circular shape
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('products')
                  .where('category', isEqualTo: 'household')
                  .snapshots(),
          builder: (context, snapshot) {
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

            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final data = products[index].data() as Map<String, dynamic>;
                print(data);

                return InkWell(
                  onTap: () async {
                    bool liked = isFavoritedByUser(
                      productData: data,
                      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ItemDetails(
                              data: {
                                'imgUrl': data['imgUrl'],
                                'sellerName': data['sellerName'],
                                'price': data['price'],
                                'product_id': data['product_id'],
                                'freeShipping': data['freeShipping'],
                                'meridiem': data['meridiem'],
                                'baselinehour': data['baselineTime'],
                                'productName': data['productName'],
                                'instructions': data['instructions'],
                                'stock': data['stock'],
                                'likes': liked,
                              },
                            ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          data['imgUrl'],
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
                                data['sellerName'],
                                style: TextStyles.abeezee14px400wP600,
                              ),
                              verticalSpace(5),
                              Text(
                                data['productName'],
                                style: TextStyles.abeezee13px400wPblack,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              verticalSpace(3),
                              Text(
                                '${data['price'] ?? '0'} KRW',
                                style: TextStyles.abeezee13px400wPblack,
                              ),
                              verticalSpace(2),
                              Text(
                                data['freeShipping'] == true
                                    ? '무료 배송'
                                    : '배송료가 부과됩니다',
                                style: TextStyles.abeezee11px400wP600,
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
