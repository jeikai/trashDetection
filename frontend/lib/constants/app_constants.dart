class AppConstants {
  // API endpoint
  static const String baseUrl = 'http://localhost:7810/';
  static const String detectEndpoint = '/detect';
  static const String streamEndpoint = '/stream';

  // Timeouts
  static const int connectionTimeout = 30000;  // 30 seconds
  static const int receiveTimeout = 30000;     // 30 seconds

  // Camera settings
  static const int scanDuration = 7;  // 7 seconds for video stream
  static const int preparationTime = 3;  // 3 seconds for preparation
  static const int resultDisplayTime = 5;  // 5 seconds to display results

  // Image settings
  static const int maxImageSize = 10 * 1024 * 1024;  // 10MB
  static const int maxImageCount = 5;
}