import 'package:final_project_flatform/models/user_mode.dart' as myModels;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/pages/logout.dart';
import 'package:final_project_flatform/tabs/advanced_search.dart';
import 'package:final_project_flatform/tabs/searchresultpage.dart';
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

class AdvancedSearch extends StatefulWidget {
  const AdvancedSearch({super.key});
  @override
  _AdvancedSearchState createState() => _AdvancedSearchState();
}

class _AdvancedSearchState extends State<AdvancedSearch> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final subjectController = TextEditingController();
  final hasWordsController = TextEditingController();
  final doesntHaveController = TextEditingController();
  final userMail = FirebaseAuth.instance.currentUser?.email;

  Future<List<Map<String, dynamic>>> searchEmails() async {
    // Đảm bảo lấy email của người dùng hiện tại
    final userMail = FirebaseAuth.instance.currentUser?.email;
    // Lấy tất cả emails của người dùng hiện tại từ Firestore
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users') // Thư mục của người dùng
        .doc(userMail) // Tìm theo email của người dùng hiện tại
        .collection('mails') // Thư mục chứa các mail của người dùng
        .get();

    // Lọc dữ liệu theo các tiêu chí đã cho
    final searchResults = querySnapshot.docs.where((doc) {
      final data = doc.data();
      bool matches = true;

      if (fromController.text.isNotEmpty &&
          !data['sender']
              .toString()
              .toLowerCase()
              .contains(fromController.text.toLowerCase())) {
        matches = false;
      }
      if (toController.text.isNotEmpty &&
          !data['receiver']
              .toString()
              .toLowerCase()
              .contains(toController.text.toLowerCase())) {
        matches = false;
      }
      if (subjectController.text.isNotEmpty &&
          !data['subject']
              .toString()
              .toLowerCase()
              .contains(subjectController.text.toLowerCase())) {
        matches = false;
      }
      if (hasWordsController.text.isNotEmpty &&
          !data['text']
              .toString()
              .toLowerCase()
              .contains(hasWordsController.text.toLowerCase())) {
        matches = false;
      }
      if (doesntHaveController.text.isNotEmpty &&
          data['text']
              .toString()
              .toLowerCase()
              .contains(doesntHaveController.text.toLowerCase())) {
        matches = false;
      }

      return matches;
    }).map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();

    return searchResults;
  }

  String? selectedDateWithin; // Dropdown value
  String? selectedSearchScope;

  var query; // Dropdown value

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Advanced Search'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // From
            TextField(
              controller: fromController,
              decoration: InputDecoration(labelText: 'From'),
            ),
            // To
            TextField(
              controller: toController,
              decoration: InputDecoration(labelText: 'To'),
            ),
            // Subject
            TextField(
              controller: subjectController,
              decoration: InputDecoration(labelText: 'Subject'),
            ),
            // Has the words
            TextField(
              controller: hasWordsController,
              decoration: InputDecoration(labelText: 'Has the words'),
            ),
            // Doesn't have
            TextField(
              controller: doesntHaveController,
              decoration: InputDecoration(labelText: "Doesn't have"),
            ),
            // Date within
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Date within'),
              items: ['1 day', '1 week', '1 month']
                  .map((value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDateWithin = value;
                });
              },
            ),
            // Search scope
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Search'),
              items: ['All Mail', 'Inbox', 'Sent']
                  .map((value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedSearchScope = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Đóng popup
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              // Lấy kết quả tìm kiếm
              List<Map<String, dynamic>> searchResults = await searchEmails();
              if (searchResults.isNotEmpty) {
                // Chuyển đến trang SearchResultsPage và truyền danh sách kết quả
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SearchResultsPage(results: searchResults),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('No emails found matching your criteria.')),
                );
              }
            } catch (e) {
              // Hiển thị thông báo lỗi nếu người dùng chưa đăng nhập
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          },
          child: Text('Search'),
        )
      ],
    );
  }
}
