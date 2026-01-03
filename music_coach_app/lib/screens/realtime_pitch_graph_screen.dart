import 'package:flutter/material.dart';

class RealtimePitchGraphScreen extends StatelessWidget {
  const RealtimePitchGraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Pitch Graph'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Realtime Pitch Graph Placeholder'),
      ),
    );
  }
}
