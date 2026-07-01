import codecs
import re

with codecs.open('lib/features/shop/shop.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace onPressed block
text = re.sub(
    r'onPressed: \(\) async \{.*?\s*await context\.pushNamed\(Routes\.addressListScreen\);\s*\},',
    '''onPressed: ref.read(authStateProvider).value == null ? null : () async {
                              await context.pushNamed(Routes.addressListScreen);
                            },''',
    text,
    flags=re.DOTALL
)

# Replace the icon block
text = re.sub(
    r'SizedBox\(width: 6\.w\),\s*const Icon\(\s*Icons\.arrow_drop_down,\s*color: Colors\.black,\s*size: 18,\s*\),',
    '''if (ref.watch(authStateProvider).value != null) ...[
                                  SizedBox(width: 6.w),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                                ]''',
    text,
    flags=re.DOTALL
)

with codecs.open('lib/features/shop/shop.dart', 'w', encoding='utf-8') as f:
    f.write(text)
