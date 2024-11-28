import 'package:UNISTOCK/pages/ProfilePage.dart';
import 'dart:async';
import 'package:UNISTOCK/pages/PreOrderPage.dart';
import 'package:UNISTOCK/pages/SHSUniformsPage.dart';
import 'package:UNISTOCK/screensize.dart';
import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UNISTOCK/pages/CartPage.dart';
import 'package:UNISTOCK/pages/NotificationPage.dart';
import 'package:UNISTOCK/ProfileInfo.dart';
import 'package:UNISTOCK/pages/SizeAndUniformSelection.dart';
import 'package:UNISTOCK/services/DetailSelectionMerch.dart';

class HomePage extends StatefulWidget {
  final ProfileInfo profileInfo;
  final List<Map<String, dynamic>> navigationItems;

  HomePage({
    required this.profileInfo,
    required this.navigationItems,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _merchItems = [];
  List<String> _imageUrls = [];
  bool _isLoading = true;
  Timer? _autoScrollTimer;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchAnnouncementImages();
    _startAutoScroll();
    _fetchMerchData();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_imageUrls.isNotEmpty) {
        _currentIndex = (_currentIndex + 1) % _imageUrls.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnnouncementImages() async {
    try {
      String adminDocumentId = 'ZmjXRodEmi3LOaYA10tH';
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('admin')
          .doc(adminDocumentId)
          .collection('announcements')
          .orderBy('announcement_label', descending: false)
          .get();

      List<String> urls = snapshot.docs.map((doc) {
        return doc['image_url'] as String;
      }).toList();

      setState(() {
        _imageUrls = urls;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching announcements: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fetchMerchData() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Inventory_stock')
          .doc('Merch & Accessories')
          .get();

      if (documentSnapshot.exists) {
        Map<String, dynamic>? data =
            documentSnapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          List<Map<String, dynamic>> items = data.entries
              .map((entry) {
                // Assuming entry.key is the item name and entry.value contains the item data
                var itemData = entry.value;

                if (itemData is Map<String, dynamic> &&
                    itemData['imagePath'] != null &&
                    itemData['label'] != null &&
                    itemData['price'] != null &&
                    itemData['sizes'] is Map<String, dynamic> &&
                    itemData['sizes']['price'] != null &&
                    itemData['sizes']['quantity'] != null) {
                  return {
                    'image_url': itemData['imagePath'],
                    'label': itemData['label'],
                    'price': itemData['price'], // Main price
                    'size_price': itemData['sizes']
                        ['price'], // Price under sizes
                    'quantity': itemData['sizes']
                        ['quantity'], // Quantity under sizes
                  };
                } else {
                  print('Missing data for item: ${entry.key}');
                  return null; // Return null for incomplete items
                }
              })
              .where((item) => item != null)
              .cast<Map<String, dynamic>>()
              .toList(); // Filter and cast non-null items

          setState(() {
            _merchItems = items;
          });

          print('Fetched merchandise items: ${_merchItems.length} items');
        } else {
          print('Document data is null!');
        }
      } else {
        print('No such document!');
      }
    } catch (e) {
      print('Error fetching merchandise data: $e');
    }
  }

  void _navigateToUniformPage(String courseLabel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollegeUniSelectionPage(
          courseLabel: courseLabel,
          currentProfileInfo: widget.profileInfo,
        ),
      ),
    );
  }

  void _navigateToDetailPage(Map<String, dynamic> itemData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailSelectionMerch(
          label: itemData['label'],
          imagePath: itemData['imagePath'],
          price: itemData['Price'],
          quantity: itemData['quantity'],
          currentProfileInfo: widget.profileInfo,
        ),
      ),
    );
  }

  void _navigateToSHSPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SHSUniformsPage(
          currentProfileInfo: widget.profileInfo,
        ),
      ),
    );
  }

  void _showQuickView(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                size: 50, color: Colors.white),
                            Text('Image failed to load',
                                style: TextStyle(color: Colors.white)),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = context.isMobileDevice;
    final bool isTablet = context.isTabletDevice;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF046be0),
        automaticallyImplyLeading: false,
        title: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: isMobile ? 20.0 : 24.0,
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
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.notifications,
                color: Colors.white, size: isMobile ? 20.0 : 24.0),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        NotificationsPage(userId: widget.profileInfo.userId)),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart,
                color: Colors.white, size: isMobile ? 20.0 : 24.0),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_bag,
                color: Colors.white, size: isMobile ? 20.0 : 24.0),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PreOrderPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAnnouncementImages,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(0),
                children: <Widget>[
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            // Announcement Images
                            Container(
                              height: isMobile
                                  ? MediaQuery.of(context).size.height * 0.25
                                  : MediaQuery.of(context).size.height * 0.3,
                              width: double.infinity,
                              child: _imageUrls.isNotEmpty
                                  ? PageView.builder(
                                      controller: _pageController,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentIndex = index;
                                        });
                                      },
                                      itemCount: _imageUrls.length,
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            _showQuickView(_imageUrls[index]);
                                          },
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            child: Image.network(
                                              _imageUrls[index],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.broken_image,
                                                        size: 50),
                                                    Text(
                                                        'Image failed to load'),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child:
                                          Text('No announcements available')),
                            ),
                            if (_imageUrls.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: DotsIndicator(
                                  dotsCount: _imageUrls.length,
                                  position: _currentIndex.toDouble(),
                                  decorator: DotsDecorator(
                                    activeColor: Colors.blue,
                                    size: isMobile
                                        ? Size(6.0, 6.0)
                                        : Size(8.0, 8.0),
                                    activeSize: isMobile
                                        ? Size(10.0, 10.0)
                                        : Size(12.0, 12.0),
                                  ),
                                ),
                              ),
                            // Bold text below announcements
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Merch/Accessories',
                                style: TextStyle(
                                  fontSize: isMobile ? 25.0 : 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Merchandise Items Display
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16.0), // Adjust padding as needed
                              child:
                                  _buildFixedImageButtons(), // Add the fixed image button here
                            ),
                            // Uniforms Section
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Uniforms',
                                style: TextStyle(
                                  fontSize: isMobile ? 25.0 : 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Image buttons with labels
                            Container(
                              padding: EdgeInsets.only(bottom: 50.0),
                              child: GridView.count(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                crossAxisCount: 3,
                                childAspectRatio: 1.0, // Square buttons
                                children: [
                                  _buildImageButton('assets/images/bacomm.png',
                                      'BACOMM', null),
                                  _buildImageButton('assets/images/IT&CPE.png',
                                      'IT&CPE', null),
                                  _buildImageButton(
                                      'assets/images/hrm and culinary.png',
                                      'HRM & Culinary',
                                      null),
                                  _buildImageButton(
                                      'assets/images/bsa and bsba.png',
                                      'BSA & BSBA',
                                      null),
                                  _buildImageButton('assets/images/tourism.png',
                                      'Tourism', null),
                                  _buildImageButton(
                                      'assets/images/SHS.png', 'SHS', null),
                                ],
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          // Bottom Navigation Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.navigationItems
                  .map((item) => Flexible(
                        flex: 1,
                        child: buildBottomNavItem(
                          item['icon'],
                          item['label'],
                          item['onPressed'],
                          isMobile,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton(
      String imagePath, String label, Map<String, dynamic>? itemData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (label != 'SHS') {
              _navigateToUniformPage(label);
            } else {
              _navigateToSHSPage();
            }
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image, size: 50);
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 4), // Spacing between image and label
        Text(label, style: TextStyle(color: Colors.black)),
      ],
    );
  }

  // Replace this method once method is found :D
  Widget _buildFixedImageButtons() {
    final String firstImageUrl =
        "https://firebasestorage.googleapis.com/v0/b/unistock-266e8.appspot.com/o/merch_images%2F30th%20Anniversary%20Shirt_1730006786909.png?alt=media&token=c48ecf11-64ad-4483-8c87-45b20c167ff3";
    final String firstLabel = "30th Anniversary Shirt";
    final int firstPrice = 300;
    final int firstQuantity = 1;

    final String secondImageUrl =
        "https://firebasestorage.googleapis.com/v0/b/unistock-266e8.appspot.com/o/merch_images%2FSTI%20Aqua%20Flask%20Limited%20Edition_1730008418832.png?alt=media&token=c114d53b-e417-499d-a832-2ffca80ef700";
    final String secondLabel = "STI Aqua Flask Limited Edition";
    final int secondPrice = 799;
    final int secondQuantity = 1;

    final String thirdImageUrl =
        "https://firebasestorage.googleapis.com/v0/b/unistock-266e8.appspot.com/o/merch_images%2FSTI%20Robot%20Pin_1730724347007.png?alt=media&token=4748fe68-c1ef-4c93-8cc6-7c91da121bf6";
    final String thirdLabel = "STI Robot Pin";
    final int thirdPrice = 50;
    final int thirdQuantity = 1;

    return Container(
      height: 180, // Increased height to accommodate label and prevent overflow
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildFixedImageButton(
                firstImageUrl, firstLabel, firstPrice, firstQuantity),
            SizedBox(width: 20), // Increased space between buttons
            _buildFixedImageButton(
                secondImageUrl, secondLabel, secondPrice, secondQuantity),
            SizedBox(width: 20), // Increased space between buttons
            _buildFixedImageButton(
                thirdImageUrl, thirdLabel, thirdPrice, thirdQuantity),
            // Add more items as needed
          ],
        ),
      ),
    );
  }

  Widget _buildFixedImageButton(
      String imageUrl, String label, int price, int quantity) {
    return Container(
      width: 120, // Increased width for better spacing
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailSelectionMerch(
                    label: label,
                    imagePath: imageUrl,
                    price: price,
                    quantity: quantity,
                    currentProfileInfo: widget.profileInfo,
                  ),
                ),
              );
            },
            child: Container(
              width: 100, // Width of the image container
              height: 100, // Height of the image container
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 8), // Space between image and label
          Container(
            height: 40, // Fixed height for label container for alignment
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black,
              ),
              textAlign: TextAlign.center, // Center the text
            ),
          )
        ],
      ),
    );
  }

  Widget buildBottomNavItem(IconData icon, String categoryName,
      VoidCallback onPressed, bool isMobile) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            child: Icon(icon, color: Colors.blue, size: isMobile ? 24 : 30),
          ),
          SizedBox(height: 4),
          Text(
            categoryName,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }
}
