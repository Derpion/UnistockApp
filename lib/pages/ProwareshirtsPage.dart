import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:UNISTOCK/pages/CheckoutPage.dart';
import 'package:UNISTOCK/ProfileInfo.dart';

class ProwareShirtsPage extends StatefulWidget {
  final ProfileInfo currentProfileInfo;

  ProwareShirtsPage({required this.currentProfileInfo});

  @override
  _ProwareShirtsPageState createState() => _ProwareShirtsPageState();
}

class _ProwareShirtsPageState extends State<ProwareShirtsPage> {
  String selectedShirtType = 'College'; // Default selection
  String selectedShirtCategory = 'PE'; // Default category

  // Firestore paths
  final Map<String, String> paths = {
    'College_PE': 'Inventory_stock/Proware & PE/PE/College_PE',
    'SHS_PE': 'Inventory_stock/Proware & PE/PE/SHS_PE',
    'College_Female_Proware':
        'Inventory_stock/Proware & PE/Proware/College_Female_Proware',
    'College_Male_Proware':
        'Inventory_stock/Proware & PE/Proware/College_Male_Proware',
    'SHS_Proware': 'Inventory_stock/Proware & PE/Proware/SHS_Proware',
    'NSTP_Shirt': 'Inventory_stock/Proware & PE/NSTP/NSTP_Shirt',
  };

  List<Map<String, dynamic>> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems(); // Fetch items on initialization
  }

  Future<void> fetchItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      String path;

      // Determine Firestore path based on the selected type and category
      if (selectedShirtCategory == 'PE') {
        path = selectedShirtType == 'College'
            ? paths['College_PE']!
            : paths['SHS_PE']!;
      } else if (selectedShirtCategory == 'Proware') {
        if (selectedShirtType == 'College') {
          path = paths['College_Female_Proware']!;
        } else {
          path = paths['SHS_Proware']!;
        }
      } else {
        path = paths['NSTP_Shirt']!;
      }

      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection(path).get();

      final fetchedItems = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      setState(() {
        items = fetchedItems;
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching items: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Choose your Proware/Shirt',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (isLoading)
              Center(
                child: CircularProgressIndicator(),
              )
            else if (items.isEmpty)
              Center(
                child: Text('No items found.'),
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutPage(
                              category: selectedShirtCategory,
                              label: item['name'] ?? 'Unnamed Shirt',
                              itemSize: null, // No size selection
                              imagePath: item['image'] ?? '',
                              unitPrice: item['price'] ?? 0,
                              price: item['price'] ?? 0,
                              quantity: 1,
                              currentProfileInfo: widget.currentProfileInfo,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(10),
                                ),
                                child: Image.network(
                                  item['image'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                item['name'] ?? 'Unnamed Shirt',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: Text(
                                '\₱${item['price'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
