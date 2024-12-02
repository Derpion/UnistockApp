import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UNISTOCK/pages/CheckoutPage.dart';
import 'package:UNISTOCK/ProfileInfo.dart';

class DetailSelectionPro extends StatefulWidget {
  final String itemId;
  final String label;
  final String courseLabel;
  final String? itemSize;
  final String imagePath;
  final int price;
  final int quantity;
  final ProfileInfo currentProfileInfo;

  DetailSelectionPro({
    required this.itemId,
    required this.label,
    required this.courseLabel,
    required this.itemSize,
    required this.imagePath,
    required this.price,
    required this.quantity,
    required this.currentProfileInfo,
  });

  @override
  _DetailSelectionProState createState() => _DetailSelectionProState();
}

class _DetailSelectionProState extends State<DetailSelectionPro> {
  int _currentQuantity = 1;
  String _selectedSize = '';
  List<String> availableSizes = [];
  Map<String, int?> sizePrices = {};
  Map<String, int> sizeQuantities = {};
  List<String> preOrderSizes = [];
  int _displayPrice = 0;
  int _availableQuantity = 0;

  @override
  void initState() {
    super.initState();
    _currentQuantity = widget.quantity;
    _selectedSize = widget.itemSize ?? '';
    _displayPrice = widget.price;

    _fetchItemDetailsFromFirestore();
  }

