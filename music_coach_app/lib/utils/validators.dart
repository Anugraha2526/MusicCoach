class Validators {
  static String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain at least one number.';
    }
    if (!RegExp(r'''[!@#\$%\^&\*\(\)_\+\-\=\{\}\[\]\|;:'",\.<>\/\?]''').hasMatch(password)) {
      return 'Password must contain at least one special character.';
    }
    return null; // Null means validation passed
  }
}
