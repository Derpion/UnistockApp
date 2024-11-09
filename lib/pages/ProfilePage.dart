import 'package:UNISTOCK/ProfileInfo.dart';
import 'package:UNISTOCK/login_screen.dart';
import 'package:UNISTOCK/pages/EditProfilePage.dart';
import 'package:UNISTOCK/pages/OrdersPage.dart' as UNISTOCKOrder;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final ProfileInfo profileInfo;

  ProfilePage({required this.profileInfo});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<UNISTOCKOrder.Order>? orders;
  File? _imageFile;
  String? _imageUrl;

  late ProfileInfo currentProfileInfo;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserOrders();
    currentProfileInfo = widget.profileInfo;
  }

  Future<void> _fetchUserProfile() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _imageUrl = userDoc['imageUrl'] as String?;
        });
      }
    }
  }

  Future<void> _fetchUserOrders() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('orders')
            .get();

        setState(() {
          orders = orderSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return UNISTOCKOrder.Order(
              itemName: data['label'] ?? '',
              quantity: data['quantity'] ?? 0,
              price: data['price'] ?? 0,
              orderDate: data['orderDate'] ?? Timestamp.now(),
              category: data['category'] ?? 'Unknown',
              courseLabel: data['courseLabel'] ?? 'Unknown',
            );
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch orders: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadImageToStorage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected.')),
      );
    }
  }

  Future<void> _uploadImageToStorage() async {
    if (_imageFile == null) return;

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profile_images/${currentUser.uid}.jpg');
        UploadTask uploadTask = storageRef.putFile(_imageFile!);
        TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => {});

        String downloadUrl = await storageSnapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'imageUrl': downloadUrl});

        setState(() {
          _imageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile image updated successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  void _viewOrders() {
    if (orders == null || orders!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No orders available yet.')),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UNISTOCKOrder.OrdersPage(),
        ),
      );
    }
  }

  void _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profileInfo: currentProfileInfo),
      ),
    );

    if (result != null && result is ProfileInfo) {
      setState(() {
        currentProfileInfo = result;
      });

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'name': currentProfileInfo.name,
            'studentId': currentProfileInfo.studentId,
            'contactNumber': currentProfileInfo.contactNumber,
            'email': currentProfileInfo.email,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully.')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have been logged out.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAboutUs() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About Us'),
          content: Text(
              "We’re a group of students from STI College Batangas who came together to make life a little easier for our fellow students. "
              "Our app, UniStock, helps streamline the process of buying uniforms and staying updated with school announcements. "
              "The team includes Charles Kenneth Adelantar, James Lawrence Peralta, Desiree Magadia, and Mac Ivan Llagas."),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF046be0),
        title: Text('Profile'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.description, color: Colors.white),
            onPressed: _viewOrders,
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: _editProfile,
          ),
          IconButton(
            icon: Icon(Icons.error_outline, color: Colors.white),
            onPressed: _showAboutUs,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _imageUrl != null
                    ? NetworkImage(_imageUrl!)
                    : AssetImage('assets/images/profilepictdefault.png')
                        as ImageProvider,
                backgroundColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 20),
            Text(
              currentProfileInfo.name.isNotEmpty
                  ? currentProfileInfo.name
                  : "Name not available",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Divider(
              color: Colors.grey,
              thickness: 1,
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.email, color: Color(0xFF046be0)),
              title: Text(
                'Email',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                currentProfileInfo.email.isNotEmpty
                    ? currentProfileInfo.email
                    : "Email not available",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.person, color: Color(0xFF046be0)),
              title: Text(
                'Student ID',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                currentProfileInfo.studentId.isNotEmpty
                    ? currentProfileInfo.studentId
                    : "Student ID not available",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.phone, color: Color(0xFF046be0)),
              title: Text(
                'Contact Number',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                currentProfileInfo.contactNumber.isNotEmpty
                    ? currentProfileInfo.contactNumber
                    : "Contact Number is not available",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _logout,
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 255, 230, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
