import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        throw CameraException('No cameras available', 'No cameras found on device');
      }

      // Use the first camera (usually the back camera)
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } on CameraException catch (e) {
      _isInitialized = false;
      throw Exception('Failed to initialize camera: ${e.description}');
    }
  }

  Future<XFile?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      return await _controller!.takePicture();
    } on CameraException catch (e) {
      throw Exception('Failed to take picture: ${e.description}');
    }
  }

  Future<File> captureVideoFrame() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      XFile picture = await _controller!.takePicture();
      return File(picture.path);
    } on CameraException catch (e) {
      throw Exception('Failed to capture video frame: ${e.description}');
    }
  }

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}