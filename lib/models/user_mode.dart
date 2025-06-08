import 'package:flutter/material.dart';

class AppUser {
  int id;
  String name;
  Color imageUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    // Lấy màu từ Firestore (sử dụng giá trị số nguyên, ví dụ 4293227496)
    int colorValue =
        data['imageUrl'] ?? 4293227496; // Sử dụng giá trị mặc định nếu không có

    return AppUser(
      id: data['id'] ?? 0, // Default ID to 0 if missing
      name:
          data['fullName'] ?? 'Unknown', // Default name to 'Unknown' if missing
      imageUrl: Color(colorValue), // Sử dụng giá trị số nguyên để tạo màu
    );
  }
}
