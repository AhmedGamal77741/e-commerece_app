import codecs

with codecs.open('lib/features/shop/shop.dart', 'r', encoding='utf-8') as f:
    text = f.read()

print('onPressed: () async {' in text)
