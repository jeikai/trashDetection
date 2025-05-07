import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/models/detection_result.dart';

class ApiService {
  late final Dio _dio;
  final String _baseUrl = AppConstants.baseUrl;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Duration(milliseconds: AppConstants.connectionTimeout),
      receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) {
        // Custom log print function to avoid truncation of base64 data
        // Only print the first part of the response body if it's too long
        if (obj.toString().length > 200 && obj.toString().contains('base64')) {
          print('${obj.toString().substring(0, 200)}... [truncated]');
        } else {
          print(obj);
        }
      },
    ));
  }

  Future<DetectionResponse> detectFromImages(List<File> images) async {
    try {
      FormData formData = FormData();

      // Using the field name expected by the backend (should match the Node.js req.files)
      for (int i = 0; i < images.length; i++) {
        formData.files.add(
          MapEntry(
            'images', // This should match what the Node.js backend expects
            await MultipartFile.fromFile(
              images[i].path,
              filename: 'image_$i.jpg',
            ),
          ),
        );
      }

      final response = await _dio.post(
        '/image', // Matches backend route
        data: formData,
      );

      if (response.statusCode == 200) {
        // Parse the response which should include base64 images
        print("Response received with status 200");
        return _parseResponse(response.data);
      } else {
        throw Exception('Failed to process images: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      print("Error in detectFromImages: $e");
      throw Exception('Failed to process images: $e');
    }
  }

  Future<DetectionResponse> analyzeVideo(File videoFile) async {
    try {
      // Create a multipart form data with Dio
      FormData formData = FormData();
      formData.files.add(
        MapEntry(
          'video', // Matches backend parameter name
          await MultipartFile.fromFile(
            videoFile.path,
            filename: 'video.mp4',
          ),
        ),
      );

      final response = await _dio.post(
        '/video', // Matches backend route
        data: formData,
      );

      if (response.statusCode == 200) {
        // Parse the response which should include base64 images from video frames
        print("Video analysis response received with status 200");
        return _parseResponse(response.data);
      } else {
        throw Exception('Failed to analyze video: ${response.statusCode}');
      }
    } catch (e) {
      print('Error analyzing video: $e');
      if (e is DioException) {
        throw _handleDioError(e);
      }
      throw Exception('Failed to analyze video: $e');
    }
  }

  Future<DetectionResponse> processVideoFrame(File frameImage) async {
    try {
      FormData formData = FormData();
      formData.files.add(
        MapEntry(
          'images', // Field name expected by the Node.js backend
          await MultipartFile.fromFile(
            frameImage.path,
            filename: 'frame.jpg',
          ),
        ),
      );

      final response = await _dio.post(
        '/image', // Matches backend route
        data: formData,
      );

      if (response.statusCode == 200) {
        // Parse the response which should include base64 images
        print("Frame processing response received with status 200");
        return _parseResponse(response.data);
      } else {
        throw Exception(
            'Failed to process video frame: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to process video frame: $e');
    }
  }

  // Helper method to parse API responses
  DetectionResponse _parseResponse(dynamic data) {
    // Check if the response is a string (some APIs might return plain text)
    if (data is String) {
      try {
        // Try to parse as JSON first
        Map<String, dynamic> jsonData = json.decode(data);
        return DetectionResponse.fromJson(jsonData);
      } catch (e) {
        // If not JSON, just use the string as a message
        return DetectionResponse.fromMessage(data);
      }
    }
    // Already a Map (Dio usually converts JSON responses to maps)
    else if (data is Map<String, dynamic>) {
      return DetectionResponse.fromJson(data);
    }
    // Fallback for unexpected response types
    else {
      return DetectionResponse.fromMessage('Unexpected response format');
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception(
          'Connection timeout. Please check your internet connection.');
    } else if (e.type == DioExceptionType.badResponse) {
      // Try to extract more detailed error message if available
      String errorMsg = 'Server error: ${e.response?.statusCode}';
      if (e.response?.data != null) {
        if (e.response!.data is String) {
          errorMsg += ' - ${e.response!.data}';
        } else if (e.response!.data is Map && e.response!.data['message'] != null) {
          errorMsg += ' - ${e.response!.data['message']}';
        }
      }
      return Exception(errorMsg);
    } else if (e.type == DioExceptionType.cancel) {
      return Exception('Request cancelled');
    } else {
      return Exception('Network error: ${e.message}');
    }
  }
}