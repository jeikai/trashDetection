import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/constants/strings.dart';
import 'package:frontend/screens/help_screen.dart';
import 'package:frontend/screens/result_screen.dart';
import 'package:frontend/screens/picture_mode_screen.dart';
import 'package:frontend/services/camera_service.dart';
import 'package:frontend/services/permission_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/loading_indicator.dart';
import 'package:frontend/config/theme.dart';

class ScanModeScreen extends StatefulWidget {
  const ScanModeScreen({Key? key}) : super(key: key);

  @override
  State<ScanModeScreen> createState() => _ScanModeScreenState();
}

class _ScanModeScreenState extends State<ScanModeScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final PermissionService _permissionService = PermissionService();

  bool _isInitialized = false;
  bool _isRecording = false;
  String _errorMessage = '';
  Timer? _recordingTimer;
  int _recordingDuration = 5; // 5 seconds for recording
  int _countdown = 0;
  Timer? _countdownTimer;
  XFile? _videoFile;
  int _initRetryCount = 0;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWithRetry();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to properly manage camera resources
    if (_cameraService.controller == null) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopRecordingIfNeeded();
      _cameraService.dispose();
      _isInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      _initializeWithRetry();
    }
  }

  Future<void> _initializeWithRetry() async {
    if (_initRetryCount >= _maxRetries) {
      setState(() {
        _errorMessage = 'Failed to initialize camera after multiple attempts. Please restart the app.';
        _initRetryCount = 0;
      });
      return;
    }

    try {
      await _initializeCamera();
    } catch (e) {
      _initRetryCount++;
      print('Camera init attempt $_initRetryCount failed: $e');

      // Wait a bit longer between retries
      await Future.delayed(Duration(seconds: _initRetryCount));
      if (mounted) {
        _initializeWithRetry();
      }
    }
  }

  void _showHelpScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpScreen(
          helpText: AppStrings.scanModeHelp,
          title: AppStrings.scanModeTitle,
        ),
      ),
    );
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _errorMessage = '';
    });

    final hasPermission = await _permissionService.requestCameraPermission();
    if (!hasPermission) {
      setState(() {
        _errorMessage = AppStrings.permissionDenied;
      });
      return;
    }

    try {
      // Add a delay before initializing camera
      // This can help with lifecycle issues
      await Future.delayed(const Duration(milliseconds: 300));

      await _cameraService.initializeCamera();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '${AppStrings.cameraError}: $e';
          _isInitialized = false;
        });
      }
      throw e; // Rethrow for retry mechanism
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized || _cameraService.controller == null) return;

    try {
      await _cameraService.controller!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _countdown = _recordingDuration;
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _stopRecording();
            _countdownTimer?.cancel();
          }
        });
      });

      // Set timer to stop recording after duration
      _recordingTimer = Timer(Duration(seconds: _recordingDuration), () {
        if (mounted) {
          _stopRecording();
        }
      });
    } catch (e) {
      print('Error starting video recording: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to start recording: $e';
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _cameraService.controller == null) return;

    _recordingTimer?.cancel();
    _countdownTimer?.cancel();

    try {
      final video = await _cameraService.controller!.stopVideoRecording();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _videoFile = video;
      });

      // Navigate to results screen with video file
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(videoFile: _videoFile),
        ),
      );
    } catch (e) {
      print('Error stopping video recording: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _errorMessage = 'Failed to stop recording: $e';
        });
      }
    }
  }

  void _stopRecordingIfNeeded() {
    if (_isRecording && _cameraService.controller != null) {
      _cameraService.controller!.stopVideoRecording().then((XFile file) {
        if (mounted) {
          setState(() {
            _isRecording = false;
            _videoFile = file;
          });
        }
      }).catchError((e) {
        print('Error stopping recording: $e');
      });
    }

    _recordingTimer?.cancel();
    _countdownTimer?.cancel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopRecordingIfNeeded();
    _recordingTimer?.cancel();
    _countdownTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanModeTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Text(
              AppStrings.helpButtonLabel,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _showHelpScreen,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: AppStrings.retryButton,
                icon: Icons.refresh,
                onPressed: () {
                  _initRetryCount = 0;
                  _initializeWithRetry();
                },
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: AppStrings.pictureMode,
                type: ButtonType.secondary,
                icon: Icons.photo_library,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PictureModeScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: LoadingIndicator(
          message: 'Initializing camera...',
        ),
      );
    }

    return Column(
      children: [
        // Camera preview area
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Camera preview
              _cameraService.controller != null
                  ? AspectRatio(
                aspectRatio: _cameraService.controller!.value.aspectRatio,
                child: CameraPreview(_cameraService.controller!),
              )
                  : Container(color: Colors.black),

              // Recording indicator
              if (_isRecording)
                Positioned(
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recording: $_countdown s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Recording frame indicator
              if (_isRecording)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red,
                      width: 4,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Controls area
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.all(16),
          child: _isRecording ? _buildRecordingControls() : _buildInitialControls(),
        ),
      ],
    );
  }

  Widget _buildRecordingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomButton(
          text: 'Stop Recording',
          icon: Icons.stop,
          type: ButtonType.warning,
          onPressed: _stopRecording,
        ),
      ],
    );
  }

  Widget _buildInitialControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Point the camera at your object and press Record to capture a 5-second video",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: "Start Recording",
          icon: Icons.videocam,
          onPressed: _startRecording,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: AppStrings.pictureMode,
          icon: Icons.photo_library,
          type: ButtonType.secondary,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PictureModeScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}