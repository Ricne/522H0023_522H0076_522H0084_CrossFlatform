import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class InformationUser extends StatefulWidget {
  InformationUser({super.key});

  @override
  State<InformationUser> createState() => _InformationUser();
}

class _InformationUser extends State<InformationUser> {
  final userMail = FirebaseAuth.instance.currentUser?.email;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    getUserAvatarUrl();
    _loadUserData(); // Tải dữ liệu người dùng khi mở trang
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

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .get();
      setState(() {
        _fullNameController.text = doc['fullName'] ?? '';
        _emailController.text = doc['email'] ?? '';
        _dobController.text = doc['dob'] ?? '';
        _phoneController.text = doc['phone'] ?? '';
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final updatedData = {
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'dob': _dobController.text,
        'phone': _phoneController.text,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedData);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
        ),
        title: const Text(
          'Information User',
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
                        controller: _fullNameController,
                        readOnly: true,
                        decoration: InputDecoration(
                          label: const Text('Full Name'),
                          prefixIcon: const Icon(LineAwesomeIcons.user),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: InputDecoration(
                          label: const Text('Email'),
                          prefixIcon: const Icon(LineAwesomeIcons.envelope),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        decoration: InputDecoration(
                          label: const Text('Birthday'),
                          prefixIcon: const Icon(LineAwesomeIcons.calendar),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        readOnly: true,
                        decoration: InputDecoration(
                          label: const Text('Phone'),
                          prefixIcon: const Icon(LineAwesomeIcons.phone_solid),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
