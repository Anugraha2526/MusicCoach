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

  // -------------------- Logout --------------------
  void handleLogout() async {
    await AuthService.logout();
    setState(() {
      isLoggedIn = false;
    });
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // -------------------- Not logged in --------------------
    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Text('Login'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      );
    }

    // -------------------- Logged in --------------------
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            isUpdating
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: handleUpdateProfile,
                    child: Text('Update Profile'),
                  ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/change-password');
              },
              child: Text('Change Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleLogout,
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
