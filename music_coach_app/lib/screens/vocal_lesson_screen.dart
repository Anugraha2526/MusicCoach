import 'package:flutter/material.dart';

class VocalLessonScreen extends StatelessWidget {
  const VocalLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocal Lessons'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Vocal Lesson Placeholder'),
      ),
    );
  }
}
