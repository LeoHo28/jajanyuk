import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../service/post_service.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  String _generateAvatarUrl(String? fullName) {
    final formattedName = (fullName ?? 'User').trim().replaceAll(' ', '+');
    return 'https://ui-avatars.com/api/?name=$formattedName&color=FFFFFF&background=FF5722&size=158';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Foodies"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bagian Header Profil (Warna Oranye Estetik)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        _generateAvatarUrl(currentUser?.displayName),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    currentUser?.displayName ?? 'Foodies',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    currentUser?.email ?? '-',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade100,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24.0),

            // Bagian Statistik Kontribusi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StreamBuilder(
                stream: PostService.getPostList(),
                builder: (context, snapshot) {
                  int totalReviews = 0;
                  if (snapshot.hasData && currentUser != null) {
                    // Menghitung jumlah post milik user yang sedang login
                    totalReviews = snapshot.data!
                        .where((post) => post.userId == currentUser!.uid)
                        .length;
                  }

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.rate_review,
                            value: '$totalReviews',
                            label: 'Total Review',
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          _buildStatItem(
                            icon: Icons.verified_user,
                            value: 'Kontributor',
                            label: 'Status Akun',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24.0),

            // Tombol Aksi / Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.restaurant, color: Colors.deepOrange),
                    title: const Text('Review Saya'),
                    subtitle: const Text('Lihat semua kuliner yang kamu ulas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Opsional: Bisa diarahkan ke list khusus review user
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Keluar Akun', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah kamu yakin ingin keluar dari aplikasi Foodies?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }
}