  Future<void> _fetchItemDetailsFromFirestore() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Inventory_stock')
          .doc('Proware & PE') // Root collection
          .collection(widget.courseLabel) // Dynamic collection (NSTP, PE, etc.)
          .doc(widget.itemId) // Fetch the specific item by ID
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          // Extract sizes, prices, and quantities
          if (data.containsKey('sizes') &&
              data['sizes'] is Map<String, dynamic>) {
            var sizesData = data['sizes'] as Map<String, dynamic>;

            sizePrices = sizesData.map((size, details) {
              if (details is Map<String, dynamic> &&
                  details.containsKey('price')) {
                return MapEntry(size, details['price'] as int?);
              } else {
                return MapEntry(size, null);
              }
            });

            sizeQuantities = sizesData.map((size, details) {
              if (details is Map<String, dynamic> &&
                  details.containsKey('quantity')) {
                return MapEntry(size, details['quantity'] ?? 0);
              } else {
                return MapEntry(size, 0);
              }
            });

            availableSizes = sizeQuantities.keys
                .where((size) => sizeQuantities[size]! > 0)
                .toList();

            // Show pre-orderable sizes (those with 0 quantity)
            preOrderSizes = sizeQuantities.keys
                .where((size) => sizeQuantities[size]! == 0)
                .toList();

            setState(() {
              _selectedSize =
                  availableSizes.isNotEmpty ? availableSizes.first : '';
              _availableQuantity = availableSizes.isNotEmpty
                  ? sizeQuantities[_selectedSize] ?? 0
                  : 0;
              _displayPrice = sizePrices[_selectedSize] ?? widget.price;
            });
          }
        }
      } else {
        throw Exception("Item not found in the selected category.");
      }
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }

  bool get disableButtons {
    if (availableSizes.isEmpty) {
      return true;
    }

    if (_selectedSize.isEmpty) {
      return true;
    }

    if (_availableQuantity == 0) {
      return true;
    }

    return false;
  }

  void showSizeNotSelectedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Size Not Selected'),
          content: const Text('Please select a size before proceeding.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void handleCheckout() {
    if (availableSizes.isNotEmpty && _selectedSize.isEmpty) {
      showSizeNotSelectedDialog();
    } else {
      final int totalPrice = _displayPrice * _currentQuantity;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutPage(
            label: widget.label,
            itemSize: availableSizes.isNotEmpty ? _selectedSize : null,
            imagePath: widget.imagePath,
            unitPrice: _displayPrice,
            price: totalPrice,
            quantity: _currentQuantity,
            category: 'Proware & PE',
            courseLabel: widget.courseLabel,
            currentProfileInfo: widget.currentProfileInfo,
          ),
        ),
      );
    }
  }

  void handleAddToCart() async {
    if (availableSizes.isNotEmpty && _selectedSize.isEmpty) {
      showSizeNotSelectedDialog();
    } else {
      String userId = widget.currentProfileInfo.userId;

      final int totalPrice = _displayPrice * _currentQuantity;

      CollectionReference cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart');

      await cartRef.add({
        'label': widget.label,
        'itemSize': availableSizes.isNotEmpty ? _selectedSize : null,
        'imagePath': widget.imagePath,
        'price': totalPrice,
        'quantity': _currentQuantity,
        'category': 'Proware & PE',
        'courseLabel': widget.courseLabel,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added to cart!')),
      );
    }
  }

  void handlePreOrder() async {
    String userId = widget.currentProfileInfo.userId;

    final int totalPrice = _displayPrice * _currentQuantity;

    CollectionReference preOrderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('preorders');

    await preOrderRef.add({
      'label': widget.label,
      'itemSize': availableSizes.isNotEmpty ? _selectedSize : null,
      'imagePath': widget.imagePath,
      'price': totalPrice,
      'quantity': _currentQuantity,
      'category': 'Proware & PE',
      'courseLabel': widget.courseLabel,
      'status': 'pre-ordered',
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to pre-order!')),
    );
  }

  void viewImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Image.network(widget.imagePath),
        );
      },
    );
  }

  Widget build(BuildContext context) {
    final int? sizePrice = sizePrices[_selectedSize];
    final int displayPrice = sizePrice ?? widget.price;

    // Check if the selected size is a pre-order size
    bool isPreOrderSelected = preOrderSizes.contains(_selectedSize);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: viewImage,
                      child: Image.network(
                        widget.imagePath,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.label,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (availableSizes.isNotEmpty ||
                        preOrderSizes.isNotEmpty) ...[
                      SizedBox(height: 10),
                      _buildSizeSelector(),
                    ],
                    SizedBox(height: 10),
                    Text(
                      'Price: ₱$displayPrice',
                      style: TextStyle(fontSize: 20),
                    ),
                    _buildQuantitySelector(),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildButtonsRow(isPreOrderSelected), // Pass the pre-order flag
                // Show out of stock or pre-order message only when no size is selected
                if (_selectedSize.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'This item is either out of stock or requires a size selection.',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsRow(bool isPreOrderSelected) {
    // Determine whether buttons should be enabled based on pre-order selection
    bool disableButtons = isPreOrderSelected;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: disableButtons ? null : handleCheckout,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                backgroundColor:
                    disableButtons ? Colors.grey : Color(0xFFFFEB3B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 31, 31, 31),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: disableButtons ? null : handleAddToCart,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                side: BorderSide(
                    color: disableButtons ? Colors.grey : Colors.blue,
                    width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Add to Cart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: disableButtons
                      ? Color.fromARGB(255, 31, 31, 31)
                      : Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: isPreOrderSelected
                  ? handlePreOrder
                  : null, // Only enable if pre-order is selected
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                backgroundColor: isPreOrderSelected
                    ? Color(0xFF4CAF50) // Green if pre-order available
                    : Colors.grey, // Gray if size has stock
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Pre-order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    return AbsorbPointer(
      absorbing: availableSizes.isEmpty &&
          preOrderSizes.isEmpty, // Disable interactions when no sizes
      child: DropdownButton<String>(
        value: _selectedSize.isEmpty ? null : _selectedSize,
        hint: const Text('Select Size'),
        items: [...availableSizes, ...preOrderSizes].map((size) {
          int availableQuantity = sizeQuantities[size] ?? 0;
          return DropdownMenuItem(
              value: size,
              child: Text(
                '$size (${availableQuantity == 0 ? "Pre-order" : availableQuantity} available)',
                style: TextStyle(
                  color: availableQuantity > 0 ? Colors.black : Colors.green,
                ),
              ));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedSize = value ?? '';
            _currentQuantity = 1; // Reset quantity to 1 for new size selection
          });
        },
        disabledHint: const Text(
          'No Sizes Available',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text('Quantity:'),
        IconButton(
          onPressed: _currentQuantity > 1
              ? () {
                  setState(() {
                    _currentQuantity--;
                  });
                }
              : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$_currentQuantity'),
        IconButton(
          onPressed: _currentQuantity < _availableQuantity
              ? () {
                  setState(() {
                    _currentQuantity++;
                  });
                }
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
