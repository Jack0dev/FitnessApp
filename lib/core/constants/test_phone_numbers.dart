/// Firebase Test Phone Numbers for Development
/// These numbers work without billing and don't charge SMS fees
/// Verification code is always: 123456
class TestPhoneNumbers {
  /// All Firebase test phone numbers with their codes
  /// These are provided by Firebase for testing
  static const List<Map<String, String>> testNumbers = [
    {
      'number': '+16505553434',
      'formatted': '+1 650-555-3434',
      'code': '123456',
      'country': 'US',
    },
    {
      'number': '+16505551234',
      'formatted': '+1 650-555-1234',
      'code': '123456',
      'country': 'US',
    },
    {
      'number': '+16505554242',
      'formatted': '+1 650-555-4242',
      'code': '123456',
      'country': 'US',
    },
    {
      'number': '+16505555555',
      'formatted': '+1 650-555-5555',
      'code': '123456',
      'country': 'US',
    },
  ];

  /// Default test verification code for all test numbers
  static const String defaultTestCode = '123456';

  /// Get formatted test numbers list for display
  static List<String> getFormattedNumbers() {
    return testNumbers.map((test) => test['formatted']!).toList();
  }

  /// Get raw phone numbers (without formatting)
  static List<String> getRawNumbers() {
    return testNumbers.map((test) => test['number']!).toList();
  }

  /// Check if a phone number is a Firebase test number
  static bool isTestNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    return testNumbers.any((test) {
      final testNum = test['number']!;
      return cleaned == testNum || cleaned.contains(testNum.replaceAll('+1', ''));
    });
  }

  /// Get test number by index
  static String? getTestNumber(int index, {bool formatted = false}) {
    if (index >= 0 && index < testNumbers.length) {
      return formatted 
          ? testNumbers[index]['formatted']
          : testNumbers[index]['number'];
    }
    return null;
  }
}



