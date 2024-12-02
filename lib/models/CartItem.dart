import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String label;
  final String imagePath;
  final List<String> availableSizes;
  String? selectedSize;
  int price;
  int quantity;
  bool selected;
  final String category;
  String courseLabel;
  List<DocumentReference> documentReferences;

  CartItem({
    required this.id,
    required this.label,
    required this.imagePath,
    required this.availableSizes,
    this.selectedSize,
    required this.price,
    this.quantity = 1,
    this.selected = false,
    required this.category,
    this.courseLabel = 'Unknown',
    this.documentReferences = const [],
  });

  /// Factory constructor for creating CartItem from Firestore
  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String inferredCourseLabel = data['courseLabel'] ?? 'Unknown';
    if (inferredCourseLabel == 'Unknown' && data['category'] == 'Proware & PE') {
      inferredCourseLabel = data['subcategory'] ?? 'Unknown'; // Infer from subcategory
    }

    return CartItem(
      id: doc.id,
      label: data['label'] ?? 'Unknown',
      imagePath: data['imagePath'] ?? 'assets/images/placeholder.png',
      availableSizes: List<String>.from(data['availableSizes'] ?? []),
      selectedSize: data['itemSize'] as String?,
      price: data['price'] ?? 0,
      quantity: data['quantity'] ?? 1,
      selected: data['selected'] ?? false,
      category: data['category'] ?? 'Unknown',
      courseLabel: inferredCourseLabel, // Dynamically assign
      documentReferences: [doc.reference],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'imagePath': imagePath,
      'availableSizes': availableSizes,
      'itemSize': selectedSize,
      'price': price,
      'quantity': quantity,
      'selected': selected,
      'category': category,
      'courseLabel': courseLabel,
    };
  }

  void addDocumentReference(DocumentReference ref) {
    documentReferences.add(ref);
  }

  void updateCourseLabel(String newCourseLabel) {
    if (courseLabel == 'Unknown' || courseLabel.isEmpty) {
      courseLabel = newCourseLabel;
    }
  }

  CartItem copyWith({
    String? id,
    String? label,
    String? imagePath,
    List<String>? availableSizes,
    String? selectedSize,
    int? price,
    int? quantity,
    bool? selected,
    String? category,
    String? courseLabel,
    List<DocumentReference>? documentReferences,
  }) {
    return CartItem(
      id: id ?? this.id,
      label: label ?? this.label,
      imagePath: imagePath ?? this.imagePath,
      availableSizes: availableSizes ?? this.availableSizes,
      selectedSize: selectedSize ?? this.selectedSize,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      selected: selected ?? this.selected,
      category: category ?? this.category,
      courseLabel: courseLabel ?? this.courseLabel,
      documentReferences: documentReferences ?? this.documentReferences,
    );
  }
}
