import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String? id;
  final String? image;
  final String? description;
  final String? category;
  final double? rating; // Kolom rating bintang kuliner
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? latitude;
  final String? longitude;
  final String? userId;
  final String? userFullName;

  Post({
    this.id,
    this.image,
    this.description,
    this.category,
    this.rating,
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.userId,
    this.userFullName,
  });
}