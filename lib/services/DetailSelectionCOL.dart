import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UNISTOCK/pages/CheckoutPage.dart';
import 'package:UNISTOCK/ProfileInfo.dart';

class DetailSelectionCOL extends StatefulWidget {
  final String itemId;
  final String label;
  final String courseLabel;
  final String? itemSize;
  final String imagePath;
  final int price;
  final int quantity;
  final ProfileInfo currentProfileInfo;

  DetailSelectionCOL({
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
  _DetailSelectionCOLState createState() => _DetailSelectionCOLState();
}

class _DetailSelectionCOLState extends State<DetailSelectionCOL> {
  int _currentQuantity = 1;
  String _selectedSize = '';
  List<String> availableSizes = [];
  Map<String, int?> sizePrices = {};
  Map<String, int> sizeQuantities = {};
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
      String courseLabel = widget.courseLabel;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Inventory_stock')
          .doc('college_items')
          .collection(courseLabel)
          .doc(widget.itemId)
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data == null) {
          setState(() {
            availableSizes = [];
            _selectedSize = '';
            _availableQuantity = 0;
          });
          return;
        }

        if (data.containsKey('sizes') &&
            data['sizes'] is Map<String, dynamic>) {
          var sizesData = data['sizes'] as Map<String, dynamic>;

          sizePrices = sizesData.map((size, details) {
            if (details is Map<String, dynamic> &&
                details.containsKey('price')) {
              return MapEntry(size,
                  details['price'] != null ? details['price'] as int? : null);
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

          // Define size order
          List<String> sizeOrder = [
            'XS',
            'Small',
            'Medium',
            'Large',
            'XL',
            '2XL',
            '3XL',
            '4XL',
            '5XL',
            '6XL',
            '7XL'
          ];

          // Filter sizes to only include those with quantity > 0
          availableSizes = sizeQuantities.keys.toList();

          availableSizes.sort((a, b) {
            int indexA = sizeOrder.indexOf(a);
            int indexB = sizeOrder.indexOf(b);
            return indexA.compareTo(indexB);
          });

          setState(() {
            _selectedSize = '';
            _availableQuantity =
                0; // Default to 0 until the user selects a size
            _displayPrice = widget.price; // Default price
          });
        } else {
          setState(() {
            availableSizes = [];
            _selectedSize = '';
            _availableQuantity = 1;
            _displayPrice = data['price'] ?? widget.price;
          });
        }
      } else {
        setState(() {
          availableSizes = [];
          _selectedSize = '';
          _availableQuantity = 0;
        });
      }
    } catch (e) {
      setState(() {
        availableSizes = [];
        _selectedSize = '';
        _availableQuantity = 0;
      });
    }
  }

  bool get disableButtons {
    if (availableSizes.isEmpty) {
      return true;
    }

    if (_selectedSize.isEmpty) {
      return true;
    }

    if (sizeQuantities[_selectedSize] == null ||
        sizeQuantities[_selectedSize]! < _currentQuantity) {
      return true;
    }

    return false;
  }

  bool get disablePreOrder {
    if (_selectedSize.isEmpty || sizeQuantities[_selectedSize] == null) {
      return true; // Disable if no size is selected or size data is unavailable.
    }

    if (sizeQuantities[_selectedSize]! > 0) {
      return true; // Disable if stock is available for the selected size.
    }

    return false; // Enable pre-order only when stock is zero.
  }

  bool get shouldShowMessage {
    if (_selectedSize.isEmpty) {
      return true; // Show message if no size is selected.
    }

    if (sizeQuantities[_selectedSize] == null ||
        sizeQuantities[_selectedSize]! <= 0) {
      return false; // Don't show the message for valid pre-order items (out of stock but size selected).
    }

    return false; // Hide message if stock is available for the selected size.
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
            category: 'college_items',
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
        'category': 'college_items',
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
      'category': 'college_items',
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

  @override
  Widget build(BuildContext context) {
    final int? sizePrice = sizePrices[_selectedSize];
    final int displayPrice = sizePrice ?? widget.price;

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
                    if (availableSizes.isNotEmpty) ...[
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
                _buildButtonsRow(),
                //show out of stock message only when no stocks available for the selected size
                if (shouldShowMessage)
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

  Widget _buildButtonsRow() {
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
              onPressed: disablePreOrder ? null : handlePreOrder,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                backgroundColor:
                    disablePreOrder ? Colors.grey : Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
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
      absorbing: availableSizes.isEmpty, // Disable interactions when empty
      child: DropdownButton<String>(
        value: _selectedSize.isEmpty ? null : _selectedSize,
        hint: Text('Select Size'),
        items: availableSizes.map((size) {
          int availableQuantity = sizeQuantities[size] ?? 0;

          return DropdownMenuItem(
            value: size,
            child: Text(
              availableQuantity > 0
                  ? '$size ($availableQuantity available)'
                  : '$size (Pre-order)', // Mark out-of-stock items as "Pre-order"
              style: TextStyle(
                color: availableQuantity > 0 ? Colors.black : Colors.green,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedSize = value ?? '';
            _currentQuantity = 1; // Reset quantity to 1 for new size selection
          });
        },
        disabledHint: Text(
          'No Sizes Available',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Text('Quantity:'),
        IconButton(
          onPressed: _currentQuantity > 1
              ? () {
                  setState(() {
                    _currentQuantity--;
                  });
                }
              : null,
          icon: Icon(Icons.remove),
        ),
        Text('$_currentQuantity'),
        IconButton(
          onPressed: _currentQuantity < (sizeQuantities[_selectedSize] ?? 0)
              ? () {
                  setState(() {
                    _currentQuantity++;
                  });
                }
              : null,
          icon: Icon(Icons.add),
        ),
      ],
    );
  }
}
