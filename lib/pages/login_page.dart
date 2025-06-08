import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:final_project_flatform/components/my_button.dart';
import 'package:final_project_flatform/components/my_textfield.dart';
import 'package:final_project_flatform/pages/phonenumber_page.dart';
import 'package:final_project_flatform/tabs/mails.dart';
import 'package:final_project_flatform/tabs/forget_password.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _loadTwoFactorStatus(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['isTwoFactorEnabled'] ?? false;
      }
    } catch (e) {
      print("Error loading 2FA status: $e");
    }
    return false;
  }

  void signUserIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showErrorMessage("Please enter email and password.");
      return;
    }

    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (context) => const Center(child: CircularProgressIndicator()),
    // );

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw FirebaseAuthException(code: 'user-null', message: 'User not found');

      bool isTwoFactorEnabled = await _loadTwoFactorStatus(user.uid);

      if (!mounted) return;
      // Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isTwoFactorEnabled ? PhoneNumberPage() : const Mails(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showErrorMessage(e.message ?? "An error occurred");
    }
  }

  void showErrorMessage(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text("Error")),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showErrorMessage('Please enter your email');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Reset'),
          content: const Text('A password reset link has been sent to your email.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      showErrorMessage(e.message ?? 'An error occurred');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Image.asset('assets/gmail.png', height: 90),
                const Text('Sign In', style: TextStyle(fontSize: 22)),
                const Text('Gmail Account.'),
                const SizedBox(height: 25),
                MyTextField(
                  controller: _emailController,
                  hintText: 'Enter your email',
                  obscureText: false,
                  isEmailField: true,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: _passwordController,
                  hintText: 'Enter your password',
                  obscureText: !showPassword,
                  isEmailField: false,
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: showPassword,
                            onChanged: (value) {
                              setState(() {
                                showPassword = value ?? false;
                              });
                            },
                          ),
                          Text(
                            'Show Password',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResetPasswordWithPhone(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MyButton(text: 'Sign In', onTap: signUserIn),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(thickness: 0.5, color: Colors.grey[400]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Or continue with',
                            style: TextStyle(color: Colors.grey[700])),
                      ),
                      Expanded(
                        child: Divider(thickness: 0.5, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Not a member?', style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Register now',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}