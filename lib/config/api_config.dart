// lib/config/api_config.dart
class ApiConfig {
  // Development URL - change this to your actual backend URL
  static const String baseUrl = 'http://localhost:3001/api';
  
  // Production URL (uncomment when deploying)
  // static const String baseUrl = 'https://api.explorelesotho.com/api';
  
  // Timeout settings
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}