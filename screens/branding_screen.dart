import 'package:flutter/material.dart';

class BrandingScreen extends StatelessWidget {
  const BrandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('브랜딩'),
      ),
      body: const Center(
        child: Text('브랜딩 화면'),
      ),
    );
  }
} 