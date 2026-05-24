import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../model/post.dart';
import '../service/post_service.dart';
import 'map_detail_screen.dart'; // Pastikan file ini sudah dibuat untuk menampilkan map

class DetailScreen extends StatelessWidget {
  final Post post;
  const DetailScreen({super.key, required this.post});

  // Fungsi untuk menampilkan konfirmasi sebelum menghapus postingan
  Future<void> _deletePost(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Review'),
        content: const Text('Apakah kamu yakin ingin menghapus review kuliner ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PostService.deletePost(post);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _sharePost() {
    final text = 'Rekomendasi Kuliner: ${post.category ?? ''}\n'
        '${post.description ?? ''}\n'
        'Rating: ${post.rating ?? 5.0} ⭐\n'
        'Direview oleh: ${post.userFullName ?? ''}';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId != null && post.userId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Kuliner"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePost,
            tooltip: 'Bagikan',
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Hapus',
              onPressed: () => _deletePost(context),
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menampilkan Foto dengan penanganan error gambar rusak
            if (post.image != null && post.image!.isNotEmpty)
              Image.memory(
                base64Decode(post.image!),
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 250,
                  child: Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (post.category != null) Chip(label: Text(post.category!)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${post.rating ?? 5.0}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.description ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Direview oleh: ${post.userFullName ?? 'Anonim'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  
                  // Bagian Koordinat & Tombol Peta Kuliner
                  if (post.latitude != null && post.longitude != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Koordinat Resto: ${post.latitude}, ${post.longitude}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapDetailScreen(post: post),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.map),
                      label: const Text('Lihat di Peta'),
                    ),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}