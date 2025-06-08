import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project_flatform/models/reply_mode.dart';
import 'package:flutter/material.dart';
import 'package:final_project_flatform/models/user_mode.dart';

class Message {
  final AppUser sender;
  final String reciever;
  final String time;
  final String text;
  final String subject;
  bool isStarred;
  bool unread;
  bool isSelected;
  final String? threadID; // Để nhóm các mail trong cùng một luồng
  final List<Reply> replies; // Danh sách các phản hồi
  final String attachments;

  Message({
    required this.sender,
    required this.reciever,
    required this.time,
    required this.text,
    required this.subject,
    this.isStarred = false,
    this.unread = true,
    this.isSelected = false,
    this.threadID,
    this.replies = const [],
    required this.attachments,
  });

  get body => null;

  void addReply(Reply reply) {
    replies.add(reply);
  }

  @override
  String toString() {
    return 'Message from ${sender.name}, Subject: $subject, Time: $time';
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
        threadID: map['messageID'],
        isSelected: false,
        sender: map['sender'] ?? '',
        reciever: map['receiver'] ?? '',
        subject: map['subject'] ?? '',
        text: map['text'] ?? '',
        time: map['time'] ?? '',
        isStarred: map['isStarred'] ?? false,
        attachments: map['attachments'] ?? '' //NEW
        );
  }

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
        threadID: data['messageID'] ??
            '', 
        isSelected: false,
        sender: data['sender'] ?? '',
        reciever: data['receiver'] ?? '',
        subject: data['subject'] ?? '',
        text: data['text'] ?? '',
        time: data['time'] ?? '',
        isStarred: data['isStarred'] ?? false,
        attachments: data['attachments'] ?? '' 
        );
  }
}
