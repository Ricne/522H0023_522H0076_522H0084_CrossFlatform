import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:universal_io/io.dart' as universal;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_quill/flutter_quill.dart';

class Compose extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;
  final String? initialSubject;
  final String? initialBody;
  final String? initialBodyDelta; 
  final String? userMail;
  final String? userMailRe;
  final bool isReply;
  final bool isDraft;
  final String? draftId;
  final String? forwardedBody;
  final String? forwardedBodyDelta; 
  

  const Compose({
    super.key,
    this.initialFrom,
    this.initialTo,
    this.initialSubject,
    this.initialBody,
    this.initialBodyDelta, // ✅ 
    this.userMail,
    this.userMailRe,
    required this.isReply,
    required this.isDraft,
    this.draftId,
    this.forwardedBody,
    this.forwardedBodyDelta, // ✅
  });

  @override
  _ComposeState createState() => _ComposeState();
}

class _ComposeState extends State<Compose> {
  List<Uint8List> _webSelectedFiles = [];
  List<File> _mobileSelectedFiles = [];
  List<String> attachmentUrls = [];
  List<String> _webFileNames = [];
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();

  PlatformFile? file;
  bool entered = false;
  bool isClicked = false;
  bool isCcBccExpanded = false;
  String? fromValue;
  bool isSent = false;
  final currenUser = FirebaseAuth.instance.currentUser?.email;
  final messageID = FirebaseFirestore.instance.collection('mails').doc().id;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _quillController = QuillController.basic();
  }

  // ✅ Hàm lưu draft với Delta
  Future<void> saveDraft() async {
    print(currenUser);
    
    // Lấy cả plain text và Delta
    final bodyText = _quillController.document.toPlainText();
    final bodyDelta = jsonEncode(_quillController.document.toDelta().toJson());
    
    if (!isSent ||
        (subjectController.text.isNotEmpty ||
            bodyText.isNotEmpty ||
            toController.text.isNotEmpty)) {
      final draft = {
        'from': currenUser,
        'to': toController.text,
        'subject': subjectController.text,
        'body': bodyText, // Plain text để tìm kiếm
        'bodyDelta': bodyDelta, // ✅ Lưu Delta để preserve formatting
        'time': DateTime.now().toIso8601String(),
      };

      try {
        final queryDraftID = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userMail)
            .collection('drafts')
            .get();

        bool draftUpdated = false;
        for (var doc in queryDraftID.docs) {
          final draftID = doc.id;
          if (widget.draftId == draftID) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currenUser)
                .collection('drafts')
                .doc(draftID)
                .update(draft);
            print('Draft updated successfully!');
            draftUpdated = true;
            break;
          }
        }
        
        if (widget.draftId == null || !draftUpdated) {
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

  // ✅ Upload attachments (giữ nguyên)
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

    // Web files
    for (int i = 0; i < webFiles.length; i++) {
      final fileBytes = webFiles[i];
      final fileName = webFileNames[i];
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
  final TextEditingController bodyController = TextEditingController(); // Có thể bỏ vì dùng Quill

  // ✅ Load draft content với Delta
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (widget.isDraft == true) {
      toController.text = widget.initialTo!;
      subjectController.text = widget.initialSubject!;
      
      // ✅ Load draft content với Delta nếu có
      if (widget.initialBodyDelta != null && widget.initialBodyDelta!.isNotEmpty) {
        try {
          final deltaJson = jsonDecode(widget.initialBodyDelta!);
          final delta = Delta.fromJson(deltaJson);
          _quillController.document = Document.fromDelta(delta);
        } catch (e) {
          print('Error loading Delta: $e');
          // Fallback về plain text
          if (widget.initialBody != null && widget.initialBody!.isNotEmpty) {
            _quillController.document = Document()..insert(0, widget.initialBody!);
          }
        }
      } else if (widget.initialBody != null && widget.initialBody!.isNotEmpty) {
        _quillController.document = Document()..insert(0, widget.initialBody!);
      }
    }

    if (widget.initialTo != null) {
      toController.text = widget.initialTo!;
    }
    if (widget.initialSubject != null) {
      subjectController.text = widget.initialSubject!;
    }

    // ✅ Load forwarded content với Delta
    if (widget.forwardedBodyDelta != null && widget.forwardedBodyDelta!.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(widget.forwardedBodyDelta!);
        final delta = Delta.fromJson(deltaJson);
        _quillController.document = Document.fromDelta(delta);
      } catch (e) {
        print('Error loading forwarded Delta: $e');
        // Fallback về plain text
        if (widget.forwardedBody != null && widget.forwardedBody!.isNotEmpty) {
          _quillController.document = Document()..insert(0, widget.forwardedBody!);
        }
      }
    } else if (widget.forwardedBody != null && widget.forwardedBody!.isNotEmpty) {
      _quillController.document = Document()..insert(0, widget.forwardedBody!);
    }
  }

  // ✅ Sửa lỗi sendMail - lưu cả plain text và Delta
  Future<void> sendMail() async {
    List<String> attachmentUrls = [];
    final bodyText = _quillController.document.toPlainText();
    final bodyDelta = jsonEncode(_quillController.document.toDelta().toJson()); // ✅ Lưu Delta

    if (kIsWeb) {
      attachmentUrls = await uploadAttachments(
        mobileFiles: [],
        webFiles: _webSelectedFiles,
        webFileNames: _webFileNames,
      );
    } else {
      attachmentUrls = await uploadAttachments(
        mobileFiles: _mobileSelectedFiles,
        webFiles: [],
        webFileNames: [],
      );
    }
    print('Uploaded URLs: $attachmentUrls');

    if (widget.isReply) {
      Map<String, dynamic> emailDataReply = {
        'from': fromValue,
        'to': toController.text,
        'subject': subjectController.text,
        'body': bodyText, // ✅ Plain text
        'bodyDelta': bodyDelta, // ✅ Formatted content
        'time': DateTime.now().toIso8601String(),
        'attachments': attachmentUrls.join(',')
      };
      
      try {
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
          final messageID = doc.id;

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
            break;
          }
        }

        for (var doc in querySnapshot2.docs) {
          final data = doc.data();
          final messageID = doc.id;

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
            break;
          }
        }

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
        'text': bodyText, // ✅ Plain text
        'textDelta': bodyDelta, // ✅ Formatted content
        'time': currentTime.toIso8601String(),
        'isStarred': false,
        'unread': true,
        'color': getRandomColor().value,
        'replies': [],
      });
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(toController.text)
          .collection('mails')
          .doc(widget.draftId)
          .set({
        'messageID': widget.draftId,
        'sender': fromValue,
        'receiver': toController.text,
        'subject': subjectController.text.replaceFirst('Fwd:', '').trim(),
        'text': bodyText, // ✅ Plain text
        'textDelta': bodyDelta, // ✅ Formatted content
        'time': currentTime.toIso8601String(),
        'isStarred': false,
        'unread': true,
        'color': getRandomColor().value,
        'replies': [],
      });
      Navigator.pop(context);
    } else {
      // Mail mới
      Map<String, String> emailData = {
        'to': toController.text,
        'cc': ccController.text,
        'bcc': bccController.text,
        'subject': subjectController.text,
        'body': bodyText, // ✅ Plain text
        'bodyDelta': bodyDelta, // ✅ Formatted content
        'attachments': attachmentUrls.join(','),
      };

      if (widget.forwardedBody != null && widget.forwardedBody!.isNotEmpty) {
        final messageID = FirebaseFirestore.instance.collection('mails').doc().id;
        final currentTime = DateTime.now();
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(toController.text)
            .collection('mails')
            .doc(messageID)
            .set({
          'messageID': messageID,
          'sender': fromValue,
          'receiver': toController.text,
          'subject': subjectController.text.replaceFirst('Fwd:', '').trim(),
          'text': bodyText, // ✅ Plain text
          'textDelta': bodyDelta, // ✅ Formatted content
          'time': currentTime.toIso8601String(),
          'isStarred': false,
          'unread': true,
          'color': getRandomColor().value,
          'replies': [],
        });
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(fromValue)
            .collection('mails')
            .doc(messageID)
            .set({
          'messageID': messageID,
          'sender': fromValue,
          'receiver': toController.text,
          'subject': subjectController.text,
          'text': bodyText, // ✅ Plain text
          'textDelta': bodyDelta, // ✅ Formatted content
          'time': currentTime.toIso8601String(),
          'isStarred': false,
          'unread': true,
          'color': getRandomColor().value,
          'replies': [],
        });
      }

      Navigator.pop(context, emailData);
      
      // Clear fields
      toController.clear();
      ccController.clear();
      bccController.clear();
      subjectController.clear();
      _quillController.clear(); // ✅ Clear Quill controller
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
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
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await saveDraft();
        return true;
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
                    onTap: () => saveDraft(), // ✅ Gọi saveDraft trực tiếp
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
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: QuillSimpleToolbar(
              controller: _quillController,
              config: const QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showColorButton: true,
                showBackgroundColorButton: true,
                showListNumbers: true,
                showListBullets: true,
                showCodeBlock: false,
                showInlineCode: false,
                showLink: true,
                showUndo: true,
                showRedo: true,
                showFontSize: true,
                showFontFamily: false,
                showHeaderStyle: true,
                showAlignmentButtons: true,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: QuillEditor.basic(
                controller: _quillController,
                focusNode: _focusNode,
                config: QuillEditorConfig(
                  placeholder: entered == false ? "Compose email" : file?.name ?? "Compose email",
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
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
        for (var file in _mobileSelectedFiles)
          ListTile(
            leading: Icon(Icons.attach_file),
            title: Text(file.path.split('/').last),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _mobileSelectedFiles.remove(file);
                });
              },
            ),
          ),
        for (int i = 0; i < _webSelectedFiles.length; i++)
          Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: _isImage(_webSelectedFiles[i])
                  ? Image.memory(
                      _webSelectedFiles[i],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.insert_drive_file),
              title: Text(_webFileNames[i]), // ✅ Show actual filename
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _webSelectedFiles.removeAt(i);
                    _webFileNames.removeAt(i); // ✅ Remove matching filename
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  bool _isImage(Uint8List fileBytes) {
    try {
      return Image.memory(fileBytes).width != null;
    } catch (e) {
      return false;
    }
  }
}