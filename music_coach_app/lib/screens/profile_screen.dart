import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  // Simulate login state for now
  final bool isLoggedIn = false; // Change to true when implementing auth

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isLoggedIn
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 40),
                  ),
                  SizedBox(height: 10),
                  Text('User Name'),
                  Text('user@example.com'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to update profile
                    },
                    child: Text('Update Profile'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to change password
                    },
                    child: Text('Change Password'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Logout logic
                    },
                    child: Text('Logout'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Login screen
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text('Login'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Sign Up screen
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: Text('Sign Up'),
                  ),
                ],
              ),
      ),
    );
  }
}
