import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    bool loggedIn = await AuthService.isLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });
    
    // If not logged in, go back
    if (!loggedIn) {
      Navigator.pop(context);
    }
  }

  void handleChangePassword() async {
    // Double check authentication
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to change password')),
      );
      return;
    }

    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool success = await AuthService.changePassword(oldPassword, newPassword);

    setState(() {
      isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully')),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully')),
      );
      // Navigate to Main Layout (Home) to restore bottom nav
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Old password is incorrect or an error occurred')),
      );
    }
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Design System Colors
    final Color backgroundColor = const Color(0xFF0F172A);
    final Color primaryAccent = const Color(0xFF4FA2FF);
    final Color primaryText = const Color(0xFFFFFFFF);
    final Color secondaryText = const Color(0xFF848484);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Change Password', style: TextStyle(color: primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                style: TextStyle(color: primaryText),
                decoration: InputDecoration(
                  labelText: 'Old Password',
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
                  prefixIcon: Icon(Icons.lock_outline, color: secondaryText),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                style: TextStyle(color: primaryText),
                decoration: InputDecoration(
                  labelText: 'New Password',
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
                  prefixIcon: Icon(Icons.lock, color: secondaryText),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: TextStyle(color: primaryText),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
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
                  prefixIcon: Icon(Icons.check, color: secondaryText),
                ),
              ),
              SizedBox(height: 32),
              isLoading
                  ? CircularProgressIndicator(color: primaryAccent)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
