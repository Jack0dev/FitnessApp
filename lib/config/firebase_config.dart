import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConfig {
  /// Get emulator host - use 10.0.2.2 for Android emulator, localhost for others
  static String get _emulatorHost {
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return '10.0.2.2';
    }
    // iOS simulator, desktop, or web can use localhost
    return 'localhost';
  }

  /// Initialize Firebase
  /// [useEmulator] - Set to true to connect to Firebase Emulator for development
  static Future<void> initialize({bool useEmulator = false}) async {
    await Firebase.initializeApp();
    
    // Set default language code to avoid "Ignoring header X-Firebase-Locale" warning
    // Use device locale or default to 'en'
    try {
      await FirebaseAuth.instance.setLanguageCode('en');
    } catch (e) {
      // Ignore if language code cannot be set
      print('Note: Could not set Firebase Auth language code: $e');
    }
    
    // Note: Firestore will automatically enable offline persistence on mobile
    // The "Failed to resolve name" warnings from ManagedChannelImpl (gRPC) are harmless
    // and occur when Firestore tries to establish connections. They don't affect functionality.
    
    // Connect to Firebase Emulator (chỉ khi có flag USE_EMULATOR=true)
    if (useEmulator) {
      final host = _emulatorHost;
      
      // Connect Authentication Emulator
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      
      // Connect Firestore Emulator
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8081);
      
      print('🔧 Connected to Firebase Emulator');
      print('   - Host: $host (${Platform.isAndroid ? "Android Emulator" : "Other Platform"})');
      print('   - Authentication: http://$host:9099');
      print('   - Firestore: http://$host:8081');
      print('   - Emulator UI: http://localhost:4000');
    } else {
      print('✅ Connected to Firebase Production');
      print('   - Using real Firebase services');
      print('   - Phone Authentication will use real SMS (or test numbers if configured)');
    }
  }
}

