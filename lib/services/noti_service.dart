import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final ValueNotifier<bool> isNotificationEnabledNotifier = ValueNotifier(false);
  static bool isNotificationEnabled = false;
  static StreamSubscription? emailSubscription;
  static Future<void> loadNotificationPreference() async {
    final userMail = FirebaseAuth.instance.currentUser?.email;
    if (userMail == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userMail).get();
    if (userDoc.exists) {
      final isEnabled = userDoc['isNotificationEnabled'] ?? false;
      isNotificationEnabledNotifier.value = isEnabled;
    }
  }

  static Future<void> updateNotificationPreference(bool isEnabled) async {
    final userMail = FirebaseAuth.instance.currentUser?.email;
    if (userMail == null) return;

    isNotificationEnabledNotifier.value = isEnabled;

    await FirebaseFirestore.instance.collection('users').doc(userMail).set(
      {'isNotificationEnabled': isEnabled},
      SetOptions(merge: true),
    );
  }

  static Future<void> initialize() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
    await requestPermission();
    await loadNotificationPreference();
    isNotificationEnabledNotifier.addListener(() {
      listenForNewEmails(); // Gọi lại mỗi khi trạng thái thông báo thay đổi
    });
    listenForNewEmails();
  }

  static Future<void> requestPermission() async {
  final status = await Permission.notification.status;
  if (status.isDenied) {
    final requestStatus = await Permission.notification.request();
    print("Notification permission status: $requestStatus");
  } else {
    print("Notification permission granted.");
  }
}

  static Future<void> showNewMailNotification(String sender, String subject, String time) async {
    if (!isNotificationEnabledNotifier.value) {
      print("Notification is disabled. Skipping notification display.");
    return; // Không hiển thị thông báo nếu bị tắt
    }
    const androidDetails = AndroidNotificationDetails(
      'new_email_channel',
      'New Email Notifications',
      channelDescription: 'Shows notifications for new emails',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, 'New Email from $sender', '$subject \n at $time', notificationDetails);
  }

  static void listenForNewEmails() {
    emailSubscription?.cancel();
    emailSubscription = null;
    if (!isNotificationEnabledNotifier.value) {
      print("Notifications are disabled. Skipping email listener.");
    return;
    }

    
    final userMail = FirebaseAuth.instance.currentUser?.email;
    if (userMail == null) return;

    emailSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userMail)
        .collection('mails')
        .snapshots()
        .listen((querySnapshot) {
      for (var change in querySnapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final newMail = change.doc.data();
          final sender = newMail?['sender'] ?? 'Unknown';
          final subject = newMail?['subject'] ?? 'No Subject';
          final time = DateFormat('hh:mm a').format(DateTime.parse(newMail?['time']));
          if (newMail?['receiver'] == userMail) {
            showNewMailNotification(sender, subject, time);
          }
          // showNewMailNotification(sender, subject, time);
        }
      }
    });
  }
  
}
