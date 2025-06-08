import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/models/message_mode.dart';
import 'package:final_project_flatform/tabs/mail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_project_flatform/models/user_mode.dart' as myModels;
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class EmailsByLabelScreen extends StatefulWidget {
  final String label;

  const EmailsByLabelScreen({Key? key, required this.label}) : super(key: key);

  @override
  State<EmailsByLabelScreen> createState() => _EmailsByLabelScreen();
}

class _EmailsByLabelScreen extends State<EmailsByLabelScreen> {
  final userMail = FirebaseAuth.instance.currentUser?.email;
  List<Message> labelMails = [];
  List<Message> mails = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLabelMails();
  }

  Future<void> choseLabel(BuildContext context, String? threadID) async {
    final userMail = FirebaseAuth.instance.currentUser?.email;
    List<String> allLabels = []; // Danh sách tất cả các nhãn
    List<String> selectedLabels = []; // Danh sách nhãn đã gán cho email

    try {
      // Lấy danh sách tất cả các nhãn từ Firestore
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .collection('labels')
          .get();
      allLabels =
          snapshot.docs.map((doc) => doc['labelName'] as String).toList();

      // Lấy danh sách nhãn đã gán cho email từ Firestore
      var mailDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .collection('mails')
          .doc(threadID)
          .get();

      if (mailDoc.exists) {
        List<dynamic> labelsFromFirestore = mailDoc['labels'] ?? [];
        selectedLabels = List<String>.from(labelsFromFirestore);
      }
    } catch (e) {
      print('Error fetching labels or email data: $e');
      return;
    }

    // Hiển thị hộp thoại để chọn/ chỉnh sửa nhãn
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Assign Labels to Email',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: allLabels.map((label) {
                    return CheckboxListTile(
                      activeColor: Colors.blue,
                      title: Text(label),
                      value: selectedLabels.contains(label),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedLabels.add(label);
                          } else {
                            selectedLabels.remove(label);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Đóng dialog
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // Cập nhật danh sách nhãn mới cho email trong Firestore
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userMail)
                          .collection('mails')
                          .doc(threadID)
                          .update({
                        'labels': selectedLabels, // Cập nhật danh sách nhãn mới
                      });

                      // Lấy lại danh sách mail với nhãn đã thay đổi
                      await fetchLabelMails(); // Cập nhật lại UI sau khi thay đổi nhãn

                      Navigator.of(ctx).pop(); // Đóng dialog sau khi lưu
                    } catch (e) {
                      print('Error updating labels: $e');
                    }
                  },
                  label: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> fetchLabelMails() async {
    try {
      // Truy vấn email có chứa label từ Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .collection('mails')
          .where('labels', arrayContains: widget.label) // Lọc email theo label
          .get();

      // Chuyển dữ liệu từ Firestore thành danh sách Message
      final fetchedMails = snapshot.docs.map((doc) {
        final data = doc.data();
        final colorValue = data['color'].toString() ?? '0xFF000000';
        return Message(
          threadID: doc.id,
          subject: data['subject'] ?? 'No Subject',
          text: data['text'] ?? '',
          sender: myModels.AppUser(
            id: doc.id.hashCode,
            name: data['sender'] ?? 'Unknown',
            imageUrl: Color(int.parse(colorValue)) ?? Colors.grey,
          ),
          time: DateFormat('hh:mm a').format(DateTime.parse(data['time'])),
          isStarred: data['isStarred'] ?? false,
          isSelected: false,
          unread: data['unread'] ?? false,
          reciever: data['receiver'],
          attachments: data['attachments'] ?? ''
        );
      }).toList();

      setState(() {
        labelMails = fetchedMails;
        isLoading = false;
        mails.addAll(fetchedMails);
        print(mails);
      });
    } catch (e) {
      print('Error fetching mails for label ${widget.label}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load mails for label: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleisStarred(Message mail) async {
    if (mail.threadID != null) {
      try {
        mail.isStarred = !mail.isStarred;

        // Cập nhật trạng thái `isStarred` trong Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail)
            .collection('mails')
            .doc(mail.threadID)
            .update({'isStarred': mail.isStarred});

        // Cập nhật UI
        setState(() {});
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
        title: Text('Mails with Label: ${widget.label}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : labelMails.isEmpty
              ? const Center(child: Text('No Mails with this Label'))
              : ListView.builder(
                  itemCount: labelMails.length,
                  itemBuilder: (context, index) {
                    final mail = labelMails[index];
                    return ListTile(
                      leading: SizedBox(
                        width: 120,
                        child: Row(
                          children: [
                            // Checkbox để chọn mail
                            Tooltip(
                              message: 'Select',
                              child: Checkbox(
                                value: mail.isSelected,
                                checkColor: Colors.black,
                                activeColor: Colors.grey,
                                onChanged: (bool? value) {
                                  setState(() {
                                    mail.isSelected = value ?? false;
                                  });
                                },
                              ),
                            ),
                            // Nút ngôi sao để đánh dấu mail
                            Tooltip(
                              message:
                                  mail.isStarred ? "Starred" : "Not starred",
                              child: IconButton(
                                icon: Icon(
                                  mail.isStarred
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: mail.isStarred
                                      ? Colors.yellow
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  toggleisStarred(mail);
                                },
                              ),
                            ),
                            // Avatar của người gửi
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
                        style: TextStyle(
                          fontWeight:
                              mail.unread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(mail.text),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Thời gian mail
                          Text(mail.time),
                          // Nút xóa, hiện khi mail được chọn
                          if (mail.isSelected)
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(LineAwesomeIcons.trash_alt,
                                      color: Colors.red),
                                  onPressed: () {
                                    // Thêm logic xóa mail ở đây
                                  },
                                ),
                                IconButton(
                                  icon: Icon(LineAwesomeIcons.tag_solid),
                                  onPressed: () {
                                    choseLabel(context, mails[index].threadID);
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                      onTap: () {
                        // Điều hướng đến chi tiết mail
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
