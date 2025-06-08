import 'package:final_project_flatform/services/noti_service.dart';
import 'package:final_project_flatform/services/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Usersetting extends StatefulWidget {
  @override
  _UsersettingState createState() => _UsersettingState();
}

class _UsersettingState extends State<Usersetting> {
  final userMail = FirebaseAuth.instance.currentUser?.email;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool isTwoFactorEnabled = false;
  bool isNotificationEnabled = false;
  bool isLoading = true;

  // Hàm tải dữ liệu từ Firestore
  Future<void> loadUserSettings() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;

        setState(() {
          isTwoFactorEnabled = data != null && data.containsKey('isTwoFactorEnabled')
              ? data['isTwoFactorEnabled']
              : false;
          isNotificationEnabled = data != null && data.containsKey('isNotificationEnabled')
              ? data['isNotificationEnabled']
              : false;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load settings: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // Hàm gửi OTP
  Future<void> sendOTP() async {
    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) {
      // Thêm mã quốc gia (ví dụ: +84 cho Việt Nam)
      phone = '+84 ' + phone.substring(1);
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a phone number")),
      );
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone verified automatically")),
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: ${e.message}")),
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
  }

  // Hàm liên kết số điện thoại
  Future<void> linkPhoneNumber() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter the OTP")),
      );
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone number linked successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user signed in")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to link phone number: $e")),
      );
    }
  }

  // Hàm để bật/tắt xác thực 2 lớp
  void toggleTwoFactor() {
    setState(() {
      isTwoFactorEnabled = !isTwoFactorEnabled;
    });

    // Lưu trạng thái bật/tắt 2FA vào Firestore
    saveTwoFactorStatus(isTwoFactorEnabled);
  }

  // Lưu trạng thái 2FA vào Firestore
  Future<void> saveTwoFactorStatus(bool status) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userMail).set(
          {
            'isTwoFactorEnabled': status,
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save 2FA status: $e")),
        );
      }
    }
  }

  // Lấy trạng thái 2FA từ Firestore khi người dùng đăng nhập
  Future<void> loadTwoFactorStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;

          setState(() {
            isTwoFactorEnabled = data != null && data.containsKey('isTwoFactorEnabled')
                ? data['isTwoFactorEnabled']
                : false;
            isNotificationEnabled = data != null && data.containsKey('isNotificationEnabled')
                ? data['isNotificationEnabled']
                : false;
            print("Updated isTwoFactorEnabled: $isTwoFactorEnabled");
            print("Notification Enabled: $isNotificationEnabled");
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load 2FA status: $e")),
        );
      }
    }
  }

  void toggleNotification() async {
    setState(() {
      isNotificationEnabled = !isNotificationEnabled;
    });

    saveNotificationStatus(isNotificationEnabled);
    await NotificationService.updateNotificationPreference(isNotificationEnabled);
  }

  // Hàm lưu trạng thái thông báo
  Future<void> saveNotificationStatus(bool status) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userMail).set(
        {
          'isNotificationEnabled': status,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save notification status: $e")),
      );
    }
  }

  // Hàm tải trạng thái thông báo
  Future<void> loadNotificationStatus() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;

        setState(() {
          isNotificationEnabled = data != null && data.containsKey('isNotificationEnabled')
              ? data['isNotificationEnabled']
              : false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load notification status: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadTwoFactorStatus();
    loadNotificationStatus();
    loadUserSettings();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text("Link Phone Number")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bật/tắt xác thực 2 lớp
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enable 2-Factor Authentication',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: isTwoFactorEnabled,
                      onChanged: (value) {
                        toggleTwoFactor();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Tiêu đề "Enable Notification"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enable Notification',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: isNotificationEnabled,
                      onChanged: (value) {
                        toggleNotification();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dark Mode',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Enter phone number',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: sendOTP,
                  child: Text('Send OTP'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: linkPhoneNumber,
                  child: Text('Verify and Link'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
