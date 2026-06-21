import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String? id;
  final String? image;
  final String? description;
  final String? category;
  final double? ratingSum;   
  final int? ratingCount;    
  final DateTime? createdAt; // 👈 Diubah menjadi DateTime agar fleksibel
  final DateTime? updatedAt; // 👈 Diubah menjadi DateTime
  final double? latitude;
  final double? longitude;
  final String? userId;
  final String? userFullName;
  final List<dynamic>? likedBy;

  Post({
    this.id,
    this.image,
    this.description,
    this.category,
    this.ratingSum,
    this.ratingCount,
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.userId,
    this.userFullName,
    this.likedBy,
  });

  // Hitung otomatis rata-rata bintang
  double get averageRating {
    if (ratingCount == null || ratingCount == 0) return 0.0;
    return (ratingSum ?? 0.0) / ratingCount!;
  }

  factory Post.fromMap(Map<String, dynamic> map, String id) {
    double? _parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    // Fungsi pembantu untuk konversi Timestamp Firebase ke DateTime Flutter
    DateTime? _parseDateTime(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return Post(
      id: id,
      image: map['image'],
      description: map['description'],
      category: map['category'],
      ratingSum: _parseDouble(map['ratingSum']) ?? 0.0,
      ratingCount: _parseInt(map['ratingCount']) ?? 0,
      createdAt: _parseDateTime(map['createdAt']), // 👈 parsing aman dari Timestamp
      updatedAt: _parseDateTime(map['updatedAt']),
      latitude: _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),
      userId: map['userId'],
      userFullName: map['userFullName'],
      likedBy: map['likedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'description': description,
      'category': category,
      'ratingSum': ratingSum,
      'ratingCount': ratingCount,
      // 👈 Jika bernilai null, server otomatis mengisi dengan serverTimestamp() waktu Firebase
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId,
      'userFullName': userFullName,
      'likedBy': likedBy,
    };
  }
}