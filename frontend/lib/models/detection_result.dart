import 'dart:convert';

class DetectionResult {
  final String objectType;
  final String recyclableCategory;
  final double confidence;
  final Map<String, dynamic>? boundingBox;

  DetectionResult({
    required this.objectType,
    required this.recyclableCategory,
    required this.confidence,
    this.boundingBox,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      objectType: json['object_type'] ?? 'Unknown',
      recyclableCategory: json['recyclable_category'] ?? 'Unknown',
      confidence: json['confidence'] != null ? (json['confidence'] * 1.0) : 0.0,
      boundingBox: json['bounding_box'],
    );
  }
}

class DetectionResponse {
  final String message;
  final List<String> imageBase64;
  final List<DetectionResult> results;

  DetectionResponse({
    required this.message,
    required this.imageBase64,
    this.results = const [],
  });

  factory DetectionResponse.fromJson(Map<String, dynamic> json) {
    // Handle images field - it contains base64 image data
    List<String> imagesList = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        // Handle when images is a list of base64 strings
        imagesList = List<String>.from(json['images']);
      } else if (json['images'] is String) {
        // Handle when 'images' is a single base64 string
        imagesList = [json['images']];
      }
    }

    // Handle results if they exist in the response
    List<DetectionResult> resultsList = [];
    if (json['results'] != null && json['results'] is List) {
      resultsList = List<DetectionResult>.from(
        json['results'].map((result) => DetectionResult.fromJson(result)),
      );
    }

    return DetectionResponse(
      message: json['message'] ?? '',
      imageBase64: imagesList,
      results: resultsList,
    );
  }

  // Helper method for when backend returns simple string responses
  factory DetectionResponse.fromMessage(String message) {
    return DetectionResponse(
      message: message,
      imageBase64: [],
    );
  }
}