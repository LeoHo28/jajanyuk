import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../service/post_service.dart';
import '../widget/post_list_item.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      color: Colors.grey.shade50,
      child: StreamBuilder(
        stream: PostService.getPostList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allPosts = snapshot.data ?? [];
          
          // Memfilter kiriman secara nyata berdasarkan ada tidaknya UID user di dalam array likedBy
          final favoritePosts = allPosts.where((post) {
            return post.likedBy != null && post.likedBy!.contains(currentUserId);
          }).toList();

          if (favoritePosts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada kuliner favoritmu.',
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Simpan ulasan resto yang kamu sukai di sini.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              itemCount: favoritePosts.length,
              itemBuilder: (context, index) {
                final post = favoritePosts[index];
                final isOwner = currentUserId != null && post.userId == currentUserId;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  // Menggunakan ListView Vertikal agar aman dari overflow / garis kuning hitam
                  child: PostListItem(post: post, isOwner: isOwner),
                );
              },
            ),
          );
        },
      ),
    );
  }
}