import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/sign_in_screen.dart';

void main() async {
  // Memastikan binding Flutter sudah siap sebelum inisialisasi Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase dengan opsi platform saat ini (Android/iOS/Web)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Review Tracker',
      debugShowCheckedModeBanner: false,
      
      // Mengatur Tema Warna Aplikasi biar bernuansa Kuliner (Deep Orange)
      theme: ThemeData(
        useMaterialDesign: true,
        primarySwatch: Colors.deepOrange,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrange,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      
      // Pengecekan Otomatis: Jika user sudah login langsung ke Home, jika belum ke Sign In
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika Firebase masih loading memeriksa status login
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            ),
          );
        }
        
        // Jika ada data user (artinya sudah pernah login)
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        
        // Jika belum login atau sudah logout
        return const SignInScreen();
      },
    );
  }
}