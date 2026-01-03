import 'package:flutter/material.dart';

class PianoLessonScreen extends StatelessWidget {
  const PianoLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piano Lessons'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Piano Lesson Placeholder'),
      ),
    );
  }
}
