import codecs

with codecs.open('lib/features/shop/widgets/category_products_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix logic drop for stock > 0
text = text.replace(
'''                if (hasUserAddress && _isSameRegion(userAddressMap, product.address)) {
                  sameRegion.add(product);
                } else if (!hasUserAddress) {
                  otherRegion.add(product);
                }''',
'''                if (hasUserAddress && _isSameRegion(userAddressMap, product.address)) {
                  sameRegion.add(product);
                } else {
                  otherRegion.add(product);
                }'''
)

# Fix logic drop for stock == 0
text = text.replace(
'''                if (product.address != null && product.address!.isNotEmpty) {
                  if (_isSameRegion(userAddressMap, product.address)) {
                    soldOutList.add(product);
                  }
                } else {''',
'''                if (product.address != null && product.address!.isNotEmpty) {
                  if (_isSameRegion(userAddressMap, product.address)) {
                    soldOutList.add(product);
                  } else {
                    soldOutList.add(product);
                  }
                } else {'''
)

with codecs.open('lib/features/shop/widgets/category_products_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
