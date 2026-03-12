import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import 'vocal_pitch_calibration_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoggedIn = false;
  bool isLoading = true;
  bool isUpdating = false;

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  double? _naturalPitch;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // -------------------- Check if user is logged in --------------------
  void _checkLoginStatus() async {
    bool loggedIn = await AuthService.isLoggedIn();

    if (loggedIn) {
      // Fetch profile from backend
      final profile = await AuthService.fetchProfile();
      if (profile != null) {
        usernameController.text = profile['username'] ?? '';
        emailController.text = profile['email'] ?? '';
        _naturalPitch = profile['natural_pitch'];
      }
    }

    setState(() {
      isLoggedIn = loggedIn;
      isLoading = false;
    });
  }

  // -------------------- Update profile --------------------
  void handleUpdateProfile() async {
    // Safety check - should not happen as button is hidden when not logged in
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to update profile')),
      );
      return;
    }

    setState(() => isUpdating = true);
    bool success = await AuthService.updateProfile(
      usernameController.text.trim(),
      emailController.text.trim(),
    );
    setState(() => isUpdating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Profile updated successfully'
            : 'Failed to update profile'),
      ),
    );
  }

  String _midiToName(double freqHz) {
    if (freqHz <= 0) return '?';
    double midi = 69 + 12 * (math.log(freqHz / 440.0) / math.ln2);
    List<String> notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'];
    int m = midi.round();
    int noteIndex = m % 12;
    int octave = (m ~/ 12) - 1;
    return '${notes[noteIndex]}$octave';
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // -------------------- Logout --------------------
  void handleLogout() async {
    await AuthService.logout();
    setState(() {
      isLoggedIn = false;
    });
    // Navigate to Landing Screen after logout
    Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Design System Colors
    final Color backgroundColor = const Color(0xFF0F172A);
    final Color primaryAccent = const Color(0xFF4FA2FF);
    final Color primaryText = const Color(0xFFFFFFFF);
    final Color secondaryText = const Color(0xFF848484);

    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          title: Text('Profile', style: TextStyle(color: primaryText)),
          centerTitle: true,
          iconTheme: IconThemeData(color: primaryText),
        ),
        body: Center(child: CircularProgressIndicator(color: primaryAccent)),
      );
    }

    // -------------------- Not logged in --------------------
    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          title: Text('Profile', style: TextStyle(color: primaryText)),
          centerTitle: true,
          iconTheme: IconThemeData(color: primaryText),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Please login to view profile',
                style: TextStyle(color: secondaryText, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    // -------------------- Logged in --------------------
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text('Profile', style: TextStyle(color: primaryText)),
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, size: 60, color: primaryAccent),
            ),
            const SizedBox(height: 32),

            // Username
            TextField(
              controller: usernameController,
              style: TextStyle(color: primaryText),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: secondaryText),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: secondaryText.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 16),

            // Email
            TextField(
              controller: emailController,
              style: TextStyle(color: primaryText),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: secondaryText),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: secondaryText.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 16),
            
            // Natural Pitch Display
            InkWell(
              onTap: () {
                 if (!isLoggedIn) return;
                 Navigator.push(
                    context,
                    MaterialPageRoute(
                       builder: (context) => VocalPitchCalibrationScreen(
                          onCalibrationComplete: (double pitchHz) async {
                             // Save to backend
                             await AuthService.updateProfile(
                                usernameController.text.trim(),
                                emailController.text.trim(),
                                naturalPitch: pitchHz,
                             );
                             // Update local state and pop
                             setState(() {
                                _naturalPitch = pitchHz;
                             });
                             Navigator.pop(context);
                             ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Natural pitch updated successfully!')),
                             );
                          },
                       ),
                    ),
                 );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.05),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: secondaryText.withOpacity(0.5)),
                ),
                child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Text('Natural Pitch', style: TextStyle(color: secondaryText, fontSize: 16)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                           _naturalPitch != null ? '${_naturalPitch!.toStringAsFixed(1)} Hz (${_midiToName(_naturalPitch!)})' : 'Not Calibrated',
                           textAlign: TextAlign.right,
                           style: TextStyle(
                              color: _naturalPitch != null ? const Color(0xFFE93B81) : secondaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                           ),
                        ),
                      ),
                   ]
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            isUpdating
                ? CircularProgressIndicator(color: primaryAccent)
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: handleUpdateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Update Profile'),
                    ),
                  ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/change-password');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryText,
                  side: BorderSide(color: secondaryText),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Change Password'),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: handleLogout,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
