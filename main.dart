import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'constants/colors.dart';

void main() {
  runApp(const BusinessPhotoApp());
}

class BusinessPhotoApp extends StatelessWidget {
  const BusinessPhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '비즈니스 포토',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
} 