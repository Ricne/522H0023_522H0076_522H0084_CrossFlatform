import 'package:final_project_flatform/pages/auth_page.dart';
import 'package:final_project_flatform/services/noti_service.dart';
import 'package:final_project_flatform/services/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create Firebase for project
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD2ggKZRshDQSX8yrUsGmyABchRdw72C74",
        authDomain: "final-project-flatform.firebaseapp.com",
        projectId: "final-project-flatform",
        storageBucket: "final-project-flatform.firebasestorage.app",
        messagingSenderId: "926312719257",
        appId: "1:926312719257:web:10d9c9abd70971bdb0a908",
        measurementId: "G-G33ZLWHB5K"),
    );
  } 
  else {
    await Firebase.initializeApp();
    await NotificationService.initialize();
    await NotificationService.loadNotificationPreference();
  }
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      NotificationService.listenForNewEmails();
      print("Listening for emails for user: $user"); 
    }
  });
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeProvider.themeMode,
        home: AuthPage());
  }
}
