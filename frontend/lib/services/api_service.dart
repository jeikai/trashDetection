import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/models/detection_result.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
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
        AppConstants.detectEndpoint,
        data: formData,
      );

      return DetectionResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to process images: $e');
    }
  }

  Future<DetectionResponse> processVideoFrame(File frameImage) async {
    try {
      FormData formData = FormData();
      formData.files.add(
        MapEntry(
          'frame',
          await MultipartFile.fromFile(
            frameImage.path,
            filename: 'frame.jpg',
          ),
        ),
      );

      final response = await _dio.post(
        AppConstants.streamEndpoint,
        data: formData,
      );

      return DetectionResponse.fromJson(response.data);
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
      return Exception('Connection timeout. Please check your internet connection.');
    } else if (e.type == DioExceptionType.badResponse) {
      return Exception('Server error: ${e.response?.statusCode}');
    } else if (e.type == DioExceptionType.cancel) {
      return Exception('Request cancelled');
    } else {
      return Exception('Network error: ${e.message}');
    }
  }
}