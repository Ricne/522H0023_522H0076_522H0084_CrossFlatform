import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/components/my_button.dart';
import 'package:final_project_flatform/components/my_textfield.dart';
import 'package:final_project_flatform/components/square_title.dart';
import 'package:final_project_flatform/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform; 

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900), // Ngày bắt đầu
      lastDate: DateTime.now(), // Ngày kết thúc
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

String generateAvatar(String fullName) {
  if (fullName.isEmpty) return 'A';
  return fullName.trim()[0].toUpperCase();
}

Future<String> uploadAvatar(String fullName) async {
  try {
    String avatarLetter = generateAvatar(fullName);
    print("Avatar Letter: $avatarLetter");

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = Colors.blue;

    const size = 100.0;

    if (!kIsWeb) {
      canvas.translate(0, size);
    }

    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: avatarLetter,
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size);

    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final uri = Uri.parse("https://api.cloudinary.com/v1_1/dj7dzrxjg/image/upload");

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = 'avatar_unsigned'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        pngBytes,
        filename: '$fullName.png',
        contentType: MediaType('image', 'png'),
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);
      return data['secure_url'];
    } else {
      print("Upload failed: ${response.statusCode}");
      throw Exception("Failed to upload avatar");
    }
  } catch (e) {
    print("Upload avatar error: $e");
    throw Exception("Failed to upload avatar.");
  }
}

String formatPhoneNumber(String phone) {
  phone = phone.trim();
  if (phone.startsWith('0')) {
    phone = '+84' + phone.substring(1);
  } else if (!phone.startsWith('+')) {
    phone = '+84' + phone;
  }
  return phone;
}


    void signUserUp() async {
      final rawPhone = _phoneController.text.trim();
      final formattedPhone = formatPhoneNumber(rawPhone);
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return const Center(
    //       child: CircularProgressIndicator(),
    //     );
    //   },
    // );

    try {
      if (!_isFormValid()) {
        if (!mounted) return;
        Navigator.pop(context);
        showErrorMessage('Please fill in all fields correctly!');
        return;
      }

      if (_passwordController.text.length < 6 ||
          _confirmPasswordController.text.length < 6) {
        if (!mounted) return;
        Navigator.pop(context);
        showErrorMessage('Password must be at least 6 characters!');
        return;
      }

      if (_passwordController.text == _confirmPasswordController.text) {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final userMail = _emailController.text.trim();
        print('User registered with UID: $userMail');

        String avatarUrl = await uploadAvatar(_fullNameController.text.trim());

        await FirebaseFirestore.instance.collection('users').doc(userMail).set({
          'fullName': _fullNameController.text.trim(),
          'dob': _selectedDate == null
              ? ''
              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          'phone': formattedPhone,  
          'email': _emailController.text.trim(),
          'avatarUrl': avatarUrl,
          'isTwoFactorEnabled': false,
        });

        if (!mounted) return;
        Navigator.pop(context);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail)
            .collection('emails')
            .doc('dummy')
            .set({'message': 'No emails yet'});

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail)
            .collection('emails')
            .add({
          'senderName': 'Sender Name',
          'subject': 'Subject of the email',
          'text': 'Body of the email',
          'time': FieldValue.serverTimestamp(),
          'unread': true,
          'label': null,
          'isStarred': false,
        });
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        showErrorMessage('Passwords don\'t match!');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showErrorMessage(e.code);
    }
  }

  bool _isFormValid() {
    final phone = _phoneController.text.trim();
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty &&
        _fullNameController.text.trim().isNotEmpty &&
        phone.isNotEmpty &&
        phone.length == 10 &&
        RegExp(r'^\d{10}$').hasMatch(phone) && // Kiểm tra chỉ chứa số
        _selectedDate != null;
  }

  void showErrorMessage(String message) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Center(
              child: Text(
                message,
              ),
            ),
          );
        });
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
                SizedBox(
                  height: 25,
                ),
                Image.asset(
                  'assets/gmail.png',
                  height: 90,
                ),
                Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 22,
                  ),
                ),
                Text('Let\'s create an account Gmail for you.'),
                const SizedBox(
                  height: 25,
                ),
                MyTextField(
                  controller: _fullNameController,
                  hintText: 'Enter your full name',
                  obscureText: false,
                  isEmailField: false,
                ),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    width: double.infinity, // Chiếm toàn bộ chiều rộng
                    margin: EdgeInsets.symmetric(
                        horizontal: 25), // Canh lề ngang giống các trường khác
                    padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12), // Padding giống MyTextField
                    decoration: BoxDecoration(
                      color: Colors.white, // Nền giống các trường nhập
                      border: Border.all(
                          color: Colors.grey), // Viền giống các trường nhập
                      borderRadius: BorderRadius.circular(
                          8), // Góc bo giống các trường nhập
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select your date of birth'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                  controller: _phoneController,
                  hintText: 'Enter your phone number',
                  obscureText: false,
                  isEmailField: false,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                  controller: _emailController,
                  hintText: 'Enter your email',
                  obscureText: false,
                  isEmailField: true,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                  controller: _passwordController,
                  hintText: 'Enter your password',
                  obscureText: true,
                  isEmailField: false,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm your password',
                  obscureText: true,
                  isEmailField: false,
                ),
                const SizedBox(
                  height: 30,
                ),
                MyButton(
                  text: 'Sign Up',
                  onTap: signUserUp,
                ),
                const SizedBox(
                  height: 50,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Or continute with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Aldready have an account?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Login now',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 25,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
