import 'package:geolocator/geolocator.dart';

/// Service for getting GPS location
class LocationService {
  /// Ensure location service & permission are ready
  /// Return true if OK, false if cannot use location.
  Future<bool> _ensureServiceAndPermission() async {
    // 1. Kiểm tra Location Service đã bật chưa
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[LocationService] Location services are disabled.');
      // Có thể gợi ý mở settings (optional):
      // await Geolocator.openLocationSettings();
      return false;
    }

    // 2. Kiểm tra quyền hiện tại
    LocationPermission permission = await Geolocator.checkPermission();
    print('[LocationService] Current permission: $permission');

    if (permission == LocationPermission.denied) {
      // 3.1. Nếu denied → request lại → trigger popup xin quyền
      permission = await Geolocator.requestPermission();
      print('[LocationService] Permission after request: $permission');

      if (permission == LocationPermission.denied) {
        print('[LocationService] Location permissions are denied by user.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 3.2. deniedForever → chỉ có thể mở App Settings
      print('[LocationService] Location permissions are permanently denied.');
      // Optional: mở App Settings cho user tự bật lại
      // await Geolocator.openAppSettings();
      return false;
    }

    // Các trạng thái còn lại: whileInUse hoặc always → OK
    return true;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permissions
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permissions
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position
  /// Returns null if permission denied or location unavailable
  Future<Position?> getCurrentPosition() async {
    try {
      final ok = await _ensureServiceAndPermission();
      if (!ok) {
        // Không dùng được location (dịch vụ tắt / user từ chối)
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('[LocationService] Got position: '
          '${position.latitude}, ${position.longitude}');

      return position;
    } catch (e) {
      print('[LocationService] Error getting current position: $e');
      return null;
    }
  }

  /// Get current location as Map with latitude and longitude
  Future<Map<String, double>?> getCurrentLocation() async {
    final position = await getCurrentPosition();
    if (position == null) {
      return null;
    }

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }
}
