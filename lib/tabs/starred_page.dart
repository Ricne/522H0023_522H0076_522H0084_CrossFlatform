import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/models/message_mode.dart';
import 'package:final_project_flatform/tabs/mail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StarredPage extends StatefulWidget {
  final List<Message> starredMails;

  const StarredPage({Key? key, required this.starredMails}) : super(key: key);

  @override
  State<StarredPage> createState() => _StarredPageState();
}

class _StarredPageState extends State<StarredPage> {
  final userMail = FirebaseAuth.instance.currentUser?.email;
  void toggleisStarred(Message mail) async {
    if (mail.threadID != null) {
      try {
        // Đổi trạng thái `isStarred`
        mail.isStarred = !mail.isStarred;

        // Cập nhật trạng thái vào Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail)
            .collection('mails')
            .doc(mail.threadID)
            .update({'isStarred': mail.isStarred});

        // Gọi `setState` để cập nhật UI
        setState(() {
          print("Toggled isStarred: ${mail.isStarred}");
        });
      } catch (e) {
        print("Failed to toggle isStarred: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update isStarred: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Starred Mails'),
      ),
      body: widget.starredMails.isEmpty
          ? const Center(child: Text('No Starred Mails'))
          : ListView.builder(
              itemCount: widget.starredMails.length,
              itemBuilder: (context, index) {
                final mail = widget.starredMails[index];
                return ListTile(
                  leading: SizedBox(
                    width: 138,
                    child: Row(
                      children: [
                        // Checkbox to select the mail
                        Tooltip(
                          message: 'Select',
                          child: Checkbox(
                            value: mail.isSelected,
                            checkColor: Colors.black,
                            activeColor: Colors.grey,
                            onChanged: (bool? value) {
                              // Toggle the isSelected value
                              mail.isSelected = value ?? false;
                            },
                          ),
                        ),
                        // Star button to toggle starred status
                        Tooltip(
                          message: mail.isStarred ? "Starred" : "Not starred",
                          child: IconButton(
                            icon: Icon(
                              mail.isStarred ? Icons.star : Icons.star_border,
                              color:
                                  mail.isStarred ? Colors.yellow : Colors.grey,
                            ),
                            onPressed: () {
                              // Toggle the isStarred value
                              mail.isStarred = !mail.isStarred;
                              // Optionally, save to Firestore here
                              toggleisStarred(mail);
                            },
                          ),
                        ),
                        // Avatar of the sender
                        CircleAvatar(
                          backgroundColor: mail.sender.imageUrl,
                          child: Text(
                            mail.sender.name[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    mail.subject,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1, // Giới hạn số dòng
                    style: TextStyle(
                      fontWeight:
                          mail.unread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    mail.text,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Time of the mail
                      Text(mail.time),
                      // Delete button, shown if mail is selected
                      if (mail.isSelected)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // Call your delete function here
                          },
                        ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to the detailed email view
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Gmail(
                          index: index,
                          user: mail.sender,
                          image: mail.sender.imageUrl,
                          time: mail.time,
                          text: mail.text,
                          subject: mail.subject,
                          isstarred: mail.isStarred,
                          replies: mail.replies,
                          account: mail.reciever,
                          attachments: mail.attachments,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
