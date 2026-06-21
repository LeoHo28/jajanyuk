import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/post.dart';

class PostService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<List<Post>> getPostList() {
    return _db.collection('posts').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data(); 
        return Post.fromMap(data, doc.id);
      }).toList();
    });
  }

  static Future<void> addPost(Post post) async {
    await _db.collection('posts').add(post.toMap());
  }

  static Future<void> deletePost(Post post) async {
    if (post.id != null) {
      await _db.collection('posts').doc(post.id).delete();
    }
  }

  static Future<void> toggleFavoritePost(String postId, String userId, bool isFavorite) async {
    final postRef = _db.collection('posts').doc(postId);
    if (isFavorite) {
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([userId])
      });
    } else {
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([userId])
      });
    }
  }

  // ==================== FITUR MULTI-USER RATING UPDATE KAMI ====================

  // Mendapatkan rating yang pernah diberikan user saat ini pada kuliner terkait
  static Future<int?> getUserRating(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db
        .collection('posts')
        .doc(postId)
        .collection('ratings')
        .doc(uid)
        .get();

    if (doc.exists) {
      return doc.data()?['rating'] as int?;
    }
    return null;
  }

  // Menambahkan ulasan baru ATAU memperbarui ulasan rating lama secara dinamis
  static Future<void> addRating(String postId, int selectedRating) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final postRef = _db.collection('posts').doc(postId);
    final ratingRef = postRef.collection('ratings').doc(uid);

    await _db.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      final ratingDoc = await transaction.get(ratingRef);

      if (!postDoc.exists) return;

      double currentSum = (postDoc.data()?['ratingSum'] as num?)?.toDouble() ?? 0.0;
      int currentCount = (postDoc.data()?['ratingCount'] as int?) ?? 0;

      if (ratingDoc.exists) {
        // Jika UPDATE: rating lama dikurangi, rating baru ditambahkan ke akumulasi sum
        int oldRating = ratingDoc.data()?['rating'] as int;
        double newSum = currentSum - oldRating + selectedRating;

        transaction.update(postRef, {'ratingSum': newSum});
      } else {
        // Jika BARU: tambahkan jumlah pengulas baru (Count + 1)
        double newSum = currentSum + selectedRating;
        int newCount = currentCount + 1;

        transaction.update(postRef, {
          'ratingSum': newSum,
          'ratingCount': newCount,
        });
      }

      // Simpan/Selesaikan data rating user di sub-collection
      transaction.set(ratingRef, {
        'rating': selectedRating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ==================== FITUR KOMENTAR (BARU) ====================

  // 1. Menambahkan komentar baru ke sub-collection di dalam dokumen post terkait
  static Future<void> addComment(String postId, Map<String, dynamic> commentData) async {
    // Menambahkan timestamp otomatis dari server agar urutan komentar konsisten
    commentData['createdAt'] = FieldValue.serverTimestamp();
    
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add(commentData);
  }

  // 2. Mengambil stream daftar komentar secara real-time (diurutkan dari yang terbaru)
  static Stream<QuerySnapshot> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 3. Menghapus komentar berdasarkan ID dokumen komentar tersebut
  static Future<void> deleteComment(String postId, String commentId) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}