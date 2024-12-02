import 'package:UNISTOCK/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController studentId = TextEditingController();
  TextEditingController contactNumber = TextEditingController();
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String passwordPattern =
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$';
  final String emailPattern = r'^[a-zA-Z0-9._%+-]+@(batangas\.sti\.edu\.ph)$';

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Color(0xFF046be0),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 36.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Arial',
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'UNI',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'STOCK',
                            style: TextStyle(color: Color(0xFFFFEB3B)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: mediaQuery.size.width * 0.1),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(130, 143, 143, 143),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildInputField('* Student Name', name,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^[a-zA-Z ]*$')),
                              ]),
                          const SizedBox(height: 20),
                          _buildInputField('* Email', email),
                          const SizedBox(height: 20),
                          _buildInputField('* Student ID', studentId,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                    11), // Limit to 11 digits
                              ]),
                          const SizedBox(height: 20),
                          _buildInputField('* Contact Number', contactNumber,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                    11), // Limit to 11 digits
                              ]),
                          const SizedBox(height: 20),
                          _buildInputField('* Password', password,
                              isPassword: true),
                          const SizedBox(height: 20),
                          _buildInputField(
                              '* Confirm Password', confirmPassword,
                              isConfirmPassword: true),
                          const SizedBox(height: 20),
                          _buildRegisterButton(mediaQuery),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already Have An Account? ',
                                  style: TextStyle(color: Colors.white)),
                              GestureDetector(
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {bool isPassword = false,
      bool isConfirmPassword = false,
      List<TextInputFormatter>? inputFormatters}) {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8), // Less rounded corners
      ),
      child: TextField(
        controller: controller,
        obscureText: (isPassword && _obscureText) ||
            (isConfirmPassword && _obscureConfirmText),
        inputFormatters: inputFormatters, // Add input formatters here
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white), // Bright white text
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // Less rounded corners
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // Less rounded corners
            borderSide: BorderSide(
              color: Color(0xFFFFEB3B),
              width: 2.0,
            ),
          ),
          border: InputBorder.none,
          suffixIcon: (isPassword || isConfirmPassword)
              ? IconButton(
                  icon: Icon(
                    (isPassword ? _obscureText : _obscureConfirmText)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isPassword) {
                        _obscureText = !_obscureText;
                      } else {
                        _obscureConfirmText = !_obscureConfirmText;
                      }
                    });
                  },
                )
              : null,
        ),
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildRegisterButton(MediaQueryData mediaQuery) {
    return InkWell(
      borderRadius: BorderRadius.circular(8), // Less rounded corners for button
      onTap: () {
        if (name.text.isEmpty ||
            email.text.isEmpty ||
            password.text.isEmpty ||
            confirmPassword.text.isEmpty ||
            studentId.text.isEmpty ||
            contactNumber.text.isEmpty) {
          _showErrorDialog('Please fill in all fields.');
        } else if (!RegExp(emailPattern).hasMatch(email.text)) {
          _showErrorDialog(
              'Please enter a valid microsoft account (e.g., example.123456@batangas.sti.edu.ph)');
        } else if (!RegExp(passwordPattern).hasMatch(password.text)) {
          _showErrorDialog(
              'Password must be at least 8 characters, include an uppercase letter, a lowercase letter, a number, and a special character.');
        } else if (password.text != confirmPassword.text) {
          _showErrorDialog('Passwords do not match.');
        } else if (contactNumber.text.length != 11) {
          _showErrorDialog('Contact number must be exactly 11 digits.');
        } else {
          // Show Terms and Conditions Dialog
          showTermsAndConditionsDialog(context);
        }
      },
      child: Container(
        height: mediaQuery.size.height * 0.06,
        width: mediaQuery.size.width * 0.5,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 15, 5, 93),
          borderRadius:
              BorderRadius.circular(8), // Less rounded corners for button
        ),
        child: const Center(
          child: Text(
            'REGISTER',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }

  void showTermsAndConditionsDialog(BuildContext parentContext) {
    bool isChecked = false; // Checkbox state

    showDialog(
      context: parentContext,
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
                    '1. Account Creation: You must provide accurate and complete information during the registration process. UniStock will not be liable for errors caused by incorrect user inputs.\n\n'
                    '2. Data Privacy: Your personal information will be collected, stored and used solely for app features. By registering, you consent to our data handling practices.\n\n'
                    '3. Use of the application: This app is exclusively designed for uniform and merchandise reservations. Misuse of the app for unauthorized purposes may result in the immediate termination of your account and punishment of the user.\n\n'
                    '4. Eligibility: Only students or authorized personnel connected with STI College Batangas may register. By registering, you confirm that you meet the eligibility requirements.\n\n'
                    '5. Agreement: By clicking the "Accept" button, you confirm that you have read, understand, and agree to the terms and conditions.\n\n',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              actions: <Widget>[
                Row(
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isChecked = value ?? false;
                        });
                      },
                    ),
                    const Flexible(
                      child: Text(
                        'I have read and agree to the Terms and Conditions.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  child: Text(
                    'Accept',
                    style: TextStyle(
                      color: isChecked
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                  ),
                  onPressed: isChecked
                      ? () {
                          Navigator.of(context).pop();
                          _showEmailVerificationDialog(
                              parentContext); // Use parentContext
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEmailVerificationDialog(BuildContext context) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );

      await userCredential.user!.sendEmailVerification();

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'userId': userCredential.user!.uid,
        'name': name.text,
        'email': email.text,
        'studentId': studentId.text,
        'contactNumber': contactNumber.text,
        'createdAt': Timestamp.now(),
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Email Verification'),
            content: const Text(
                'A verification email has been sent to your email address. Please verify to complete your registration.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
