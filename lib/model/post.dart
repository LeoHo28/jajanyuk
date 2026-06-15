class Post {
  final String? id;
  final String? image;
  final String? description;
  final String? category;
  final double? ratingSum;   // Menyimpan total penjumlahan bintang
  final int? ratingCount;    // Menyimpan total jumlah pengulas
  final String? createdAt;
  final String? updatedAt;
  final String? latitude;
  final String? longitude;
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
    return Post(
      id: id,
      image: map['image'],
      description: map['description'],
      category: map['category'],
      ratingSum: (map['ratingSum'] as num?)?.toDouble() ?? 0.0,
      ratingCount: map['ratingCount'] as int? ?? 0,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      latitude: map['latitude'],
      longitude: map['longitude'],
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId,
      'userFullName': userFullName,
      'likedBy': likedBy,
    };
  }
}