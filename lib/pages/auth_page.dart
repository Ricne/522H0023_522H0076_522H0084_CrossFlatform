import 'package:final_project_flatform/pages/login_or_register_page.dart';
import 'package:final_project_flatform/pages/login_page.dart';
import 'package:final_project_flatform/tabs/front_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            //user is logged in
            if (snapshot.hasData) {
              return FrontPage();
            }
            //user is NOT logged in
            else {
              return LoginOrRegisterPage();
            }
          }),
    );
  }
}
