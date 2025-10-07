import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/models/message_mode.dart';
import 'package:final_project_flatform/tabs/allMails.dart';
import 'package:final_project_flatform/tabs/draft.dart';
import 'package:final_project_flatform/tabs/emailsbylabelscreen.dart';
import 'package:final_project_flatform/tabs/front_page.dart';
import 'package:final_project_flatform/tabs/sentMails.dart';
import 'package:final_project_flatform/tabs/starred_page.dart';
import 'package:final_project_flatform/tabs/unread.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:final_project_flatform/models/user_mode.dart' as myModels;
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class Drawers extends StatefulWidget {
  //Drawers({required  key}) : super(key: key);
  const Drawers({super.key});
  @override
  _DrawersState createState() => _DrawersState();
}

class _DrawersState extends State<Drawers> {
  bool isExpanded = false;
  final _newLabelNameController = TextEditingController();
  final userMail = FirebaseAuth.instance.currentUser?.email;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  List<String> _labels = [];
  String nameAccount = 'User';

  @override
  void initState() {
    super.initState();
    _fetchLabels();
    getName();
  }

  Future<void> getName() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userMail)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        nameAccount = snapshot.data()?['fullName'] ?? 'User';
      }
    });
  }

  Future<List<Message>> fetchStarredMails(String? userMail) async {
    List<Message> starredMails = [];
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .collection('mails')
          .where('isStarred', isEqualTo: true)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        starredMails.add(
          Message(
              threadID: doc.id,
              sender: myModels.AppUser(
                id: starredMails.length,
                name: data['sender'] ?? 'Unknown',
                imageUrl:
                    Color(int.parse(data['color'].toString() ?? '0xFF000000')),
              ),
              reciever: data['receiver'] ?? 'No Receiver',
              subject: data['subject'] ?? 'No Subject',
              text: data['text'] ?? 'No Content',
              time: DateFormat('hh:mm a').format(
                  DateTime.parse(data['time'] ?? DateTime.now().toString())),
              unread: data['unread'] ?? true,
              isStarred: data['isStarred'] ?? false,
              attachments: data['attachments'] ?? ''),
        );
      }
    } catch (e) {
      print("Failed to fetch starred mails: $e");
    }
    return starredMails;
  }

  // Hàm lấy danh sách label từ Firestore
  Future<void> _fetchLabels() async {
    final userMail = FirebaseAuth.instance.currentUser?.email;
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .collection('labels')
          .get();

      setState(() {
        _labels =
            snapshot.docs.map((doc) => doc['labelName'] as String).toList();
      });
    } catch (e) {
      print('Error fetching labels: $e');
    }
  }

  Future<void> _addLabel() async {
    if (_newLabelNameController.text.isNotEmpty) {
      String labelName = _newLabelNameController.text;
      final userMail = FirebaseAuth.instance.currentUser?.email;

      try {
        // Lưu label vào Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail)
            .collection('labels')
            .add({'labelName': labelName});
        await _fetchLabels();
        setState(() {
          _newLabelNameController.clear();
        });
        Navigator.of(context).pop(); // Đóng dialog
      } catch (e) {
        print('Error adding label: $e');
      }
    }
  }

  Future<void> _assignLabelToMail(
      String threadID, List<String> labelIds) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail) // Lấy email người dùng
          .collection('mails')
          .doc(threadID) // Lấy mail
          .update({
        'labels': labelIds, // Cập nhật danh sách label vào mail
      });
    } catch (e) {
      print('Error assigning label to mail: $e');
    }
  }

  Future<void> updateLabelFirestore(String oldLabel, String newLabel) async {
    final userMail = FirebaseAuth.instance.currentUser?.email;

    try {
      // Tìm nhãn cũ trong bộ sưu tập "labels"
      var labelDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .collection('labels')
          .where('labelName', isEqualTo: oldLabel)
          .get();

      // Nếu nhãn tồn tại, cập nhật tên nhãn
      if (labelDoc.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail)
            .collection('labels')
            .doc(labelDoc.docs.first.id)
            .update({'labelName': newLabel});
      }

      // Cập nhật nhãn trong tất cả email
      var emailSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .collection('mails')
          .where('labels', arrayContains: oldLabel)
          .get();

      for (var emailDoc in emailSnapshot.docs) {
        List<String> labels = List<String>.from(emailDoc['labels'] ?? []);
        // Thay đổi tên nhãn cũ thành nhãn mới trong danh sách
        List<String> updatedLabels = labels.map((label) {
          return label == oldLabel ? newLabel : label;
        }).toList();

        // Cập nhật lại danh sách nhãn trong email
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail)
            .collection('mails')
            .doc(emailDoc.id)
            .update({'labels': updatedLabels});
      }

      print('Successfully updated label from $oldLabel to $newLabel');
    } catch (e) {
      print('Error updating label: $e');
      throw e; // Ném lỗi để hàm gọi có thể xử lý
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 0, 10),
            width: MediaQuery.of(context).size.width * 0.45,
            child: Text(
              'Hello, $nameAccount!',
              style: TextStyle(
                color: Colors.red,
                //fontFamily: 'LexendMega',
                fontFamily: 'Roboto',
                fontSize: 22.0,
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.image_outlined),
            title: Text('Inbox'),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (ctx) => FrontPage())),
          ),
          ListTile(
            leading: Icon(Icons.star_border),
            title: Text('Starred'),
            onTap: () async {
              List<Message> starredMails = await fetchStarredMails(userMail);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => StarredPage(starredMails: starredMails),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Unread'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        Unread()), // Điều hướng đến trang Unread
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.send_outlined),
            title: Text('Sent'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Sent()), // Điều hướng đến trang Sent
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.mail_outline),
            title: Text('All Mail'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AllMails()), // Điều hướng đến trang Unread
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.insert_drive_file_outlined),
            title: Text('Drafts'),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (ctx) => Draft())),
          ),
          ListTile(
            trailing: Icon(Icons.add),
            title: Text(
              'Labels',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: Text('New label'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _newLabelNameController,
                            decoration: InputDecoration(
                              hintText: 'Please enter a new label name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: _addLabel,
                          child: Text('Create'),
                        ),
                      ],
                    );
                  });
            },
          ),
          ..._labels.map((label) {
            return ListTile(
              leading: Icon(Icons.label),
              title: Text(label),
              trailing: IconButton(
                icon: Icon(LineAwesomeIcons.grip_vertical_solid,
                    color: Colors.grey),
                tooltip: 'Edit Label',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      String newLabel = label; // Biến lưu trữ tên nhãn mới
                      TextEditingController controller =
                          TextEditingController(text: label);

                      return AlertDialog(
                        title: Text('Edit Label'),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(labelText: 'Label Name'),
                          onChanged: (value) {
                            newLabel = value;
                          },
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final userMail =
                                  FirebaseAuth.instance.currentUser?.email;

                              if (newLabel != label) {
                                // Kiểm tra nếu tên nhãn thay đổi
                                try {
                                  // Cập nhật nhãn trong Firestore
                                  await updateLabelFirestore(label, newLabel);

                                  // Đóng hộp thoại
                                  Navigator.of(ctx).pop();

                                  // Làm mới danh sách nhãn trên UI
                                  setState(() {
                                    _labels = _labels
                                        .map((lbl) =>
                                            lbl == label ? newLabel : lbl)
                                        .toList();
                                  });

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text('Label updated successfully'),
                                  ));
                                } catch (e) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text('Failed to update label: $e'),
                                  ));
                                }
                              } else {
                                // Nếu tên nhãn không thay đổi
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('Label name is the same.'),
                                ));
                                Navigator.of(ctx).pop();
                              }
                            },
                            child: Text('Save'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final userMail =
                                  FirebaseAuth.instance.currentUser?.email;
                              try {
                                // Xóa nhãn khỏi Firestore
                                var labelDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userMail)
                                    .collection('labels')
                                    .where('labelName', isEqualTo: label)
                                    .get();

                                if (labelDoc.docs.isNotEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userMail)
                                      .collection('labels')
                                      .doc(labelDoc.docs.first.id)
                                      .delete();
                                }

                                Navigator.of(ctx).pop();

                                // Làm mới danh sách nhãn
                                setState(() {
                                  _labels.remove(label);
                                });

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('Label deleted successfully'),
                                ));
                              } catch (e) {
                                print('Error deleting label: $e');
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('Failed to delete label: $e'),
                                ));
                              }
                            },
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              onTap: () async {
                print('Label $label clicked');
                final userMail = FirebaseAuth.instance.currentUser?.email;

                try {
                  // Truy vấn Firestore để lấy danh sách email có gán label
                  var snapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userMail)
                      .collection('mails')
                      .where('labels', arrayContains: label)
                      .get();

                  // Lấy danh sách email
                  List<String> emails = snapshot.docs.map((doc) {
                    return (doc['subject'] ?? 'No Subject') as String;
                  }).toList();

                  // In danh sách email ra console
                  print('Emails with label $label: $emails');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmailsByLabelScreen(label: label),
                    ),
                  );
                } catch (e) {
                  print('Error fetching emails for label $label: $e');
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
