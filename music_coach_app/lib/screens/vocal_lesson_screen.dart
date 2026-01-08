import 'package:flutter/material.dart';

class VocalLessonScreen extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const VocalLessonScreen({super.key, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: onBackPressed == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (onBackPressed != null) {
          onBackPressed!();
        }
      },
      child: Scaffold(
        appBar: AppBar(
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (onBackPressed != null) {
              onBackPressed!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text(
          'Vocal Lessons',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF0A1929),
      body: const Center(
        child: Text(
          'Vocal Lesson Placeholder',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      ),
    );
  }
}
