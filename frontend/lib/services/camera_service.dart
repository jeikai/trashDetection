import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  Future<void> initializeCamera() async {
    await dispose();

    try {
      // Kiểm tra quyền truy cập camera
      try {
        _cameras = await availableCameras();
      } catch (e) {
        print('Lỗi truy cập plugin camera: $e');
        if (e.toString().contains('MissingPluginException')) {
          throw Exception('Plugin camera không khả dụng. Vui lòng khởi động lại ứng dụng hoặc kiểm tra cài đặt.');
        }
        rethrow;
      }

      if (_cameras == null || _cameras!.isEmpty) {
        throw CameraException('Không có camera khả dụng', 'Không tìm thấy camera trên thiết bị');
      }

      // Cấu hình camera với độ phân giải cao nhất để tránh bóp ngang
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.max,
        enableAudio: true,
      );

      await _controller!.initialize();

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      print('Lỗi khởi tạo camera: $e');
      throw e;
    }
  }

  Future<XFile?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera chưa được khởi tạo');
    }

    try {
      return await _controller!.takePicture();
    } on CameraException catch (e) {
      print('Lỗi chụp ảnh: ${e.description}');
      throw Exception('Không thể chụp ảnh: ${e.description}');
    }
  }

  Future<File> captureVideoFrame() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera chưa được khởi tạo');
    }

    try {
      XFile picture = await _controller!.takePicture();
      return File(picture.path);
    } on CameraException catch (e) {
      print('Lỗi chụp khung hình từ video: ${e.description}');
      throw Exception('Không thể chụp khung hình từ video: ${e.description}');
    }
  }

  Future<void> dispose() async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      print('Lỗi giải phóng controller camera: $e');
    } finally {
      _isInitialized = false;
    }
  }
}
