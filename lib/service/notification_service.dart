import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ditambahkan untuk mendapatkan currentUser
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'review_channel',
    'Review Notifications',
    description: 'Notifikasi untuk aktivitas review kuliner',
    importance: Importance.max,
  );

  /// 1. Menginisialisasi Notifikasi Lokal di HP (Sudah diperbaiki nama parameternya)
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // Di sini nama parameter yang benar adalah "settings:" bukan langsung dioper tanpa nama parameter
    await _plugin.initialize(
      settings: settings, 
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        log("Notifikasi diklik: ${details.payload}");
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
    }
  }

  /// 2. Menampilkan Pop-up Banner di Layar HP (Sudah diperbaiki parameter id, title, body)
  static Future<void> showReviewNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'review_channel',
      'Review Notifications',
      channelDescription: 'Notifikasi untuk aktivitas review kuliner',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

    // Menuliskan parameter wajib bawaan plugin dengan lengkap dan benar
    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  /// 3. MEMBUAT DOKUMEN NOTIFIKASI DI FIRESTORE (Sudah ditambahkan parameter targetUserId)
  static Future<void> createNotificationToFirestore({
    required String title,
    required String body,
    required String type,
    required String targetUserId, // <-- Ditambahkan agar notifikasi tahu milik siapa (misal: ID milik Wowok)
  }) async {
    try {
      await _db.collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'read': false,
        'target_user_id': targetUserId, // <-- Disimpan ke Firestore untuk proses filter
        'created_at': FieldValue.serverTimestamp(),
      });

      // Banner pop-up lokal di HP HANYA akan muncul jika user yang sedang aktif 
      // adalah si target penerima notifikasi itu sendiri
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == targetUserId) {
        await showReviewNotification(title: title, body: body);
      }
    } catch (e) {
      log("Gagal membuat notifikasi ke Firestore: $e");
    }
  }

  /// 4. Mengambil data stream notifikasi MILIK USER YANG SEDANG AKTIF SAJA
  static Stream<QuerySnapshot> getNotificationsStream() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
    return _db
        .collection('notifications')
        .where('target_user_id', isEqualTo: currentUid) // <-- Memfilter agar data tidak bercampur dengan pengguna lain
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Menandai SATU notifikasi spesifik sebagai terbaca saat disentuh (tap)
  static Future<void> markNotificationAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Menandai SEMUA notifikasi milik user aktif menjadi terbaca menggunakan Write Batch
  static Future<void> markAllNotificationsAsRead() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
    final batch = _db.batch();
    
    // Hanya mencari dokumen belum dibaca milik si pengguna aktif
    final snapshot = await _db
        .collection('notifications')
        .where('target_user_id', isEqualTo: currentUid)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  /// Menghapus dokumen notifikasi tertentu
  static Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }
}