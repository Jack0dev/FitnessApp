import 'dart:math' as math;

/// Configuration for gym location (temporary for demo)
/// TODO: Move to database or settings later
class GymLocationConfig {
  // Tọa độ phòng gym (tạm thời lưu ở đây để demo)
  // Có thể cập nhật sau khi có thông tin thực tế
  static const double gymLatitude = 10.800000; // Vĩ độ phòng gym
  static const double gymLongitude = 106.700000; // Kinh độ phòng gym
  
  // Bán kính cho phép (mét) - PT phải ở trong bán kính này để check-in/check-out hợp lệ
  static const double maxDistanceMeters  = 100.0; // 100 mét
  
  /// Get gym location as Map
  static Map<String, double> getGymLocation() {
    return {
      'latitude': gymLatitude,
      'longitude': gymLongitude,
    };
  }
  
  /// Check if a location is within allowed radius from gym
  /// Returns true if within radius, false otherwise
  static bool isWithinRadius(double latitude, double longitude) {
    final distance = calculateDistance(
      gymLatitude,
      gymLongitude,
      latitude,
      longitude,
    );
    return distance <= maxDistanceMeters;
  }
  
  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }
  
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
  
  /// Get distance in meters from gym location
  /// Returns distance in meters, or null if location is null
  static double? getDistanceFromGym(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return null;
    }
    return calculateDistance(gymLatitude, gymLongitude, latitude, longitude);
  }
}

