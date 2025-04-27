import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Navigate to Login Page after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login'); // Using named route
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set Status Bar Color to Transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF2E3B8C), // Dark blue background
      body: Stack(
        children: [
          // Side design positioned at the top-right
          Align(
            alignment: Alignment.topRight,
            child: Image.asset(
              'assets/logo_sidedesign.png',
              width: MediaQuery.of(context).size.width * 0.6, // Adjust size
              fit: BoxFit.cover,
            ),
          ),
          // Centered logo
          Center(
            child: Image.asset(
              'assets/logo.png',
              width: 150, // Adjust size as needed
            ),
          ),
        ],
      ),
    );
  }
}
