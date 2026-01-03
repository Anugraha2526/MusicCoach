import 'package:flutter/material.dart';

class GuitarTunerScreen extends StatelessWidget {
  const GuitarTunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Guitar Tuner',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF0A1929),
      body: const Center(
        child: Text(
          'Guitar Tuner Placeholder',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
