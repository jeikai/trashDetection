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
      // First check if we can access the camera plugin at all
      try {
        _cameras = await availableCameras();
      } catch (e) {
        print('Error accessing camera plugin: $e');
        // Handle plugin missing case specifically
        if (e.toString().contains('MissingPluginException')) {
          throw Exception('Camera plugin not available. Please restart the app or check your installation.');
        }
        rethrow;
      }

      if (_cameras == null || _cameras!.isEmpty) {
        throw CameraException('No cameras available', 'No cameras found on device');
      }

      // Initialize the camera controller
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      print('Camera initialization error: $e');
      throw e;
    }
  }

  Future<XFile?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      return await _controller!.takePicture();
    } on CameraException catch (e) {
      print('Take picture error: ${e.description}');
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
      print('Capture frame error: ${e.description}');
      throw Exception('Failed to capture video frame: ${e.description}');
    }
  }

  Future<void> dispose() async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      print('Error disposing camera controller: $e');
    } finally {
      _isInitialized = false;
    }
  }
}