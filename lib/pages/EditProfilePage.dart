import 'package:UNISTOCK/ProfileInfo.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileInfo profileInfo;

  EditProfilePage({required this.profileInfo});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _studentIdController;
  late TextEditingController _contactNumberController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileInfo.name);
    _studentIdController =
        TextEditingController(text: widget.profileInfo.studentId);
    _contactNumberController =
        TextEditingController(text: widget.profileInfo.contactNumber);
    _emailController = TextEditingController(text: widget.profileInfo.email);
    _passwordController = TextEditingController(text: '');
    _confirmPasswordController =
        TextEditingController(text: ''); // Empty password initially
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      final updatedProfileInfo = ProfileInfo(
        userId: currentUser.uid, // Add userId here
        name: _nameController.text,
        studentId: _studentIdController.text,
        contactNumber: _contactNumberController.text,
        email: _emailController.text,
      );

      try {
        // Update the profile information in Firestore
        await _firestore.collection('users').doc(currentUser.uid).update({
          'userId': updatedProfileInfo.userId,
          'name': updatedProfileInfo.name,
          'studentId': updatedProfileInfo.studentId,
          'contactNumber': updatedProfileInfo.contactNumber,
          'email': updatedProfileInfo.email,
        });

        // If the password has been changed, update it
        if (_passwordController.text.isNotEmpty) {
          await currentUser.updatePassword(_passwordController.text);
        }

        // Return the updated profile info to the previous screen
        Navigator.pop(context, updatedProfileInfo);
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } else {
      // Handle user not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF046be0),
        title: Text('Edit Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^[a-zA-Z ]*$')), // Allow only letters and spaces
              ],
            ),
            TextField(
              controller: _studentIdController,
              decoration: InputDecoration(labelText: 'Student ID'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
            TextField(
              controller: _contactNumberController,
              decoration: InputDecoration(labelText: 'Contact Number'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            // Change Password Section
            SizedBox(height: 20),
            Text(
              'Change Password',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            // Password Field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),

            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_passwordController.text !=
                    _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passwords do not match.')),
                  );
                } else {
                  _saveProfile();
                }
              },
              child: Text(
                'Save',
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
