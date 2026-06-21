import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ditambahkan untuk StreamBuilder Notifikasi
import 'add_post_screen.dart';
import 'favorite_screen.dart'; 
import 'profile_screen.dart'; 
import 'sign_in_screen.dart';
import '../service/post_service.dart';
import '../service/notification_service.dart'; // Ditambahkan untuk akses stream notifikasi realtime
import '../widget/post_list_item.dart';
import 'notification_screen.dart'; 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Mengaktifkan sistem push notification lokal Android sejak aplikasi pertama kali dibuka
    _initNotificationSystem();
  }

  Future<void> _initNotificationSystem() async {
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint("Gagal menginisialisasi sistem notifikasi: $e");
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  // Desain Beranda Utama asli JajahYuk yang ditambahkan fitur Badge Notifikasi
  Widget _buildHomeDashboard() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Foodies';

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Sapaan Pengguna Modern Asli JajahYuk
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bagian Teks Sapaan Asli
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $userName!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mau jajan kuliner apa hari ini?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white, // Menggunakan putih transparan lembut
                      ),
                    ),
                  ],
                ),
                
                // === FITUR BARU: TOMBOL LONCENG & BADGE NOTIFIKASI REALTIME ===
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                  child: StreamBuilder<QuerySnapshot>(
                    stream: NotificationService.getNotificationsStream(),
                    builder: (context, snapshot) {
                      // Menghitung jumlah dokumen di Firestore yang field 'read' bernilai false
                      final unreadCount = snapshot.data?.docs
                              .where((doc) => (doc.data() as Map<String, dynamic>)['read'] == false)
                              .length ??
                          0;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              'Petualangan Kuliner Terbaru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
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
                  return const Center(
                    child: Text('Belum ada review kuliner. Jadilah yang pertama!'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
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
      const SizedBox.shrink(), 
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentIndex == 0 
          ? null // AppBar bawaan disembunyikan hanya pada Dashboard Beranda agar banner custom deepOrange terlihat penuh
          : AppBar(
              title: Text(
                _currentIndex == 1 ? 'Kuliner Favorit' : 'Profil Saya',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                if (_currentIndex == 3)
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