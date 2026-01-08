import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
