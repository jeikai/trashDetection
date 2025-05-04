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
      confidence:
          (json['confidence'] != null) ? (json['confidence'] * 1.0) : 0.0,
      boundingBox: json['bounding_box'],
    );
  }
}

class DetectionResponse {
  final String message;
  final List<String> images;

  DetectionResponse({
    required this.message,
    required this.images,
  });

  factory DetectionResponse.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = List<String>.from(json['images']);
    }

    return DetectionResponse(
      message: json['message'],
      images: imagesList,
    );
  }

  // Helper method for when backend returns simple string responses
  factory DetectionResponse.fromMessage(String message) {
    return DetectionResponse(
      message: message,
      images: [],
    );
  }
}
