import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/pages/auth_page.dart';
import 'package:final_project_flatform/pages/login_page.dart';
import 'package:final_project_flatform/pages/register_page.dart';
import 'package:final_project_flatform/tabs/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordWithPhone extends StatefulWidget {
  @override
  State<ResetPasswordWithPhone> createState() => _ResetPasswordWithPhoneState();
}

class _ResetPasswordWithPhoneState extends State<ResetPasswordWithPhone> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _verificationId;
  String? phoneChange;

  String _formatPhone(String phone) {
    phone = phone.trim();
    if (phone.startsWith('0')) {
      return '+84${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      return '+$phone';
    }
    return phone;
  }

  // Kiểm tra email và số điện thoại trong Firestore

  Future<void> _verifyOTPAndLinkPhone() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter OTP")),
      );
      return;
    }

    try {
      if (_verificationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Verification ID is missing. Request OTP again.")),
        );
        return;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Liên kết số điện thoại với tài khoản hiện tại
        await currentUser.linkWithCredential(credential);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone number linked successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user signed in. Please log in first.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to link phone number: ${e.toString()}")),
      );
    }
  }

  Future<void> _sendOTP() async {
    String phone = _phoneController.text.trim();

    if (!phone.startsWith('+')) {
      phoneChange = '+84' + phone.substring(1);  
    }

    if (!await _validateEmailAndPhone()) {
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneChange,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Tự động xác minh OTP
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send OTP: ${e.message}")),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("OTP sent to $phone")),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending OTP: ${e.toString()}")),
      );
    }
  }

  Future<bool> _validateEmailAndPhone() async {
  final email = _emailController.text.trim();
  final phone = _phoneController.text.trim();
  final formattedPhone = _formatPhone(phone);

  if (email.isEmpty || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please enter both email and phone number")),
    );
    return false;
  }

  try {
    // So sánh với số điện thoại đã được định dạng +84
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .where('phone', isEqualTo: formattedPhone)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("No account found with this email and phone number")),
      );
      return false;
    }
    return true;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error validating email and phone: ${e.toString()}")),
    );
    return false;
  }
}

  Future<void> _verifyOTPAndResetPassword() async {
    final otp = _otpController.text.trim();
    final newPassword = _passwordController.text.trim();

    if (otp.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter OTP and new password")),
      );
      return;
    }

    try {
      if (_verificationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Verification ID is missing. Request OTP again.")),
        );
        return;
      }

      // Tạo credential từ OTP
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Xác minh OTP và liên kết số điện thoại
      await FirebaseAuth.instance
          .signInWithCredential(credential)
          .then((authResult) async {
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Cập nhật mật khẩu của người dùng
          await user.updatePassword(newPassword);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password updated successfully")),
          );

          // Quay lại trang đăng nhập hoặc trang chính
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AuthPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No user found after verification")),
          );
        }
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid OTP: ${e.message}")),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Failed to verify OTP or update password: ${e.toString()}")),
      );
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password updated successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user signed in. Please log in first.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update password: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset Password with Phone"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendOTP,
              child: Text("Send OTP"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: "OTP",
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: Icon(Icons.password),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _verifyOTPAndResetPassword,
              child: Text("Reset Password"),
            ),
          ],
        ),
      ),
    );
  }
}