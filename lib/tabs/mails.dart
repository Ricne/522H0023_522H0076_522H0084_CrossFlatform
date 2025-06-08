import 'dart:async';
import 'dart:convert';

import 'package:final_project_flatform/models/reply_mode.dart';
import 'package:final_project_flatform/models/user_mode.dart' as myModels;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/pages/logout.dart';
import 'package:final_project_flatform/tabs/advanced_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_project_flatform/models/message_mode.dart';
import 'package:final_project_flatform/tabs/mail_page.dart';
import 'package:final_project_flatform/tabs/compose.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'dart:math';
import 'drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:final_project_flatform/tabs/profile.dart';

class Mails extends StatefulWidget {
  const Mails({super.key});

  @override
  _MailsState createState() => _MailsState();
}

class Datasearch extends SearchDelegate<String> {
  final String userMail;

  Datasearch({required this.userMail});

  Future<List<Message>> searchEmails(String query) async {
    // Truy vấn trong collection "inbox"
    final inboxQuerySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userMail)
        .collection('mails')
        .get();

    final sentQuerySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userMail)
        .collection('sentMails')
        .get();

    // Kết hợp kết quả từ cả hai collections
    final combinedDocs = [
      ...inboxQuerySnapshot.docs,
      ...sentQuerySnapshot.docs
    ];

    final results = combinedDocs.where((doc) {
      final data = doc.data();
      final subject = data['subject'] ?? '';
      final text = data['text'] ?? '';
      final receiver = data['reciever'] ?? '';
      final senderName = data['senderName'] ?? '';

      // Kiểm tra xem bất kỳ trường nào có chứa query
      return subject.toLowerCase().contains(query.toLowerCase()) ||
          text.toLowerCase().contains(query.toLowerCase()) ||
          receiver.toLowerCase().contains(query.toLowerCase()) ||
          senderName.toLowerCase().contains(query.toLowerCase());
    }).map((doc) {
      final data = doc.data();
      return Message(
        sender: myModels.AppUser(
          id: doc.id.hashCode,
          name: data['sender'] ?? 'Unknown',
          imageUrl: Color(data['color'] ?? '0xFF000000'),
        ),
        reciever: data['reciever'] ?? 'No Reciever',
        subject: data['subject'] ?? 'No Subject',
        text: data['text'] ?? 'No Content',
        time: DateFormat('hh:mm a').format(DateTime.parse(data['time'])),
        unread: data['unread'] ?? true,
        isStarred: data['isStarred'] ?? false,
        attachments: data['attachments'] ?? '',
      );
    }).toList();

    return results;
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = ''; // Clear the search query
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, ''); // Close the search delegate
      },
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Message>>(
      future: searchEmails(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final searchResults = snapshot.data ?? [];
        if (searchResults.isEmpty) {
          return Center(child: Text('No results found.'));
        }

        return ListView.builder(
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final mail = searchResults[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: mail.sender.imageUrl,
                child: Text(
                  mail.sender.name[0], // First letter of the sender's name
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(mail.subject),
              subtitle: Text(mail.text),
              trailing: Text(mail.time),
              onTap: () {
                // Handle email tap action to show full email details
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
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestList = query.isEmpty ? [] : [query];
    return ListView.builder(
      itemCount: suggestList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestList[index]),
          onTap: () {
            query =
                suggestList[index]; // Set the query to the selected suggestion
            showResults(context);
          },
        );
      },
    );
  }
}

class TextBox extends StatelessWidget {
  const TextBox({super.key});

  @override
  Widget build(BuildContext context) {
    final userMail = FirebaseAuth.instance.currentUser?.email;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .scaffoldBackgroundColor, // Màu nền thay đổi theo theme
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        cursorHeight: 25,
        decoration: InputDecoration(
            hintText: 'Search in email',
            hintStyle: TextStyle(
              color: Theme.of(context).hintColor, // Màu chữ gợi ý theo theme
            ),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(LineAwesomeIcons.filter_solid),
              onPressed: () async {
                await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => AdvancedSearch(),
                );
              },
            )),
        onTap: () {
          if (userMail != null) {
            showSearch(
              context: context,
              delegate: Datasearch(
                  userMail: userMail), // Pass userMail to the search delegate
            );
          }
        },
      ),
    );
  }
}

