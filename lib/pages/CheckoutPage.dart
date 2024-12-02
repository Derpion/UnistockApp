import 'package:UNISTOCK/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UNISTOCK/pages/home_page.dart';
import 'package:UNISTOCK/pages/uniform_page.dart';
import 'package:UNISTOCK/pages/MerchAccessoriesPage.dart';
import 'package:UNISTOCK/pages/ProfilePage.dart';
import 'package:UNISTOCK/ProfileInfo.dart';

class CheckoutPage extends StatefulWidget {
  final String label;
  final String? itemSize;
  final String imagePath;
  final int unitPrice;
  final int price;
  final int quantity;
  final String category;
  final String? courseLabel;
  final ProfileInfo currentProfileInfo;

  CheckoutPage({
    required this.label,
    required this.itemSize,
    required this.imagePath,
    required this.unitPrice,
    required this.price,
    required this.quantity,
    required this.category,
    this.courseLabel,
    required this.currentProfileInfo,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool isOrderProcessing = false;

  final NotificationService notificationService = NotificationService();

  void showTermsAndConditionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Terms and Conditions'),
              content: Container(
                width: double.maxFinite,
                height: 300,
                child: SingleChildScrollView(
                  child: Text(
                    'PROWARE POLICY\n\n'
                    '1. No Cancellation or Refunds: Once you have checked out your order, it is considered final. Orders cannot be cancelled or refunded under any circumstances.\n\n'
                    '2. Payment Responsibility: After checking out, you are responsible for paying for your ordered items as soon as possible at the school cashier.\n\n'
                    '3. Accuracy of Order Details: You are responsible for providing accurate information during the reservation process (e.g., item, size, quantity). UniStock will not be liable for errors caused by incorrect user inputs.\n\n'
                    '4. Payment Methods: Payments should be made at the school cashier. UniStock does not currently support online or mobile payment methods.\n\n'
                    '5. Data Privacy: Your personal information will be handled in accordance with our Privacy Policy. By using the app, you acknowledge that your information will be collected, stored, and used to process reservations and send you alerts.\n\n'
                    '6. Agreement to Policies: By checking out, you confirm that you have read and understood the payment, reservation, and refund policies.\n\n',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Deny'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: isOrderProcessing
                      ? CircularProgressIndicator()
                      : Text('Accept'),
                  onPressed: isOrderProcessing
                      ? null
                      : () async {
                          setState(() {
                            isOrderProcessing = true;
                          });

                          try {
                            final int totalPrice =
                                widget.unitPrice * widget.quantity;

                            print(
                                "Placing Order - Item: ${widget.label}, Price: ${widget.price}, Quantity: ${widget.quantity}, Total: $totalPrice");
                            DocumentReference orderDocRef =
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.currentProfileInfo.userId)
                                    .collection('orders')
                                    .add({
                              'orderDate': FieldValue.serverTimestamp(),
                              'items': [
                                {
                                  'category': widget.category,
                                  'courseLabel': widget.courseLabel ?? 'N/A',
                                  'imagePath': widget.imagePath,
                                  'itemSize': widget.itemSize ?? 'N/A',
                                  'label': widget.label,
                                  'price': widget.price,
                                  'quantity': widget.quantity,
                                }
                              ],
                              'status':
                                  'pending', // Added status here at the top level
                            });

                            print(
                                "Order placed successfully with ID: ${orderDocRef.id}");

                            // // Add in-app notification in Firestore under 'notifications'
                            // await FirebaseFirestore.instance
                            //     .collection('users')
                            //     .doc(widget.currentProfileInfo.userId)
                            //     .collection('notifications')
                            //     .add({
                            //   'title': 'Order Placed',
                            //   'message': 'Your order for ${widget.label} has been successfully placed!',
                            //   'orderSummary': {
                            //     'label': widget.label,
                            //     'itemSize': widget.itemSize,
                            //     'quantity': widget.quantity,
                            //     'pricePerPiece': widget.unitPrice,
                            //     'totalPrice': totalPrice,
                            //   },
                            //   'timestamp': FieldValue.serverTimestamp(),
                            //   'status': 'unread',
                            // });
                            //
                            // print("In-app notification added to Firestore.");
                            //
                            // // Local notification for the device
                            // try {
                            //   await notificationService.showNotification(
                            //     widget.currentProfileInfo.userId,
                            //     0,
                            //     'Order Placed',
                            //     'Your order for ${widget.label} has been successfully placed!',
                            //     orderDocRef.id,
                            //   );
                            //   print("Device notification sent successfully.");
                            // } catch (notificationError) {
                            //   print("Error sending device notification: $notificationError");
                            // }

                            await _notifyAdmin(
                              widget.currentProfileInfo.name,
                              widget.currentProfileInfo.userId,
                              widget.label,
                              widget.itemSize,
                              widget.quantity,
                              widget.price,
                            );

                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PurchaseSummaryPage(
                                  label: widget.label,
                                  itemSize: widget.itemSize,
                                  imagePath: widget.imagePath,
                                  price: widget.price,
                                  quantity: widget.quantity,
                                  category: widget.category,
                                  currentProfileInfo: widget.currentProfileInfo,
                                ),
                              ),
                            );
                          } catch (e) {
                            print("Error placing order: $e");
                          } finally {
                            setState(() {
                              isOrderProcessing = false;
                            });
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _notifyAdmin(String userName, String userId, String label,
      String? itemSize, int quantity, int pricePerPiece) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference adminNotifications =
        firestore.collection('admin_notifications');

    int totalPrice = pricePerPiece * quantity;

    String detailedMessage = """
A new order has been placed by:
Student Name: $userName
Student ID: $userId

Order Details:
Item: $label
Size: ${itemSize ?? 'N/A'}
Quantity: $quantity
Price per Piece: ₱${pricePerPiece.toStringAsFixed(2)}
Total Order Price: ₱${totalPrice.toStringAsFixed(2)}
""";

    try {
      await adminNotifications.add({
        'title': 'New Order Received',
        'userName': userName,
        'userId': userId,
        'message': detailedMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
      });
      print("Admin has been notified of the new order.");
    } catch (e) {
      print("Failed to notify admin: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalPrice = widget.unitPrice * widget.quantity;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF046be0),
        title: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Arial',
              color: Colors.white,
            ),
            children: <TextSpan>[
              TextSpan(text: 'UNI'),
              TextSpan(text: 'STOCK', style: TextStyle(color: Colors.yellow)),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Item:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.network(
                    widget.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) {
                      return Center(
                        child: Icon(Icons.error, size: 50, color: Colors.red),
                      );
                    },
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Size: ${widget.itemSize}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Price: ₱${widget.unitPrice}',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Quantity: ${widget.quantity}',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Total: ₱$totalPrice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showTermsAndConditionsDialog(context);
              },
              child: Text('Proceed to Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchaseSummaryPage extends StatelessWidget {
  final String label;
  final String? itemSize;
  final String imagePath;
  final int price;
  final int quantity;
  final String category;
  final ProfileInfo currentProfileInfo;

  PurchaseSummaryPage({
    required this.label,
    required this.itemSize,
    required this.imagePath,
    required this.price,
    required this.quantity,
    required this.category,
    required this.currentProfileInfo,
  });

  Future<void> _saveOrderToFirestore() async {
    try {
      final int totalPrice = price * quantity;

      print(
          "Saving Order - Item: $label, Price: $price, Quantity: $quantity, Total: $totalPrice");

      CollectionReference orders = FirebaseFirestore.instance
          .collection('users')
          .doc(currentProfileInfo.userId)
          .collection('orders');

      await orders.add({
        'label': label,
        'itemSize': itemSize,
        'imagePath': imagePath,
        'price': price,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Order added to Firestore");
    } catch (e) {
      print("Failed to add order: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalCost =
        price; // Use the passed `price` directly as it represents the total cost

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF046be0),
        title: Text('Purchase Summary'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank you for your purchase!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: imagePath.isNotEmpty
                          ? NetworkImage(imagePath)
                          : AssetImage('assets/icons/default_icon.png')
                              as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Size: $itemSize',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Price: ₱${price ~/ quantity}', // Unit price
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Quantity: $quantity',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Total: ₱$totalCost', // Use totalCost directly
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _saveOrderToFirestore();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      profileInfo: currentProfileInfo,
                      navigationItems: [
                        {
                          'icon': Icons.inventory,
                          'label': 'Uniform',
                          'onPressed': () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UniformPage(
                                      currentProfileInfo: currentProfileInfo)),
                            );
                          }
                        },
                        {
                          'icon': Icons.shopping_bag,
                          'label': 'Merch/Accessories',
                          'onPressed': () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MerchAccessoriesPage(
                                      currentProfileInfo: currentProfileInfo)),
                            );
                          }
                        },
                        {
                          'icon': Icons.account_circle,
                          'label': 'Profile',
                          'onPressed': () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(
                                    profileInfo: currentProfileInfo),
                              ),
                            );
                          }
                        },
                      ],
                    ),
                  ),
                );
              },
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
