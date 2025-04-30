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
    ));
  }

  Future<DetectionResponse> detectFromImages(List<File> images) async {
    try {
      FormData formData = FormData();

      // Add all images to the form data with field name 'images'
      for (int i = 0; i < images.length; i++) {
        formData.files.add(
          MapEntry(
            'images',
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
        return DetectionResponse(
          results: [], // Empty results since backend doesn't return detection data yet
          message: response.data.toString(),
        );
      } else {
        throw Exception('Failed to process images: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to process images: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeVideo(File videoFile) async {
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
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else {
          // Convert string response to map if needed
          return {'message': response.data.toString()};
        }
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
          'images', // Using 'images' to match backend naming
          await MultipartFile.fromFile(
            frameImage.path,
            filename: 'frame.jpg',
          ),
        ),
      );

      final response = await _dio.post(
        '/image', // Using '/image' endpoint for frame processing
        data: formData,
      );

      if (response.statusCode == 200) {
        return DetectionResponse(
          results: [], // Empty results as backend doesn't return detection data
          message: response.data.toString(),
        );
      } else {
        throw Exception('Failed to process video frame: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to process video frame: $e');
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception(
          'Connection timeout. Please check your internet connection.');
    } else if (e.type == DioExceptionType.badResponse) {
      return Exception('Server error: ${e.response?.statusCode}');
    } else if (e.type == DioExceptionType.cancel) {
      return Exception('Request cancelled');
    } else {
      return Exception('Network error: ${e.message}');
    }
  }
}