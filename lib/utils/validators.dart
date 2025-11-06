class Validators {
  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }

  /// Validate phone number (with country code)
  /// Format: +84123456789 or +841234567890
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces and special characters except +
    final cleaned = value.replaceAll(RegExp(r'[\s-()]'), '');
    
    // Check if starts with + and has at least 10 digits
    final phoneRegex = RegExp(r'^\+[1-9]\d{9,14}$');
    
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid phone number with country code (e.g., +84123456789)';
    }
    
    return null;
  }

  /// Format phone number to include country code if missing
  /// Default to Vietnam (+84) if no country code provided
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If starts with +, return as is
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    
    // Remove leading zeros
    final withoutZeros = cleaned.replaceFirst(RegExp(r'^0+'), '');
    
    // If starts with 84, add +
    if (withoutZeros.startsWith('84')) {
      return '+$withoutZeros';
    }
    
    // Default to Vietnam country code (+84)
    return '+84$withoutZeros';
  }

  /// Validate OTP code
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Verification code is required';
    }
    
    if (value.length != 6) {
      return 'Verification code must be 6 digits';
    }
    
    final otpRegex = RegExp(r'^[0-9]{6}$');
    
    if (!otpRegex.hasMatch(value)) {
      return 'Verification code must contain only numbers';
    }
    
    return null;
  }
}

