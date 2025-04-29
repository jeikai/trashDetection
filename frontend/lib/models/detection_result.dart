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
      confidence: (json['confidence'] != null) ? (json['confidence'] * 1.0) : 0.0,
      boundingBox: json['bounding_box'],
    );
  }
}

class DetectionResponse {
  final List<DetectionResult> results;
  final String? processedImageUrl;
  final String message;

  DetectionResponse({
    required this.results,
    this.processedImageUrl,
    required this.message,
  });

  factory DetectionResponse.fromJson(Map<String, dynamic> json) {
    List<DetectionResult> resultsList = [];
    if (json['results'] != null && json['results'] is List) {
      resultsList = (json['results'] as List)
          .map((item) => DetectionResult.fromJson(item))
          .toList();
    }

    return DetectionResponse(
      results: resultsList,
      processedImageUrl: json['processed_image_url'],
      message: json['message'] ?? 'Detection completed',
    );
  }

  // Helper method for when backend returns simple string responses
  factory DetectionResponse.fromMessage(String message) {
    return DetectionResponse(
      results: [],
      processedImageUrl: null,
      message: message,
    );
  }
}