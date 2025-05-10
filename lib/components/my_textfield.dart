import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool isEmailField;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.isEmailField,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  String _errorText = '';
  int _charCount = 0;
  bool _isValidEmail = false;

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[^@]+@gmail\.com$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.isEmailField;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType:
            isEmail ? TextInputType.emailAddress : TextInputType.text,
        textInputAction: TextInputAction.next,
        maxLength: isEmail ? 100 : null,
        onChanged: (value) {
          if (isEmail) {
            setState(() {
              _charCount = value.length;
              _isValidEmail = _isEmailValid(value);
              _errorText = (_isValidEmail || value.isEmpty)
                  ? ''
                  : 'Please enter a valid email address. Ex: abc@gmail.com';
            });
          }
        },
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          counterText: isEmail ? '$_charCount/100' : null,
          filled: true,
          fillColor: Colors.white,

          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isEmail
                  ? (_isValidEmail ? Colors.green : Colors.grey)
                  : Colors.grey,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isEmail
                  ? (_isValidEmail ? Colors.green : Colors.blue)
                  : Colors.blue,
              width: 2.0,
            ),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),

          suffixIcon: isEmail && _isValidEmail
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,

          errorText: isEmail && _errorText.isNotEmpty ? _errorText : null,
        ),
      ),
    );
  }
}
