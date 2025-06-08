import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as universal;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Compose extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;
  final String? initialSubject;
  final String? initialBody;
  final String? userMail;
  final String? userMailRe;
  final bool isReply;
  final bool isDraft;
  final String? draftId; // Lưu ID của nháp hiện tại
  final String? forwardedBody;
  

  const Compose(
      {super.key,
      this.initialFrom,
      this.initialTo,
      this.initialSubject,
      this.initialBody,
      this.userMail,
      this.userMailRe,
      required this.isReply,
      required this.isDraft,
      this.draftId,
      this.forwardedBody});

  @override
  _ComposeState createState() => _ComposeState();
}

class _ComposeState extends State<Compose> {
  List<Uint8List> _webSelectedFiles = [];
  List<File> _mobileSelectedFiles = [];
  List<String> attachmentUrls = [];
  List<String> _webFileNames = [];

  PlatformFile? file;
  bool entered = false;
  bool isClicked = false;
  bool isCcBccExpanded = false;
  String? fromValue;
  bool isSent = false; // Biến theo dõi trạng thái đã gửi
  final currenUser = FirebaseAuth.instance.currentUser?.email;
  // Tạo một messageID duy nhất
  final messageID = FirebaseFirestore.instance.collection('mails').doc().id;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> saveDraft() async {
    print(currenUser);
    if (!isSent ||
        (subjectController.text.isNotEmpty ||
            bodyController.text.isNotEmpty ||
            toController.text.isNotEmpty)) {
      final draft = {
        'from': currenUser,
        'to': toController.text,
        'subject': subjectController.text,
        'body': bodyController.text,
        'time': DateTime.now().toIso8601String(),
      };

      try {
        final queryDraftID = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userMail)
            .collection('drafts')
            .get();

        for (var doc in queryDraftID.docs) {
          final draftID = doc.id; // Lấy ID của email
          print(widget.draftId);
          print(draftID);
          if (widget.draftId == draftID) {
            // Cập nhật nháp nếu đã tồn tại draftId
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currenUser)
                .collection('drafts')
                .doc(draftID)
                .update(draft);

            print('Draft updated successfully!');
          }
        }
        print(widget.draftId);
        if (widget.draftId == null) {
          // Lưu mới nếu chưa có draftId
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currenUser)
              .collection('drafts')
              .add(draft);

          print('Draft created successfully!');
        }
      } catch (e) {
        print('Failed to save draft: $e');
      }
    } else {
      print('Draft not saved: No valid content or email already sent.');
    }
  }

  Future<List<String>> uploadAttachments({
    required List<File> mobileFiles,
    required List<Uint8List> webFiles,
    required List<String> webFileNames, 
  }) async {
    const String cloudName = 'dj7dzrxjg';
    const String uploadPreset = 'avatar_unsigned';
    List<String> attachmentUrls = [];

    String getResourceType(String fileName) {
      final ext = fileName.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
      if (['mp4', 'mov', 'avi', 'webm'].contains(ext)) return 'video';
      return 'raw';
    }

    // Mobile files
    for (var file in mobileFiles) {
      final fileName = file.path.split('/').last;
      final resourceType = getResourceType(fileName);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload'),
      );
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        attachmentUrls.add(data['secure_url']);
      } else {
        print('❌ Upload mobile file thất bại ($fileName): $responseBody');
      }
    }

    // Web files (webFileNames phải cùng số lượng với webFiles)
    for (int i = 0; i < webFiles.length; i++) {
      final fileBytes = webFiles[i];
      final fileName = webFileNames[i]; // 👈 Lấy tên gốc
      final resourceType = getResourceType(fileName);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload'),
      );
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        attachmentUrls.add(data['secure_url']);
      } else {
        print('❌ Upload web file thất bại ($fileName): $responseBody');
      }
    }

    return attachmentUrls;
  }

  Future<bool> checkIfUserExists(String email) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(email).get();
    return userDoc.exists;
  }

  Future<void> _loadUserEmail() async {
    String? email = FirebaseAuth.instance.currentUser?.email;
    setState(() {
      fromValue = email;
    });
  }

  // Controllers
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController ccController = TextEditingController();
  final TextEditingController bccController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();

  // Khởi tạo giá trị nếu là email phản hồi
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isDraft == true) {
      toController.text = widget.initialTo!;
      subjectController.text = widget.initialSubject!;
      bodyController.text = widget.initialBody!;
    }

    if (widget.initialTo != null) {
      toController.text = widget.initialTo!;
    }
    if (widget.initialSubject != null) {
      subjectController.text = widget.initialSubject!;
    }

    // Nếu là mail Forward, thêm nội dung mail cũ vào body
    if (widget.forwardedBody != null && widget.forwardedBody!.isNotEmpty) {
      bodyController.text = widget.forwardedBody!;
    }
  }

  Future<void> sendMail() async {
    List<String> attachmentUrls = [];
      if (kIsWeb) {
        attachmentUrls = await uploadAttachments(
          mobileFiles: [], // Mobile không có file
          webFiles: _webSelectedFiles, // List<Uint8List>
          webFileNames: _webFileNames, // 👈 List<String>, ví dụ: ['abc.pdf', 'img.png']
        );
      } else {
        attachmentUrls = await uploadAttachments(
          mobileFiles: _mobileSelectedFiles, // List<File>
          webFiles: [], // Web không có file
          webFileNames: [], // Bắt buộc truyền rỗng
        );
      }
    print('Uploaded URLs: $attachmentUrls');

    if (attachmentUrls.isNotEmpty) {
      print('There are ${attachmentUrls.length} attachment(s) uploaded.');
    } else {
      print('No attachments uploaded.');
    }

    if (widget.isReply) {
      Map<String, dynamic> emailDataReply = {
        'from': fromValue, // Người phản hồi
        'to': toController.text, // Người nhận phản hồi
        'subject': subjectController.text,
        'body': bodyController.text,
        'time': DateTime.now().toIso8601String(), // Thời gian phản hồi
        'attachments': attachmentUrls.join(',') // Lưu URL file đính kèm
      };
      try {
        // Lấy tất cả email trong sub-collection 'mails'
        final querySnapshot1 = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userMail)
            .collection('mails')
            .get();

        final querySnapshot2 = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userMailRe)
            .collection('mails')
            .get();

        for (var doc in querySnapshot1.docs) {
          final data = doc.data();
          final messageID = doc.id; // Lấy ID của email

          // Kiểm tra email phù hợp với subject và sender
          if (data['subject'].trim().toLowerCase() ==
                  subjectController.text.trim().toLowerCase() &&
              data['sender'].trim().toLowerCase() ==
                  widget.userMail!.trim().toLowerCase()) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userMail)
                .collection('mails')
                .doc(messageID)
                .update({
              'replies': FieldValue.arrayUnion([emailDataReply]),
            });

            break; // Dừng lặp khi tìm thấy email phù hợp
          }
        }

        for (var doc in querySnapshot2.docs) {
          final data = doc.data();
          final messageID = doc.id; // Lấy ID của email

          // Kiểm tra email phù hợp với subject và sender
          if (data['subject'].trim().toLowerCase() ==
                  subjectController.text.trim().toLowerCase() &&
              data['receiver'].trim().toLowerCase() ==
                  widget.userMailRe!.trim().toLowerCase()) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userMailRe)
                .collection('mails')
                .doc(messageID)
                .update({
              'replies': FieldValue.arrayUnion([emailDataReply]),
            });

            break; // Dừng lặp khi tìm thấy email phù hợp
          }
        }

        // Trả lại thông tin phản hồi để hiển thị trên màn hình trước
        Navigator.pop(context, emailDataReply);
      } catch (e) {
        print("Error updating email replies: $e");
      }
    } else if (widget.isDraft == true && widget.draftId != null) {
      final currentTime = DateTime.now();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromValue)
          .collection('drafts')
          .doc(widget.draftId)
          .delete();
      print('Draft deleted successfully!');

      // Lưu mail vào collection `mails`
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromValue)
          .collection('mails')
          .doc(widget.draftId)
          .set({
        'messageID': widget.draftId,
        'sender': fromValue,
        'receiver': toController.text,
        'subject': subjectController.text,
        'text': bodyController.text,
        'time': currentTime.toIso8601String(),
        'isStarred': false,
        'unread': true,
        'color': getRandomColor().value,
        'replies': [], // Khởi tạo replies rỗng
      });
      print('Draft convert to Mail successfully!');
      // Lưu mail vào người nhận
      await FirebaseFirestore.instance
          .collection('users')
          .doc(toController.text) // ID người gửi
          .collection('mails')
          .doc(widget.draftId) // Sử dụng messageID duy nhất
          .set({
        'messageID': widget.draftId,
        'sender': fromValue,
        'receiver': toController.text,
        'subject': subjectController.text.replaceFirst('Fwd:', '').trim(),
        'text': bodyController.text,
        'time': currentTime.toIso8601String(),
        'isStarred': false,
        'unread': true,
        'color': getRandomColor().value,
        'replies': [], // Khởi tạo replies rỗng
      });
      Navigator.pop(context);
    } else {
      //Nếu là mail mới
      // Đọc dữ liệu email từ các trường nhập
      Map<String, String> emailData = {
        'to': toController.text,
        'cc': ccController.text,
        'bcc': bccController.text,
        'subject': subjectController.text,
        'body': bodyController.text,
        'attachments': attachmentUrls.join(','),
      };

      if (widget.forwardedBody != null && widget.forwardedBody!.isNotEmpty) {
        // Tạo một messageID duy nhất
        final messageID =
            FirebaseFirestore.instance.collection('mails').doc().id;
        final currentTime = DateTime.now();
        // Lưu mail vào người nhận
        await FirebaseFirestore.instance
            .collection('users')
            .doc(toController.text) // ID người gửi
            .collection('mails')
            .doc(messageID) // Sử dụng messageID duy nhất
            .set({
          'messageID': messageID,
          'sender': fromValue,
          'receiver': toController.text,
          'subject': subjectController.text.replaceFirst('Fwd:', '').trim(),
          'text': bodyController.text,
          'time': currentTime.toIso8601String(),
          'isStarred': false,
          'unread': true,
          'color': getRandomColor().value,
          'replies': [], // Khởi tạo replies rỗng
        });
        // Lưu mail vào người gửi
        await FirebaseFirestore.instance
            .collection('users')
            .doc(fromValue) // ID người gửi
            .collection('mails')
            .doc(messageID) // Sử dụng messageID duy nhất
            .set({
          'messageID': messageID,
          'sender': fromValue,
          'receiver': toController.text,
          'subject': subjectController.text,
          'text': bodyController.text,
          'time': currentTime.toIso8601String(),
          'isStarred': false,
          'unread': true,
          'color': getRandomColor().value,
          'replies': [], // Khởi tạo replies rỗng
        });
      }

      Navigator.pop(context, emailData);
      // Xóa trường thông tin sau khi gửi
      toController.clear();
      ccController.clear();
      bccController.clear();
      subjectController.clear();
      bodyController.clear();
      setState(() {
        file = null;
        entered = false;
      });
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

  Future<void> pickFile() async {
    if (kIsWeb) {
      // Dành cho web
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true, // Quan trọng để lấy file.bytes
      );

      if (result != null) {
        setState(() {
          _webSelectedFiles.addAll(
            result.files.map((file) => file.bytes!).toList(),
          );
          _webFileNames.addAll(
            result.files.map((file) => file.name).toList(),
          );
        });
      }
    } else {
      // Dành cho mobile
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _mobileSelectedFiles.addAll(
            result.paths.whereType<String>().map((path) => File(path)).toList(),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await saveDraft(); // Gọi hàm lưu draft khi người dùng bấm back
        return true; // Cho phép quay lại
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
          title: Text(
            'Compose',
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontFamily: "Roboto"),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.grey[600]),
              onPressed: pickFile,
            ),
            IconButton(
              icon: Icon(Icons.send, color: Colors.grey[600]),
              onPressed: sendMail,
            ),
            PopupMenuButton<String>(
              offset: Offset(50, 350),
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(value: '1', child: Text('Schedule Send')),
                  PopupMenuItem(value: '2', child: Text('Add from contacts')),
                  PopupMenuItem(value: '3', child: Text('Discard')),
                  PopupMenuItem(
                    value: '4',
                    child: Text('Save Draft'),
                    onTap: () {},
                  ),
                ];
              },
            )
          ],
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildFromField(),
            _buildDivider(),
            _buildToField(),
            _buildDivider(),
            if (isCcBccExpanded) _buildCcBccFields(),
            _buildDivider(),
            _buildSubjectField(),
            _buildDivider(),
            _buildBodyField(),
            if (_mobileSelectedFiles.isNotEmpty || _webSelectedFiles.isNotEmpty)
              _buildAttachmentPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildFromField() {
    return Row(
      children: [
        Container(
            padding: EdgeInsets.all(20),
            child: Text('From:',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]))),
        Expanded(
            child: Text(
          '$fromValue',
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
        )),
      ],
    );
  }

  Widget _buildToField() {
    return Row(
      children: [
        Container(
            padding: EdgeInsets.all(20),
            child: Text('To',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]))),
        Expanded(
          child: TextField(
            controller: toController,
            cursorHeight: 22,
            style: TextStyle(fontSize: 18),
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(Icons.arrow_drop_down),
                onPressed: () {
                  setState(() {
                    isCcBccExpanded = !isCcBccExpanded;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCcBccFields() {
    return Column(
      children: [
        _buildFieldRow(label: 'Cc', controller: ccController),
        _buildDivider(),
        _buildFieldRow(label: 'Bcc', controller: bccController),
      ],
    );
  }

  Widget _buildSubjectField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: subjectController,
            cursorHeight: 22,
            style: TextStyle(fontSize: 18),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Subject",
              contentPadding: EdgeInsets.all(20),
              hintStyle: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyField() {
    return Expanded(
      child: TextField(
        controller: bodyController,
        cursorHeight: 24,
        maxLines: null,
        expands: true,
        style: TextStyle(fontSize: 18),
        decoration: InputDecoration(
          hintText: entered == false ? "Compose email" : file!.name,
          border: InputBorder.none,
          hintStyle: TextStyle(fontSize: 18, color: Colors.grey[700]),
          contentPadding: EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildFieldRow(
      {required String label, required TextEditingController controller}) {
    return Row(
      children: [
        Container(
            padding: EdgeInsets.all(20),
            child: Text(label,
                style: TextStyle(fontSize: 18, color: Colors.grey[700]))),
        Expanded(
          child: TextField(
            controller: controller,
            cursorHeight: 22,
            style: TextStyle(fontSize: 18),
            decoration: InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 1.0)),
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return Column(
      children: [
        // Xem trước file trên mobile
        for (var file in _mobileSelectedFiles)
          ListTile(
            leading: Icon(Icons.attach_file),
            title: Text(file.path.split('/').last), // Hiển thị tên tệp
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _mobileSelectedFiles.remove(file); // Xóa tệp khỏi danh sách
                });
              },
            ),
          ),
        // Xem trước file trên web
        for (var fileBytes in _webSelectedFiles)
          Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: _isImage(fileBytes)
                  ? Image.memory(
                      fileBytes,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons
                      .insert_drive_file), // Icon mặc định nếu không phải ảnh
              title: Text('File'), // Hiển thị tên chung cho web file
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _webSelectedFiles
                        .remove(fileBytes); // Xóa tệp khỏi danh sách
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  bool _isImage(Uint8List fileBytes) {
    // Kiểm tra byte đầu của file để xác định có phải ảnh không
    // Bạn có thể cải thiện hàm này với các phương pháp xác định file cụ thể hơn
    try {
      return Image.memory(fileBytes).width != null; // Sử dụng thử nếu là ảnh
    } catch (e) {
      return false; // Không phải ảnh
    }
  }
}
