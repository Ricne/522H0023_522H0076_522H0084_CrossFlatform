import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool isEmailField;

  MyTextField({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.isEmailField,
  });

  @override
  _MyTextFieldState createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late bool _isValidEmail;
  late String _errorText;
  late int _charCount;

  @override
  void initState() {
    super.initState();
    _isValidEmail = true;
    _errorText = '';
    _charCount = 0;
  }

  bool _isEmailValid(String value) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(value);
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
        onChanged: (value) {
          setState(() {
            _charCount = value.length;
            _isValidEmail = _isEmailValid(value);
            _errorText = (_isValidEmail || value.isEmpty)
                ? ''
                : 'Please enter a valid email address. Ex: abc@gmail.com';
          });
        },
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.white,

          // Border styles
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isEmail
                  ? (_isValidEmail ? Colors.green : Colors.grey)
                  : Colors.grey,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isEmail
                  ? (_isValidEmail ? Colors.green : Colors.blue)
                  : Colors.blue,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),

          suffixText: isEmail ? '$_charCount/100' : null,
          suffixStyle: TextStyle(color: Colors.grey[500]),

          errorText: isEmail && _errorText.isNotEmpty ? _errorText : null,
        ),
      ),
    );
  }
}
