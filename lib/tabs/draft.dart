import 'dart:math';
import 'package:final_project_flatform/models/user_mode.dart' as myModels;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/pages/logout.dart';
import 'package:final_project_flatform/tabs/advanced_search.dart';
import 'package:final_project_flatform/tabs/compose.dart';
import 'package:final_project_flatform/tabs/drawer.dart';
import 'package:final_project_flatform/tabs/mail_page.dart';
import 'package:final_project_flatform/tabs/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:final_project_flatform/models/message_mode.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class Draft extends StatefulWidget {
  @override
  _SentState createState() => _SentState();
}

class Datasearch extends SearchDelegate<String> {
  final String userMail;

  Datasearch({required this.userMail});

  Future<List<Message>> searchEmails(String query) async {
    // Truy vấn trong collection "inbox"
    final inboxQuerySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userMail)
        .collection('drafts')
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
            name: data['senderName'] ?? 'Unknown',
            imageUrl: Color(data['color'] ?? '0xFF000000'),
          ),
          reciever: data['reciever'] ?? 'No Reciever',
          subject: data['subject'] ?? 'No Subject',
          text: data['text'] ?? 'No Content',
          time: DateFormat('hh:mm a').format(DateTime.parse(data['time'])),
          unread: data['unread'] ?? true,
          isStarred: data['isStarred'] ?? false,
          attachments: data['attachments'] ?? '');
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

class _SentState extends State<Draft> {
  List<Message> mails = [];
  List<String> messageID = [];
  final userMail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    handleScroll();
    loadDraftsFromFirebase();
  }

  Future<String> getUserAvatarUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMail)
          .get();
      return doc.data()?['avatarUrl'] ??
          'assets/user.png'; // URL avatar từ Firestore hoặc hình mặc định
    }
    return 'assets/user.png'; // Trường hợp không có thông tin user
  }

  Future<void> loadDraftsFromFirebase() async {
    if (userMail != null) {
      try {
        // Lấy tất cả các document trong collection 'drafts' của người dùng
        final queryDrafts = await FirebaseFirestore.instance
            .collection('users') // Truy vấn từ collection 'users'
            .doc(userMail) // Dùng email của người dùng làm ID
            .collection(
                'drafts') // Truy vấn tới collection 'drafts' của người dùng
            .orderBy('time',
                descending: true) // Sắp xếp theo thời gian tạo nháp
            .get(); // Lấy tất cả document

        // Lặp qua từng document và lưu Document ID vào mảng messageID
        for (var doc in queryDrafts.docs) {
          // Thêm Document ID vào mảng messageID
          messageID.add(doc.id);
          print('Draft Document ID: ${doc.id} added to messageID list');

          // Lấy thông tin dữ liệu từ document
          final data = doc.data();
          print(data);

          final colorValue = data['color'] != null
              ? int.parse(data['color'].toString())
              : getRandomColor().value; // Nếu không có màu, sử dụng mặc định

          // Tạo đối tượng Message với thông tin người gửi và người nhận
          final loadedMail = Message(
              sender: myModels.AppUser(
                id: mails.length,
                name: data['from'] ?? 'Unknown',
                imageUrl: Color(colorValue),
              ),
              reciever: data['to'] ?? 'No Reciever',
              subject: data['subject'] ?? 'No Subject',
              text: data['body'] ?? 'No Content', // Đảm bảo có giá trị mặc định
              time: DateFormat('hh:mm a').format(DateTime.parse(data['time'])),
              unread: data['unread'] ?? true,
              isStarred: data['isStarred'] ?? false,
              attachments: data['attachments'] ?? '',
              threadID: doc.id);

          // Cập nhật danh sách thư nháp trong UI
          setState(() {
            mails.add(loadedMail);
          });
        }
      } catch (e) {
        print('Error loading drafts: $e');
      }
    } else {
      print('UserID is null');
    }
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
                isDraft: true,
              )),
    );

    if (result != null && result is Map<String, String>) {
      print(result);

      // Lấy thông tin người gửi
      final userName = FirebaseAuth.instance.currentUser?.email ?? 'Anonymous';
      final currentTime = DateTime.now();

      final attachmentUrls =
          result['attachments'] ?? ''; // Mảng các URL tệp đính kèm

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
          attachments: attachmentUrls);

      setState(() {
        mails.add(newMessage);
      });

      // Tạo một messageID duy nhất
      final messageID = FirebaseFirestore.instance.collection('mails').doc().id;
      print(messageID);

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

  void handleScroll() async {
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        setState(() {
          isShow = false;
        });
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        setState(() {
          isShow = true;
        });
      }
    });
  }

  Future<void> deleteMailFromFirestore(String? threadID) async {
    if (threadID != null) {
      try {
        // Lấy tài liệu mail cần xóa từ Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userMail) // Dùng email người dùng làm ID
            .collection('drafts') // Truy vấn tới collection 'mails'
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

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                  FutureBuilder<String>(
                    future: getUserAvatarUrl(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        );
                      } else if (snapshot.hasError) {
                        return Icon(Icons.error,
                            color: Colors.red, size: 40); // Error state
                      }

                      final avatarUrl = snapshot.data ?? 'assets/user.png';
                      print(avatarUrl);
                      return PopupMenuButton<String>(
                        icon: CircleAvatar(
                          backgroundImage: avatarUrl.startsWith('http')
                              ? CachedNetworkImageProvider(avatarUrl, scale: 1)
                              : AssetImage(avatarUrl) as ImageProvider,
                          radius: 20,
                        ),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person,
                                    color: Theme.of(context).iconTheme.color),
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
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ProfileScreen()));
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
                        'Draft',
                        style: TextStyle(
                            color: Theme.of(context).iconTheme.color,
                            fontSize: 13),
                      ),
                    );
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
                      onDismissed: (direction) {
                        setState(() {
                          mails.removeAt(index - 1);
                        });
                      },
                      child: Container(
                        color: mails[index - 1].isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.transparent, // Change color if selected
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
                                      setState(() {
                                        mails[index - 1].isStarred =
                                            !mails[index - 1].isStarred;
                                      });
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
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: mails[index - 1].unread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
                              Text(mails[index - 1].time),
                              if (mails[index - 1].isSelected)
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    deleteMailFromFirestore(
                                        mails[index - 1].threadID!);
                                  },
                                ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Compose(
                                initialFrom: mails[index - 1].sender.toString(),
                                initialTo: mails[index - 1].reciever,
                                initialSubject: mails[index - 1].subject,
                                initialBody: mails[index - 1].text,
                                isReply: false,
                                isDraft: true,
                                draftId: messageID[index - 1],
                              ),
                            ),
                          ),
                        ),
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
}
