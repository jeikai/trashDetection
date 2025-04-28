class AppStrings {
  // App title
  static const String appName = 'Recyclable Trash Detector';

  // Home Screen
  static const String homeTitle = 'Recyclable Trash Detector';
  static const String pictureMode = 'Picture Mode';
  static const String scanMode = 'Scan Mode';
  static const String helpButtonLabel = '?';
  static const String helpTitle = 'How to Use';

  // Picture Mode Screen
  static const String pictureModeTitle = 'Picture Mode';
  static const String dragAndDropText = 'Drag & Drop Images Here';
  static const String selectFilesButton = 'Select Files';
  static const String takePhotoButton = 'Take Photo';
  static const String submitButton = 'Submit';
  static const String homeButton = 'Home';
  static const String scanModeButton = 'Scan Mode';
  static const String pictureModeHelp = 'Upload or take photos of trash items to classify them. You can select multiple images at once.';

  // Scan Mode Screen
  static const String scanModeTitle = 'Scan Mode';
  static const String targetObjectText = 'Please target at your object';
  static const String processingVideo = 'Processing video...';
  static const String detectionResults = 'Detection Results';
  static const String retryButton = 'Retry';
  static const String itemsDetected = 'items detected';
  static const String cameraPermission = 'Camera Permission';
  static const String cameraPermissionRequest = 'This app needs camera access to scan trash items';
  static const String scanModeHelp = 'Point your camera at trash items for real-time detection. Hold steady for best results.';

  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String cameraError = 'Failed to initialize camera. Please try again.';
  static const String permissionDenied = 'Permission denied. Cannot proceed without required permissions.';
  static const String noImagesSelected = 'Please select at least one image.';
}