import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_post_screen.dart';
import 'favorite_screen.dart'; 
import 'profile_screen.dart'; 
import 'sign_in_screen.dart';
import '../service/post_service.dart';
import '../widget/post_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  // Desain Beranda Utama yang Menarik & Aman dari Overflow
  Widget _buildHomeDashboard() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Foodies';

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Sapaan Pengguna Modern
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, $userName! 👋",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  "Mau berburu kuliner apa hari ini?",
                  style: TextStyle(fontSize: 14, color: Colors.orange.shade100),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 20.0, bottom: 8.0),
            child: Text(
              "Penjelajahan Kuliner Terbaru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),

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
                  // Menggunakan ListView vertikal agar pas dengan komponen PostListItem bawaanmu
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final isOwner = currentUserId != null && post.userId == currentUserId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: PostListItem(post: post, isOwner: isOwner),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBodyWidgets() {
    return [
      _buildHomeDashboard(),
      const FavoriteScreen(),
      const Center(child: CircularProgressIndicator()), // Placeholder transisi
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jajanyuk", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            tooltip: "Keluar",
          ),
        ],
      ),
      body: _currentIndex == 2 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildBodyWidgets()[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 15,
        onTap: (index) {
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddPostScreen()),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: 'Favorit'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 32), label: 'Tambah'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}