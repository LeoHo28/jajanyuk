import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/post_service.dart'; 
import '../service/notification_service.dart'; // Import service notifikasi

class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final String? postOwnerId; // Menampung ID pemilik postingan

  const CommentBottomSheet({
    super.key,
    required this.postId,
    this.postOwnerId, // Dioper dari detail screen
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _popupTextFieldController = TextEditingController();
  bool _isLoading = false; // Variabel pengunci untuk mencegah bug double submit

  @override
  void dispose() {
    _popupTextFieldController.dispose();
    super.dispose();
  }

  Future<void> _submitNewComment() async {
    final text = _popupTextFieldController.text.trim();
    
    // Jika teks kosong atau sedang dalam proses pengiriman, batalkan aksi tambahan
    if (text.isEmpty || _isLoading) return; 

    setState(() {
      _isLoading = true; // Kunci tombol dan textfield segera
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final username = user?.displayName ?? user?.email?.split('@')[0] ?? "Anonim";
      final userId = user?.uid ?? "unknown";

      // 1. Menyimpan komentar ke sub-koleksi postingan kuliner asli
      await PostService.addComment(widget.postId, {
        "userId": userId,
        "username": username,
        "text": text,
      });

      // Bersihkan teks input segera setelah tersimpan di database
      _popupTextFieldController.clear();

      // 2. Mengirim Notifikasi ke pemilik postingan
      // Notifikasi dikirim HANYA JIKA yang berkomentar bukan pemilik postingan itu sendiri
      if (widget.postOwnerId != null && userId != widget.postOwnerId) {
        await NotificationService.createNotificationToFirestore(
          title: 'Komentar Baru dari $username! 💬',
          body: text,
          type: 'comment',
          targetUserId: widget.postOwnerId!, // Mengirimkan target ke ID pemilik post
        );
      }
    } catch (e) {
      log("Gagal mengirim komentar: $e");
    } finally {
      // Pastikan widget masih aktif sebelum mengubah state kembali
      if (mounted) {
        setState(() {
          _isLoading = false; // Buka kembali kunci input setelah semua proses selesai
        });
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Komentar"),
        content: const Text("Apakah Anda yakin ingin menghapus komentar ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PostService.deleteComment(widget.postId, commentId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Komentar berhasil dihapus")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus komentar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // --- HEADER POP-UP ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Komentar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- DAFTAR KOMENTAR ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: PostService.getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Gagal memuat komentar."));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Belum ada komentar.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final comments = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const Divider(height: 20),
                  itemBuilder: (context, index) {
                    final commentData = comments[index].data() as Map<String, dynamic>;
                    final commentId = comments[index].id;
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isOwner = commentData["userId"] == currentUser?.uid;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                commentData["username"] ?? "Anonim",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                commentData["text"] ?? "",
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () => _deleteComment(commentId),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            tooltip: "Hapus komentar",
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // --- KOLOM INPUT ---
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _popupTextFieldController,
                      enabled: !_isLoading, // Otomatis disable input jika sedang loading proses kirim sebelumnya
                      decoration: InputDecoration(
                        hintText: _isLoading ? "Mengirim komentar..." : "Tuliskan komentar anda disini",
                        hintStyle: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: _submitNewComment,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}