import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../model/post.dart';
import '../service/post_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _base64Image;
  String? _latitude;
  String? _longitude;
  String? _category;
  double _selectedRating = 5.0; 
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  List<String> get categories {
    return [
      'Makanan Berat (Resto/Warung)',
      'Cemilan & Street Food',
      'Minuman & Coffee Shop',
      'Dessert & Bakery',
      'Kuliner Pedas',
    ];
  }

  Future<void> pickImageAndConvert() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _isGettingLocation = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Layanan lokasi HP dinonaktifkan.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Izin lokasi ditolak.")),
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil lokasi restoran.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _showCategorySelect() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: categories.map((cat) {
            return ListTile(
              title: Text(cat),
              onTap: () {
                setState(() {
                  _category = cat;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tulis Review Kuliner"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_base64Image == null)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('Belum ada foto makanan'),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(base64Decode(_base64Image!), height: 180, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : pickImageAndConvert,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Pilih Foto Kuliner'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _showCategorySelect,
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Pilih Kategori Makanan'),
            ),
            const SizedBox(height: 8),
            Text(
              _category ?? 'Belum memilih kategori',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.amber.shade50,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Berikan Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<double>(
                      value: _selectedRating,
                      items: [5.0, 4.0, 3.0, 2.0, 1.0].map((val) {
                        return DropdownMenuItem(value: val, child: Text('$val Bintang'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRating = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ulasan Rasa / Review',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: (_isSubmitting || _isGettingLocation) ? null : _getLocation,
              icon: const Icon(Icons.pin_drop),
              label: Text(_isGettingLocation ? 'Mendeteksi...' : 'Kunci Lokasi Warung/Resto'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () async {
                if (_base64Image == null || _category == null || _descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lengkapi foto, kategori, dan ulasan!')),
                  );
                  return;
                }
                setState(() => _isSubmitting = true);
                try {
                  if (_latitude == null) await _getLocation();
                  
                  await PostService.addPost(Post(
                    image: _base64Image,
                    description: _descriptionController.text,
                    category: _category,
                    ratingSum: _selectedRating, 
                    ratingCount: 1,            
                    latitude: _latitude,
                    longitude: _longitude,
                    userId: FirebaseAuth.instance.currentUser?.uid,
                    userFullName: FirebaseAuth.instance.currentUser?.displayName,
                    likedBy: const [],         
                  ));
                  
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                } finally {
                  setState(() => _isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
              child: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Review Kuliner'),
            ),
          ],
        ),
      ),
    );
  }
}