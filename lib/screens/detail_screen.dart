import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../model/post.dart';
import '../service/post_service.dart';

class DetailScreen extends StatelessWidget {
  final Post post;
  const DetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == post.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Kuliner"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              SharePlus.instance.share(ShareParams(
                text: 'Rekomendasi Kuliner: ${post.category}\n${post.description}\nRating: ${post.rating} ⭐',
              ));
            },
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                await PostService.deletePost(post);
                if (context.mounted) Navigator.pop(context);
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.image != null)
              Image.memory(base64Decode(post.image!), width: double.infinity, height: 250, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Chip(label: Text(post.category ?? 'Kuliner')),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${post.rating ?? 5.0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.description ?? '', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Direview oleh: ${post.userFullName ?? 'Anonim'}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  if (post.latitude != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.map, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Koordinat Resto: ${post.latitude}, ${post.longitude}', style: const TextStyle(color: Colors.grey)),
                      ],
                    )
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