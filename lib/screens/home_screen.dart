import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_post_screen.dart';
import 'sign_in_screen.dart';
import '../service/post_service.dart';
import '../widget/post_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  String generateAvatarUrl(String? fullName) {
    final formattedName = (fullName ?? 'User').trim().replaceAll(' ', '+');
    return 'https://ui-avatars.com/api/?name=$formattedName&color=FFFFFF&background=FF5722';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Food Review Tracker"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            tooltip: "Keluar",
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16.0),
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(
              generateAvatarUrl(FirebaseAuth.instance.currentUser?.displayName),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            FirebaseAuth.instance.currentUser?.displayName ?? 'Foodies',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12.0),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder(
              stream: PostService.getPostList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Center(child: Text('Belum ada review kuliner.'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final isOwner = currentUserId != null && post.userId == currentUserId;
                      return PostListItem(post: post, isOwner: isOwner);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          );
        },
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}