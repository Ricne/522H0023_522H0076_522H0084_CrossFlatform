import 'package:final_project_flatform/models/user_mode.dart';
import 'package:final_project_flatform/tabs/mail_page.dart';
import 'package:flutter/material.dart';

class SearchResultsPage extends StatelessWidget {
  final List<Map<String, dynamic>> results; // Danh sách kết quả tìm kiếm

  // Constructor
  SearchResultsPage({required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
      ),
      body: results.isEmpty
          ? Center(child: Text('No results found.'))
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final mail = results[index];

                // Kiểm tra nếu 'sender' là chuỗi (email) hay Map<String, dynamic>
                var sender = mail['sender'];
                AppUser user;

                if (sender is String) {
                  // Nếu sender là một chuỗi email, tạo AppUser với thông tin mặc định
                  user = AppUser(
                      id: 0,
                      name: sender,
                      imageUrl: Colors
                          .blue); // Hoặc bạn có thể lấy màu và thông tin khác từ Firestore
                } else {
                  // Nếu sender là Map<String, dynamic>, dùng AppUser.fromFirestore
                  user = AppUser.fromFirestore(sender);
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.imageUrl, // Màu nền của avatar
                    child: Text(
                      user.name[0], // Chữ cái đầu tiên của tên người gửi
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(mail['subject'] ?? 'No Subject'),
                  subtitle: Text(mail['text'] ?? 'No content'),
                  trailing: Text(mail['time'] ?? 'No time'),
                  onTap: () {
                    // Handle email tap action to show full email details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Gmail(
                          index: index,
                          user: user, // Truyền đối tượng AppUser
                          time: mail['time'] ?? 'No time',
                          text: mail['text'] ?? 'No content',
                          subject: mail['subject'] ?? 'No Subject',
                          isstarred: mail['isStarred'] ?? false,
                          image:
                              user.imageUrl, // Màu sắc hoặc ảnh của người gửi
                          replies:
                              mail['replies'] ?? [], // Truyền danh sách replies
                          account: mail['account'] ??
                              'No account', // Thêm thông tin account
                          attachments: mail['attachments'] ?? '', //NEW
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
