import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateProfileScreen extends StatefulWidget {
  UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _avatarUrl;
  final userMail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(userMail);
      final doc = await docRef.get();

      // Kiểm tra nếu document không tồn tại, tạo mới
      if (!doc.exists) {
        await docRef.set({
          'fullName': '', // Mặc định hoặc để trống
          'email': user.email ?? '',
          'dob': '',
          'phone': '',
          'avatarUrl': '', // Mặc định là ảnh trống
        });
      }

      // Tải dữ liệu người dùng vào các controller
      setState(() {
        _fullNameController.text = doc['fullName'] ?? '';
        _emailController.text = doc['email'] ?? '';
        _dobController.text = doc['dob'] ?? '';
        _phoneController.text = doc['phone'] ?? '';
        _avatarUrl = doc['avatarUrl']; // Load avatar URL
      });
    }
  }

  Future<void> _pickImage() async {
    const cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/dj7dzrxjg/image/upload';
    const uploadPreset = 'avatar_unsigned'; // Thường đặt sẵn trong dashboard của Cloudinary

    try {
      Uint8List? imageBytes;
      String? fileName;

      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null) {
          imageBytes = result.files.first.bytes;
          fileName = result.files.first.name;
        }
      } else {
        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          imageBytes = await pickedFile.readAsBytes();
          fileName = pickedFile.name;
        }
      }

      if (imageBytes == null || fileName == null) return;

      // Gửi ảnh lên Cloudinary
      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUploadUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);

        final imageUrl = data['secure_url'];
        if (!mounted) return;
        setState(() {
          _avatarUrl = imageUrl;
        });
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
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
        'avatarUrl': _avatarUrl ?? '', // Save the avatar URL to Firestore
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
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
          icon: const Icon(LineAwesomeIcons.arrow_left_solid),
        ),
        title: const Text(
          'Edit Profile',
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: _avatarUrl != null
                            ? Image.network(_avatarUrl!) // Hiển thị avatar mới
                            : const Image(
                                image: AssetImage('assets/avatar.png'),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage, // Mở dialog để chọn ảnh
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
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Form(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
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
                        decoration: InputDecoration(
                          label: const Text('Phone'),
                          prefixIcon: const Icon(LineAwesomeIcons.phone_alt_solid),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text(
                            'Save Profile',
                            style: TextStyle(color: Colors.black),
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
