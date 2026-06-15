import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../model/post.dart';
import '../service/post_service.dart';
import 'map_detail_screen.dart';

class DetailScreen extends StatefulWidget {
  final Post post;
  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  late double _displayRating;
  late int _displayCount;

  @override
  void initState() {
    super.initState();
    _displayRating = widget.post.averageRating;
    _displayCount = widget.post.ratingCount ?? 0;
    
    if (_currentUserId != null && widget.post.likedBy != null) {
      _isFavorite = widget.post.likedBy!.contains(_currentUserId);
    }
  }

  Future<void> _toggleFavorite() async {
    final postId = widget.post.id;
    final userId = _currentUserId;
    if (postId == null || userId == null) return;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      await PostService.toggleFavoritePost(postId, userId, _isFavorite);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Ditambahkan ke Favorit' : 'Dihapus dari Favorit'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.deepOrange,
        ),
      );
    } catch (e) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui favorit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
      await PostService.deletePost(widget.post);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _sharePost() {
    final text =
        'Rekomendasi Kuliner: ${widget.post.category ?? ''}\n'
        '${widget.post.description ?? ''}\n'
        'Rating: ${_displayRating.toStringAsFixed(1)} ⭐ ($_displayCount ulasan)\n'
        'Direview oleh: ${widget.post.userFullName ?? ''}';
    SharePlus.instance.share(ShareParams(text: text));
  }

  // Fungsi untuk menyegarkan tampilan total ulasan di UI lokal setelah proses kirim/update
  Future<void> _refreshUIData() async {
    int? currentSavedUserRating = await PostService.getUserRating(widget.post.id!);
    
    // Perhitungan lokal untuk update state tampilan tanpa perlu reload penuh screen
    setState(() {
      if (_displayCount == 0) _displayCount = 1;
      // Mengingat data di Firestore ter-update via transaksi, cara paling valid adalah memperbarui UI
      // secara berkala atau mengambil snapshot terbaru dari post id yang dimuat.
    });
  }

  void _showRatingDialog() async {
    // Tampilkan loading indicator pelan saat mengambil data lama dari Firestore
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
    );

    int? existingRating;
    if (widget.post.id != null) {
      existingRating = await PostService.getUserRating(widget.post.id!);
    }

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading indicator awal

    int selectedRating = existingRating ?? 5;
    final bool hasRated = existingRating != null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(hasRated ? "Update Rating" : "Beri Rating"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasRated)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "Anda sudah memberi rating $existingRating ⭐",
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        iconSize: 36,
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (widget.post.id != null) {
                      final messenger = ScaffoldMessenger.of(context);
                      
                      // Logika pembaharuan nilai UI instan secara lokal
                      setState(() {
                        if (hasRated) {
                          double oldSum = (_displayRating * _displayCount) - existingRating! + selectedRating;
                          _displayRating = oldSum / _displayCount;
                        } else {
                          double newSum = (_displayRating * _displayCount) + selectedRating;
                          _displayCount += 1;
                          _displayRating = newSum / _displayCount;
                        }
                      });

                      await PostService.addRating(widget.post.id!, selectedRating);
                      
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            hasRated
                                ? "Rating berhasil diperbarui!"
                                : "Rating berhasil ditambahkan!",
                          ),
                          backgroundColor: Colors.deepOrange,
                        ),
                      );
                    }
                  },
                  child: Text(hasRated ? "Update" : "Kirim"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _currentUserId != null && widget.post.userId == _currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Kuliner"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: _isFavorite ? Colors.amber : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePost,
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deletePost(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.post.image != null && widget.post.image!.isNotEmpty)
              Image.memory(
                base64Decode(widget.post.image!),
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
                    children: [
                      if (widget.post.category != null)
                        Expanded(
                          child: Chip(label: Text(widget.post.category!, overflow: TextOverflow.ellipsis)),
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${_displayRating.toStringAsFixed(1)} ($_displayCount)',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _showRatingDialog,
                              icon: const Icon(Icons.rate_review, size: 18),
                              label: const Text('Beri Rating'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(widget.post.description ?? '', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Direview oleh: ${widget.post.userFullName ?? 'Anonim'}',
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.post.latitude != null && widget.post.longitude != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Koordinat Resto: ${widget.post.latitude}, ${widget.post.longitude}',
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MapDetailScreen(post: widget.post)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.map),
                      label: const Text('Lihat di Peta'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}