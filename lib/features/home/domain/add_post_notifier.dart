import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:flutter/foundation.dart';

class UploadableImage extends ChangeNotifier {
  final String id = UniqueKey().toString();
  final XFile localFile;
  String? _networkUrl;
  bool _isUploading;
  bool _hasError;
  double? _progress;

  UploadableImage({
    required this.localFile,
    String? networkUrl,
    bool isUploading = true,
    bool hasError = false,
    double? progress,
  }) : _networkUrl = networkUrl,
       _isUploading = isUploading,
       _hasError = hasError,
       _progress = progress;

  String? get networkUrl => _networkUrl;
  set networkUrl(String? value) {
    _networkUrl = value;
    notifyListeners();
  }

  bool get isUploading => _isUploading;
  set isUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }

  bool get hasError => _hasError;
  set hasError(bool value) {
    _hasError = value;
    notifyListeners();
  }

  double? get progress => _progress;
  set progress(double? value) {
    _progress = value;
    notifyListeners();
  }
}

class AddPostState {
  final List<UploadableImage> images;
  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId;
  final bool isArrangeMode;
  final bool isDeleteMode;
  final bool isEditMode;
  final bool isLoading;
  final String innerPlaceholderText;

  AddPostState({
    this.images = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.isArrangeMode = false,
    this.isDeleteMode = false,
    this.isEditMode = false,
    this.isLoading = false,
    this.innerPlaceholderText = '',
  });

  AddPostState copyWith({
    List<UploadableImage>? images,
    List<Map<String, dynamic>>? categories,
    String? selectedCategoryId,
    bool? isArrangeMode,
    bool? isDeleteMode,
    bool? isEditMode,
    bool? isLoading,
    String? innerPlaceholderText,
  }) {
    return AddPostState(
      images: images ?? this.images,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isArrangeMode: isArrangeMode ?? this.isArrangeMode,
      isDeleteMode: isDeleteMode ?? this.isDeleteMode,
      isEditMode: isEditMode ?? this.isEditMode,
      isLoading: isLoading ?? this.isLoading,
      innerPlaceholderText: innerPlaceholderText ?? this.innerPlaceholderText,
    );
  }
}

class AddPostNotifier extends AutoDisposeNotifier<AddPostState> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  AddPostState build() {
    _loadCategories();
    _loadPlaceholderText();
    return AddPostState();
  }

  Future<void> _loadPlaceholderText() async {
    try {
      final snapshot = await _firestore.collection('widgets').doc('placeholders').get();
      if (snapshot.exists) {
         state = state.copyWith(innerPlaceholderText: snapshot.data()?['innerPlaceholderText'] ?? '');
      }
    } catch (e) {
      debugPrint('Error loading placeholder text: $e');
    }
  }

  Future<void> _loadCategories() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .orderBy('order', descending: false)
          .get();
      
      final categories = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'],
        'order': doc['order'],
      }).toList();
      
      state = state.copyWith(categories: categories);
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> addCategory(String categoryName) async {
    final user = _auth.currentUser;
    if (user == null || categoryName.isEmpty) return;
    try {
      final newOrder = state.categories.isEmpty ? 0 : (state.categories.last['order'] as int) + 1;
      final categoryRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc();
          
      await categoryRef.set({
        'name': categoryName,
        'order': newOrder,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _loadCategories();
    } catch (e) {
      debugPrint('Error adding category: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(categoryId)
          .delete();
          
      if (state.selectedCategoryId == categoryId) {
        state = state.copyWith(selectedCategoryId: null);
      }
      await _loadCategories();
    } catch (e) {
      debugPrint('Error deleting category: $e');
    }
  }

  Future<void> updateCategoryName(String categoryId, String newName) async {
    final user = _auth.currentUser;
    if (user == null || newName.trim().isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(categoryId)
          .update({'name': newName.trim()});
      await _loadCategories();
    } catch (e) {
      debugPrint('Error updating category name: $e');
    }
  }

  Future<void> updateCategoryOrder(List<Map<String, dynamic>> newOrder) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final batch = _firestore.batch();
      for (int i = 0; i < newOrder.length; i++) {
        final categoryRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('categories')
            .doc(newOrder[i]['id']);
        batch.update(categoryRef, {'order': i});
      }
      await batch.commit();
      await _loadCategories();
    } catch (e) {
      debugPrint('Error updating category order: $e');
    }
  }

  void toggleEditMode() {
    state = state.copyWith(
      isEditMode: !state.isEditMode,
      isArrangeMode: false,
      isDeleteMode: false,
    );
  }

  void toggleArrangeMode() {
    state = state.copyWith(
      isArrangeMode: !state.isArrangeMode,
      isEditMode: false,
      isDeleteMode: false,
    );
  }

  void toggleDeleteMode() {
    state = state.copyWith(
      isDeleteMode: !state.isDeleteMode,
      isEditMode: false,
      isArrangeMode: false,
    );
  }

  void exitModes() {
    state = state.copyWith(
      isArrangeMode: false,
      isDeleteMode: false,
      isEditMode: false,
    );
  }

  void selectCategory(String categoryId) {
    if (state.selectedCategoryId == categoryId) {
      state = state.copyWith(selectedCategoryId: null);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  void addImages(List<XFile> pickedFiles) {
    final newImages = pickedFiles.map((file) => UploadableImage(localFile: file)).toList();
    final allImages = List<UploadableImage>.from(state.images)..addAll(newImages);
    state = state.copyWith(images: allImages);
    
    final startIndex = state.images.length - newImages.length;
    for (int i = 0; i < pickedFiles.length; i++) {
      _uploadImage(pickedFiles[i], startIndex + i);
    }
  }
  
  void removeImage(UploadableImage image) {
    final allImages = List<UploadableImage>.from(state.images)..remove(image);
    state = state.copyWith(images: allImages);
  }
  
  void reorderImages(int oldIndex, int newIndex) {
     final newImages = List<UploadableImage>.from(state.images);
     if (newIndex > oldIndex) newIndex -= 1;
     final item = newImages.removeAt(oldIndex);
     newImages.insert(newIndex, item);
     state = state.copyWith(images: newImages);
  }

  Future<void> _uploadImage(XFile file, int index) async {
     try {
         final imageItem = state.images[index];
         final url = await ref.read(feedControllerProvider).uploadSingleImageToFirebase(
              file,
              index,
              onProgress: (progress) {
                 imageItem.progress = progress;
              },
         );
         imageItem.networkUrl = url;
         imageItem.isUploading = false;
         state = state.copyWith(images: List.from(state.images)); 
     } catch(e) {
         final imageItem = state.images[index];
         imageItem.isUploading = false;
         imageItem.hasError = true;
         state = state.copyWith(images: List.from(state.images)); 
     }
  }

  Future<void> submitPost(String text) async {
    if (text.isEmpty && state.images.isEmpty) return;
    if (state.images.any((img) => img.isUploading)) {
      throw Exception('사진이 아직 업로드 중입니다.');
    }
    
    state = state.copyWith(isLoading: true);
    try {
      final finalUrls = state.images
          .map((e) => e.networkUrl)
          .where((url) => url != null)
          .cast<String>()
          .toList();
          
      await ref.read(feedControllerProvider).uploadPost(
        text: text,
        imgUrls: finalUrls,
        categoryId: state.selectedCategoryId,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final addPostNotifierProvider = AutoDisposeNotifierProvider<AddPostNotifier, AddPostState>(() {
  return AddPostNotifier();
});
