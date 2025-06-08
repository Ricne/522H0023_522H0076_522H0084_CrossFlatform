import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class PasswordUser extends StatefulWidget {
  PasswordUser({super.key});

  @override
  State<PasswordUser> createState() => _PasswordUser();
}

class _PasswordUser extends State<PasswordUser> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? avatarUrl;
  final userMail = FirebaseAuth.instance.currentUser?.email;
  void initState() {
    super.initState();
    getUserAvatarUrl();
  }

  Future<bool> _reauthenticate(String currentPassword) async {
    final user = FirebaseAuth.instance.currentUser;

    // Tạo credential từ mật khẩu hiện tại
    final AuthCredential credential = EmailAuthProvider.credential(
      email: user?.email ?? '', // Email của người dùng
      password: currentPassword, // Mật khẩu hiện tại
    );

    try {
      // Reauthenticate người dùng với credential mới
      await user?.reauthenticateWithCredential(credential);
    } catch (e) {
      // Nếu mật khẩu hiện tại sai
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Current password is incorrect")));
      return false;
    }

    return true;
  }

  Future<void> getUserAvatarUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .get();
      setState(() {
        avatarUrl = doc.data()?['avatarUrl'] ?? 'assets/user.png';
      });
    } else {
      setState(() {
        avatarUrl = 'assets/user.png'; // Trường hợp không có thông tin user
      });
    }
  }

  // Hàm thay đổi mật khẩu
  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Kiểm tra mật khẩu xác nhận
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("New password and confirm password do not match")));
      return;
    }

    // Kiểm tra mật khẩu hiện tại
    bool isReauthenticated = await _reauthenticate(currentPassword);
    if (!isReauthenticated) {
      return;
    }

    // Tiến hành cập nhật mật khẩu mới
    final user = _auth.currentUser;
    try {
      await user?.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password updated successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to update password")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LineAwesomeIcons.arrow_left_solid),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Stack(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircleAvatar(
                        backgroundImage: avatarUrl != null &&
                                avatarUrl!.startsWith('http')
                            ? CachedNetworkImageProvider(avatarUrl!)
                            : AssetImage('assets/user.png') as ImageProvider,
                        radius: 20,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          LineAwesomeIcons.camera_solid,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Form(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          label: const Text('Current Password'),
                          prefixIcon: const Icon(LineAwesomeIcons.lock_solid),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          label: const Text('New Password'),
                          prefixIcon: const Icon(LineAwesomeIcons.lock_solid),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          label: const Text('Confirm New Password'),
                          prefixIcon: const Icon(LineAwesomeIcons.lock_solid),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _changePassword,
                        child: Text("Change Password"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
