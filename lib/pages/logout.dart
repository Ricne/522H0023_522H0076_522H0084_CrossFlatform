import 'package:final_project_flatform/pages/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LogoutHandler {
  static Future<void> logout(BuildContext context) async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;

      if (userEmail != null) {
        // Cập nhật trạng thái 2FA trong Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .update({'isTwoFactorVerified': false});
      }

      await FirebaseAuth.instance.signOut();
      print('User logged out successfully');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => AuthPage()),
      );
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }
}
