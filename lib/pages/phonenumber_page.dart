import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/components/my_button.dart';
import 'package:final_project_flatform/components/my_textfield.dart';
import 'package:final_project_flatform/tabs/mails.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PhoneNumberPage extends StatefulWidget {
  final VoidCallback? onVerified;

  const PhoneNumberPage({Key? key, this.onVerified}) : super(key: key);

  @override
  _PhoneNumberPageState createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    setState(() => _isSendingOtp = true);

    String phoneNumber = _phoneController.text.trim();

    if (phoneNumber.startsWith('0')) {
      phoneNumber = '+84' + phoneNumber.substring(1);
    } else if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+84' + phoneNumber;
    }

    if (phoneNumber.length < 10) {
      _showError('Invalid phone number');
      setState(() => _isSendingOtp = false);
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) {
              widget.onVerified?.call();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Mails()),
              );
            }
          } catch (e) {
            if (mounted) {
              _showError("Auto verification failed: $e");
              setState(() => _isSendingOtp = false);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            _showError("Verification Failed: ${e.message}");
            setState(() => _isSendingOtp = false);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isOtpSent = true;
              _isSendingOtp = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isSendingOtp = false;
            });
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        _showError("Send OTP error: $e");
        setState(() => _isSendingOtp = false);
      }
    }
  }

  void _verifyOTP() async {
    setState(() => _isVerifyingOtp = true);

    final otp = _otpController.text.trim();

    if (otp.isEmpty || _verificationId == null) {
      _showError('Please enter OTP');
      setState(() => _isVerifyingOtp = false);
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .update({'isTwoFactorVerified': true});
      }

      if (mounted) {
        widget.onVerified?.call();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Mails()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Invalid OTP');
        setState(() => _isVerifyingOtp = false);
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // Phone number input
              MyTextField(
                controller: _phoneController,
                hintText: 'Enter phone number',
                obscureText: false,
                isEmailField: false,
              ),

              const SizedBox(height: 25),

              // Send OTP button
              _isSendingOtp
                  ? const CircularProgressIndicator()
                  : MyButton(
                      text: 'Send OTP',
                      onTap: _sendOTP,
                    ),

              if (_isOtpSent) ...[
                const SizedBox(height: 30),
                const Text('Enter OTP code'),
                const SizedBox(height: 10),

                // Use PinCodeTextField here instead of MyTextField
                PinCodeTextField(
                  controller: _otpController,
                  appContext: context,
                  length: 6,
                  onChanged: (_) {},
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(5),
                    fieldHeight: 50,
                    fieldWidth: 40,
                    activeColor: Colors.deepOrange,
                    selectedColor: Colors.blue,
                    inactiveColor: Colors.grey,
                  ),
                ),

                const SizedBox(height: 10),

                _isVerifyingOtp
                    ? const CircularProgressIndicator()
                    : MyButton(
                        text: 'Verify OTP',
                        onTap: _verifyOTP,
                      ),
              ],

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
