import 'package:flutter/material.dart';

class EditScreen extends StatelessWidget {
  const EditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 편집'),
      ),
      body: const Center(
        child: Text('사진 편집 화면'),
      ),
    );
  }
} 