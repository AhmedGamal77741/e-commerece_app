import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/shop/cart_func.dart';
import 'package:ecommerece_app/features/shop/fav_fnc.dart';
import 'package:ecommerece_app/features/shop/item_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ShopSearch extends StatefulWidget {
  const ShopSearch({super.key});

  @override
  State<ShopSearch> createState() => _ShopSearchState();
}

class _ShopSearchState extends State<ShopSearch> {
  TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Fetch all products from Firestore
  void _fetchProducts() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _allProducts =
          querySnapshot.docs.map((doc) {
            return Product.fromMap(doc.data());
          }).toList();

      _filteredProducts =
          _allProducts; // Initialize filtered list with all products
    });
  }

  // Search functionality
  void _searchProduct(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts =
            _allProducts; // Show all products if search is cleared
      });
    } else {
      final filtered =
          _allProducts
              .where(
                (product) => product.productName
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
      setState(() {
        _filteredProducts = filtered; // Update filtered products list
      });
    }
  }

  final formatCurrency = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40.w,
        titleSpacing: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ColorsManager.primary600),
          onPressed: () {
            Navigator.pop(context); // Going back
          },
        ),
        title: TextField(
          controller: _searchController,
          onChanged: _searchProduct,
          decoration: InputDecoration(
            hintText: '검색...',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 5.h,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.zero,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: ImageIcon(AssetImage('assets/Frame 4.png')),
            iconSize: 30.sp,
            onPressed: () {},
          ),
        ],
      ),
      body:
          _filteredProducts.isEmpty
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator
              : _filteredProducts.isEmpty && _searchController.text.isNotEmpty
              ? Center(child: Text('결과가 없습니다')) // Show no results message
              : ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ListTile(
                    title: Text(product.productName),
                    subtitle: Text('${formatCurrency.format(product.price)} 원'),
                    leading: Image.network(
                      product.imgUrl!,
                      width: 50.w,
                      height: 50.h,
                      fit: BoxFit.cover,
                    ),
                    onTap: () async {
                      bool isSub = await isUserSubscribed();
                      bool liked = isFavoritedByUser(
                        p: product,
                        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                      );

                      String arrivalTime = await getArrivalDay(
                        product.meridiem,
                        product.baselineTime,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ItemDetails(
                                product: product,
                                arrivalDay: arrivalTime,
                                isSub: isSub,
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