class _MailsState extends State<Mails> {
  StreamSubscription? mailSubscription;
  List<String> selectedMessageIDs = [];
  bool? isStarred = false;
  List<Message> mails = [];
  final userMail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    handleScroll();
    loadMailsFromFirebase();
  }

  void loadMailsFromFirebase() {
    if (userMail != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .collection('mails')
          .orderBy('time', descending: true)
          .snapshots()
          .listen((snapshot) {
        final List<Message> updatedMails = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['receiver'] == userMail) {
            final colorValue = data['color'].toString() ?? '0xFF000000';

            // Lấy danh sách replies nếu có
            List<Reply> replyList = [];
            if (data['replies'] != null) {
              for (var reply in data['replies']) {
                replyList.add(
                  Reply(
                      body: reply['body'] ?? 'No Content',
                      from: reply['from'] ?? 'Unknown Sender',
                      subject: reply['subject'] ?? 'No Subject',
                      time: reply['time'] ?? '',
                      to: reply['to'] ?? 'Unknown Receiver',
                      attachments: reply['attachments'] ?? ''),
                );
              }
            }

            // Kiểm tra và xử lý dữ liệu đính kèm
            String attachments = data['attachments'] ?? '';
            //List<String> attachmentUrls = attachments.split(',');
            final loadedMail = Message(
              sender: myModels.AppUser(
                id: updatedMails.length,
                name: data['sender'] ?? 'Unknown',
                imageUrl: Color(int.parse(colorValue)),
              ),
              reciever: data['receiver'] ?? 'No Receiver',
              subject: data['subject'] ?? 'No Subject',
              text: data['text'] ?? 'No Content',
              time: DateFormat('hh:mm a').format(DateTime.parse(data['time'])),
              unread: data['unread'] ?? true,
              isStarred: data['isStarred'] ?? false,
              replies: replyList,
              attachments: attachments,
              threadID: doc.id,
            );
            updatedMails.add(loadedMail);
          }
        }

        setState(() {
          mails = updatedMails; // Cập nhật danh sách mail trong UI
        });
      });
    } else {
      print('UserMail is null');
    }
  }

  @override
  void dispose() {
    mailSubscription?.cancel(); // Hủy listener
    super.dispose();
  }

  Future<bool> checkIfUserExists(String email) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(email).get();

    return userDoc.exists;
  }

  Future<void> navigateToCompose() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Compose(
                isReply: false,
                isDraft: false,
              )),
    );

    if (result != null) {
      // Lấy thông tin người gửi
      final userName = FirebaseAuth.instance.currentUser?.email ?? 'Anonymous';
      final currentTime = DateTime.now();

      // Dữ liệu tệp đính kèm (có thể là danh sách các URL)
      final attachmentUrls =
          result['attachments'] ?? ''; // Mảng các URL tệp đính kèm
      print(attachmentUrls);

      final newMessage = Message(
        sender: myModels.AppUser(
          id: mails.length,
          name: userName,
          imageUrl: getRandomColor(),
        ),
        reciever: result['to'] ?? '',
        subject: result['subject'] ?? '',
        text: result['body'] ?? '',
        time: DateFormat('hh:mm a').format(currentTime),
        unread: true,
        isStarred: false,
        attachments: attachmentUrls,
      );
      setState(() {
        mails.add(newMessage);
      });

      // Tạo một messageID duy nhất
      final messageID = FirebaseFirestore.instance.collection('mails').doc().id;

      // Lưu mail vào collection 'mails' của cả người gửi và người nhận
      final senderMail = FirebaseAuth.instance.currentUser?.email ?? '';
      final receiverMail = newMessage.reciever.trim();

      // Lưu mail vào người gửi
      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderMail) // ID người gửi
          .collection('mails')
          .doc(messageID) // Sử dụng messageID duy nhất
          .set({
        'messageID': messageID,
        'sender': newMessage.sender.name,
        'receiver': newMessage.reciever,
        'subject': newMessage.subject,
        'text': newMessage.text,
        'time': currentTime.toIso8601String(),
        'isStarred': newMessage.isStarred,
        'unread': newMessage.unread,
        'color': getRandomColor().value,
        'replies': [], // Khởi tạo replies rỗng
        'labels': [],
        'attachments': newMessage.attachments,
      });

      // Lưu mail vào người nhận (nếu người nhận tồn tại)
      final userExists = await checkIfUserExists(receiverMail);

      if (userExists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverMail) // ID người nhận
            .collection('mails')
            .doc(messageID) // Sử dụng messageID duy nhất
            .set({
          'messageID': messageID,
          'sender': newMessage.sender.name,
          'receiver': newMessage.reciever,
          'subject': newMessage.subject,
          'text': newMessage.text,
          'time': currentTime.toIso8601String(),
          'isStarred': newMessage.isStarred,
          'unread': newMessage.unread,
          'color': getRandomColor().value,
          'replies': [], // Khởi tạo replies rỗng
          'labels': [],
          'attachments': newMessage.attachments,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mail account does not exist!')),
        );
      }
    }
  }

  Color getRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  bool isShow = true;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();

  void handleScroll() {
    _scrollController.addListener(() {
      // Lấy hướng cuộn hiện tại
      final direction = _scrollController.position.userScrollDirection;

      // Kiểm tra và chỉ gọi setState nếu trạng thái isShow thay đổi
      if (direction == ScrollDirection.reverse && isShow) {
        setState(() {
          isShow = false;
        });
      } else if (direction == ScrollDirection.forward && !isShow) {
        setState(() {
          isShow = true;
        });
      }
    });
  }

  Future<void> markAsRead(String messageId) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Anonymous';

    // Kiểm tra trạng thái 'unread' trước khi cập nhật
    final mailRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('mails')
        .doc(messageId);

    // Lấy dữ liệu của mail trước khi cập nhật
    final docSnapshot = await mailRef.get();
    final data = docSnapshot.data();
    final currentUnreadStatus = data?['unread'] ?? true;

    // Chỉ thay đổi 'unread' khi nó đang là true (chưa đọc)
    if (currentUnreadStatus) {
      await mailRef.update({'unread': false});

      // Cập nhật lại UI để email được đánh dấu là đã đọc
      setState(() {
        final index = mails.indexWhere((mail) => mail.threadID == messageId);
        if (index != -1) {
          mails[index].unread = false;
        }
      });
    }
  }

  Future<void> toggleReadStatus(
      String messageId, bool currentUnreadStatus) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Anonymous';

    // Kiểm tra và cập nhật trạng thái 'unread'
    final mailRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('mails')
        .doc(messageId);

    // Lấy dữ liệu hiện tại của email để kiểm tra trạng thái 'unread'
    final docSnapshot = await mailRef.get();
    final data = docSnapshot.data();
    final isAlreadyRead = data?['unread'] ?? true;

    // Chỉ cập nhật trạng thái 'unread' nếu email chưa được đọc
    if (isAlreadyRead) {
      // Cập nhật trạng thái 'unread' trong Firestore (đánh dấu là đã đọc)
      await mailRef.update({'unread': false});

      // Cập nhật lại UI khi trạng thái 'unread' thay đổi
      setState(() {
        final index = mails.indexWhere((mail) => mail.threadID == messageId);
        if (index != -1) {
          mails[index].unread = false; // Đánh dấu là đã đọc trong UI
        }
      });
    }
  }

  Future<void> deleteMailFromFirestore(String? threadID) async {
    if (threadID != null) {
      try {
        // Lấy tài liệu mail cần xóa từ Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail) // Dùng email người dùng làm ID
            .collection('mails') // Truy vấn tới collection 'mails'
            .doc(threadID) // Chỉ định ID của mail cần xóa
            .delete(); // Xóa tài liệu

        print('Mail with threadID $threadID has been deleted from Firestore');

        // Cập nhật lại giao diện người dùng sau khi xóa
        setState(() {
          mails.removeWhere((mail) => mail.threadID == threadID);
        });
      } catch (e) {
        print('Error deleting mail: $e');
      }
    } else {
      print("threadID is null");
    }
  }

  Future<void> loadisStarredStatus(String? threadID) async {
    if (threadID != null) {
      try {
        DocumentSnapshot mailDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail)
            .collection('mails')
            .doc(threadID)
            .get();

        if (mailDoc.exists) {
          setState(() {
            isStarred = mailDoc['isStarred'] ?? false;
            print("Updated isStarred: $isStarred");
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load isStarred status: $e")),
        );
      }
    }
  }

  Future<void> saveisStarredStatus(bool status, String threadID) async {
    try {
      // Lưu vào Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .collection('mails')
          .doc(threadID)
          .update(
        {
          'isStarred': isStarred!,
        },
      );
      print(
          "Saved isStarred: $isStarred"); // Merge với dữ liệu hiện có (nếu có)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save isStarred status: $e")),
      );
    }
  }

  void toggleisStarred(Message mail, int index) async {
    if (mail.threadID != null) {
      mail.isStarred = !mail.isStarred;

      // Cập nhật Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .collection('mails')
          .doc(mail.threadID)
          .update({'isStarred': mail.isStarred});

      // Cập nhật danh sách và UI
      setState(() {
        mails[index] = mail; // Cập nhật danh sách
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawers(),
      key: _globalKey,
      body: Padding(
        padding: EdgeInsets.only(top: 35),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(15, 0, 15, 5),
              sliver: SliverAppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                toolbarHeight: 55,
                primary: false,
                iconTheme: Theme.of(context).iconTheme,
                title: TextBox(),
                elevation: 2,
                floating: true,
                shape: ContinuousRectangleBorder(
                  side: BorderSide(width: 1, color: Colors.grey),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                    topRight: Radius.circular(22),
                    topLeft: Radius.circular(22),
                  ),
                ),
                actions: <Widget>[
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userMail)
                        .snapshots(), // Lắng nghe thay đổi real-time
builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircularProgressIndicator(strokeWidth: 2.0),
    );
  } else if (snapshot.hasError) {
    return Icon(Icons.error, color: Colors.red, size: 40);
  } else if (!snapshot.hasData || snapshot.data!.data() == null) {
    // Document chưa có hoặc data null
    return CircleAvatar(
      backgroundImage: AssetImage('assets/user.png'),
      radius: 20,
    );
  }

  final data = snapshot.data!.data() as Map<String, dynamic>;
  final avatarUrl = data['avatarUrl'] ?? 'assets/user.png';

  return PopupMenuButton<String>(
    icon: CircleAvatar(
      backgroundImage: avatarUrl.startsWith('http')
          ? NetworkImage(avatarUrl)
          : AssetImage(avatarUrl) as ImageProvider,
      radius: 20,
    ),
    itemBuilder: (BuildContext context) => [
      PopupMenuItem<String>(
        value: 'profile',
        child: Row(
          children: [
            Icon(Icons.person, color: Theme.of(context).iconTheme.color),
            SizedBox(width: 10),
            Text('Profile'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Logout'),
          ],
        ),
      ),
    ],
    onSelected: (String value) {
      if (value == 'logout') {
        LogoutHandler.logout(context);
      } else if (value == 'profile') {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => ProfileScreen()));
      }
    },
  );
},
                  ),
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  if (index == 0) {
                    return Padding(
                      padding: EdgeInsets.only(left: 15, top: 10, bottom: 5),
                      child: Text(
                        'Inbox',
                        style: TextStyle(
                            color: Theme.of(context).iconTheme.color,
                            fontSize: 13),
                      ),
                    );
                  }

                  final mailIndex = index - 1;
                  if (mailIndex < 0 || mailIndex >= mails.length) {
                    return const SizedBox.shrink(); // Không hiển thị gì nếu lỗi
                  }

                  return Builder(builder: (context) {
                    return Dismissible(
                      key: UniqueKey(),
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.archive_outlined,
                            color: Colors.white, size: 30),
                      ),
                      secondaryBackground: Container(
                        color: Colors.green,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.archive_outlined,
                            color: Colors.white, size: 30),
                      ),
                      onDismissed: (direction) async {
                        setState(() {
                          mails.removeAt(index - 1);
                        });
                      },
                      child: Container(
                        color: mails[index - 1].unread
                            ? Colors.grey.withOpacity(0.1)
                            : Colors.transparent,
                        child: ListTile(
                            leading: SizedBox(
                              width: 138,
                              child: Row(
                                children: [
                                  Tooltip(
                                    message: 'Select',
                                    child: Checkbox(
                                      value: mails[index - 1].isSelected,
                                      checkColor: Colors.black,
                                      activeColor: Colors.grey,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          mails[index - 1].isSelected =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  Tooltip(
                                    message: mails[index - 1].isStarred
                                        ? "Starred"
                                        : "Not starred",
                                    child: IconButton(
                                      icon: Icon(
                                        mails[index - 1].isStarred
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: mails[index - 1].isStarred
                                            ? Colors.yellow
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        toggleisStarred(
                                            mails[index - 1], index - 1);
                                      },
                                    ),
                                  ),
                                  CircleAvatar(
                                    backgroundColor:
                                        mails[index - 1].sender.imageUrl,
                                    child: Text(
                                      mails[index - 1].sender.name[0],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            title: Text(
                              mails[index - 1].subject,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1, // Giới hạn số dòng
                              style: TextStyle(
                                fontWeight: mails[index - 1].unread
                                    ? FontWeight.bold
                                    : FontWeight
                                        .bold, // Đậm cho cả đã đọc và chưa đọc
                                color: mails[index - 1].unread
                                    ? Colors.black
                                    : Colors.black, // Màu chữ không thay đổi
                              ),
                            ),
                            subtitle: Text(
                              mails[index - 1].text,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mails[index - 1].time,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (mails[index - 1].isSelected)
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(LineAwesomeIcons.trash_alt,
                                            color: Colors.red),
                                        onPressed: () {
                                          deleteMailFromFirestore(
                                              mails[index - 1].threadID!);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(LineAwesomeIcons.tag_solid),
                                        onPressed: () {
                                          choseLabel(context,
                                              mails[index - 1].threadID!);
                                        },
                                      )
                                    ],
                                  ),
                              ],
                            ),
                            onTap: () async {
                              await toggleReadStatus(mails[index - 1].threadID!,
                                  mails[index - 1].unread);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Gmail(
                                    index: index,
                                    user: mails[index - 1].sender,
                                    image: mails[index - 1].sender.imageUrl,
                                    time: mails[index - 1].time,
                                    text: mails[index - 1].text,
                                    subject: mails[index - 1].subject,
                                    isstarred: mails[index - 1].isStarred,
                                    replies: mails[index - 1].replies,
                                    account: mails[index - 1].reciever,
                                    attachments: mails[index - 1]
                                        .attachments, // Thêm thông tin tệp đính kèm
                                  ),
                                ),
                              );
                            }),
                      ),
                    );
                  });
                },
                childCount: mails.length + 1,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isShow
          ? FloatingActionButton.extended(
              onPressed: navigateToCompose,
              label: const Text('Compose'),
              icon: const Icon(Icons.edit),
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
            )
          : null,
    );
  }

  Color generateRandomColor() {
    Random rd = Random();
    return Color.fromARGB(
        255, rd.nextInt(256), rd.nextInt(256), rd.nextInt(256));
  }
}
