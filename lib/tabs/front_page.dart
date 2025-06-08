import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/pages/phonenumber_page.dart';
import 'package:final_project_flatform/services/noti_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_project_flatform/tabs/meet.dart';
import 'package:final_project_flatform/tabs/mails.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FrontPage extends StatefulWidget {
  const FrontPage({Key? key}) : super(key: key);

  @override
  _FrontPageState createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  int currentIndex = 0;
  final List<Widget> _children = const [Mails(), Meet()];
  bool isTwoFactorEnabled = false;
  bool isTwoFactorVerified = false;
  bool isNotificationEnabled = NotificationService.isNotificationEnabled;
  bool isLoading = true;
  final String? userMail = FirebaseAuth.instance.currentUser?.email;

  late final VoidCallback _notiListener;

  @override
  void initState() {
    super.initState();
    loadUserSettings();

    _notiListener = () {
      if (!mounted) return;
      setState(() {
        isNotificationEnabled = NotificationService.isNotificationEnabledNotifier.value;
      });
    };

    NotificationService.isNotificationEnabledNotifier.addListener(_notiListener);
  }

  @override
  void dispose() {
    NotificationService.isNotificationEnabledNotifier.removeListener(_notiListener);
    super.dispose();
  }

  Future<void> loadUserSettings() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .get();

      final data = userDoc.data();

      if (!mounted) return;

      setState(() {
        isTwoFactorEnabled = data?['isTwoFactorEnabled'] ?? false;
        isNotificationEnabled = data?['isNotificationEnabled'] ?? false;
        isTwoFactorVerified = data?['isTwoFactorVerified'] ?? false; // Thêm dòng này
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load settings: $e")),
      );

      setState(() {
        isTwoFactorEnabled = false;
        isNotificationEnabled = false;
        isTwoFactorVerified = false;  // Mặc định false
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SpinKitFadingCircle(
                color: Color.fromARGB(255, 43, 159, 101),
                size: 70.0,
              ),
              SizedBox(height: 30),
              Text(
                "Loading...",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Please wait a second",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isTwoFactorEnabled && !isTwoFactorVerified) {
      return PhoneNumberPage(
        onVerified: () {
          setState(() {
            isTwoFactorVerified = true;
          });
        },
      );
    }

    return Scaffold(
      body: _children[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Colors.red,
        onTap: onTabTapped,
        currentIndex: currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.mail, size: 35),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    child: const Text(
                      '9+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Mail',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.video_call, size: 35),
            label: 'Meet',
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() => currentIndex = index);
  }
}

class FloatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FloatAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 10,
          right: 15,
          left: 15,
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                Material(
                  type: MaterialType.transparency,
                  child: IconButton(
                    splashColor: Colors.grey,
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                Expanded(
                  child: TextField(
                    cursorColor: Colors.black,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      suffixIcon: const Icon(Icons.search),
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.mic),
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}