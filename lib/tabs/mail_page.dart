import 'package:final_project_flatform/models/reply_mode.dart';
import 'package:final_project_flatform/tabs/compose.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_project_flatform/models/user_mode.dart';
import 'package:url_launcher/url_launcher.dart';

class Gmail extends StatefulWidget {
  final int index;
  final AppUser user;
  final Color image;
  final String time;
  final String text;
  final String subject;
  bool isstarred;
  final List<Reply> replies; // Thêm đối tượng replies
  final String account;
  final String attachments; // Thêm thuộc tính attachments

  Gmail({
    required this.index,
    required this.user,
    required this.image,
    required this.time,
    required this.text,
    required this.subject,
    required this.isstarred,
    required this.replies, // Nhận replies từ mail gốc
    required this.account,
    required this.attachments, // Nhận tệp đính kèm
  });

  @override
  _GmailState createState() => _GmailState();
}

class _GmailState extends State<Gmail> {
  bool _hasBeenPressed = false;
  late bool isStarred;
  final userName = FirebaseAuth.instance.currentUser?.email;

  bool _isMailSentMail() {
    return userName == widget.user.name;
  }

  Reply _getLatestReply() {
    if (widget.replies.isNotEmpty) {
      return widget.replies.last; // Mail phản hồi gần nhất
    } else {
      return Reply(
          from: widget.user.name,
          to: widget.account,
          subject: widget.subject,
          body: widget.text,
          time: widget.time,
          attachments: widget.attachments); // Mail gốc
    }
  }

  void _openAttachment(String url) async {
    final Uri uri = Uri.parse(url); // Chuyển đổi URL thành Uri
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url'; // Lỗi nếu không thể mở URL
    }
  }

  @override
  Widget build(BuildContext context) {
    print(widget.replies);
    return Scaffold(
      appBar: AppBar(
        title: Text("Mail Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subject,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.image,
                  child: Text(
                    widget.user.name[0],
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _isMailSentMail() ? "me" : widget.user.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(widget.time),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _isMailSentMail() ? "to ${widget.account}" : "to me",
                          style: TextStyle(
                              color: Theme.of(context).iconTheme.color,
                              fontSize: 14.0),
                        ),
                        Icon(Icons.expand_more),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hiển thị nội dung mail gốc
                    Text(
                      widget.text,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    if (widget.attachments.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attachments:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          ...widget.attachments.split(',').map((url) {
                            String fileName = Uri.parse(url)
                                .pathSegments
                                .last
                                .split('/')
                                .last;
                            fileName = Uri.decodeFull(fileName);
                            print('File Name: $fileName');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: Icon(Icons.attach_file),
                                title: Text(
                                  fileName,
                                  style: TextStyle(fontSize: 14),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.open_in_new),
                                  onPressed: () {
                                    // Mở file bằng trình duyệt hoặc ứng dụng hỗ trợ
                                    _openAttachment(url);
                                    print("Attachment URL: $url");
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),

                    // Kiểm tra và hiển thị các mail phản hồi nếu có
                    if (widget.replies.isNotEmpty)
                      ...widget.replies.map((reply) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(),
                              Text(
                                'Replied by: ${reply.from}',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Subject: ${reply.subject}',
                                style: TextStyle(
                                    fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                              Text(
                                'To: ${reply.to}',
                                style: TextStyle(
                                    fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                              Text(
                                'Time: ${reply.time}',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                reply.body,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 12),
                              if (reply.attachments.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attachments:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    ...reply.attachments.split(',').map((url) {
                                      String fileName = Uri.parse(url)
                                          .pathSegments
                                          .last
                                          .split('/')
                                          .last;
                                      fileName = Uri.decodeFull(fileName);
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: ListTile(
                                          leading: Icon(Icons.attach_file),
                                          title: Text(
                                            fileName,
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(Icons.open_in_new),
                                            onPressed: () {
                                              // Mở file bằng trình duyệt hoặc ứng dụng hỗ trợ
                                              _openAttachment(url);
                                              print("Attachment URL: $url");
                                            },
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              SizedBox(height: 20),
                            ],
                          ),
                        );
                      }).toList(),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Compose(
                          initialTo: widget.user.name,
                          initialSubject: widget.subject,
                          userMail: widget.user.name,
                          userMailRe: widget.account,
                          isReply: true,
                          isDraft: false,
                        ),
                      ),
                    );
                  },
                  child: Text('Reply'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final latestData = _getLatestReply();
                    print("-------------");
                    print(latestData);
                    print("-------------");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Compose(
                          initialTo: '', // Người dùng nhập địa chỉ mới
                          initialSubject: "Fwd: ${latestData.subject}",
                          userMail: widget.user.name,
                          isReply: false,
                          isDraft: false,
                          forwardedBody:
                              latestData.body, // Nội dung mail để forward
                        ),
                      ),
                    );
                  },
                  child: Text('Forward'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
