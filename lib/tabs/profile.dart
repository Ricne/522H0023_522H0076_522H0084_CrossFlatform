import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/pages/login_page.dart';
import 'package:final_project_flatform/pages/logout.dart';
import 'package:final_project_flatform/tabs/information_user.dart';
import 'package:final_project_flatform/tabs/password_user.dart';
import 'package:final_project_flatform/tabs/usersetting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'update_profile.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final userMail = FirebaseAuth.instance.currentUser?.email;
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, String?>> getUserData() async {
    if (userMail != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .get();
      return {
        'fullName': doc.data()?['fullName'],
        'dob': doc.data()?['dob'],
        'email': doc.data()?['email'],
        'phone': doc.data()?['phone'],
      };
    }
    return {
      'fullName': '',
      'dob': '',
      'email': '',
      'phone': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    var isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, String?>>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (!snapshot.hasData) {
            return const Text('No data found');
          }

          final userData = snapshot.data;
          final fullName = userData?['fullName'] ?? '';
          final dob = userData?['dob'] ?? '';
          final email = userData?['email'] ?? '';
          final phone = userData?['phone'] ?? '';

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userMail)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircleAvatar(
                              backgroundImage: AssetImage('assets/user.png'),
                              radius: 60,
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data?.data() == null) {
                            return CircleAvatar(
                              backgroundImage: AssetImage('assets/user.png'),
                              radius: 60,
                            );
                          }

                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final avatarUrl =
                              data['avatarUrl'] ?? 'assets/user.png';

                          return CircleAvatar(
                            backgroundImage: avatarUrl.startsWith('http')
                                ? CachedNetworkImageProvider(avatarUrl)
                                : AssetImage(avatarUrl) as ImageProvider,
                            radius: 60,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateProfileScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 200, 217, 219),
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        "Edit Profile",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),
                  ProfileMenuWidget(
                    title: "Settings",
                    icon: LineAwesomeIcons.cog_solid,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (builder) => Usersetting()));
                    },
                  ),
                  ProfileMenuWidget(
                    title: "Change password",
                    icon: LineAwesomeIcons.lock_solid,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (builder) => PasswordUser()));
                    },
                  ),
                  ProfileMenuWidget(
                    title: "Informations",
                    icon: LineAwesomeIcons.info_solid,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (builder) => InformationUser()));
                    },
                  ),
                  ProfileMenuWidget(
                    title: "Log out",
                    icon: LineAwesomeIcons.sign_out_alt_solid,
                    textColor: Colors.red,
                    endIcon: false,
                    onPressed: () => LogoutHandler.logout(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({
    required this.title,
    required this.icon,
    required this.onPressed,
    this.endIcon = true,
    this.textColor,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPressed,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: const Color.fromARGB(255, 128, 200, 208).withOpacity(0.2),
        ),
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: endIcon
          ? Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color:
                    const Color.fromARGB(255, 128, 200, 208).withValues(alpha: 0.1),
              ),
              child: const Icon(
                LineAwesomeIcons.angle_double_right_solid,
                color: Colors.black,
                size: 18,
              ),
            )
          : null,
    );
  }
}
