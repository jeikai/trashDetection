import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/constants/strings.dart';
import 'package:frontend/models/detection_result.dart';
import 'package:frontend/screens/help_screen.dart';
import 'package:frontend/screens/picture_mode_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/camera_service.dart';
import 'package:frontend/services/permission_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/detection_result_display.dart';
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
  final ApiService _apiService = ApiService();
  final PermissionService _permissionService = PermissionService();

  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  bool _showTargetText = false;
  String _errorMessage = '';
  Timer? _scanTimer;
  Timer? _frameTimer;
  int _countdown = AppConstants.preparationTime;
  Timer? _countdownTimer;
  DetectionResponse? _detectionResponse;
  List<DetectionResult> _allDetections = [];
  int _resultDisplayTime = AppConstants.resultDisplayTime;
  Timer? _resultDisplayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to properly manage camera resources
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
      _isInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
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
    final hasPermission = await _permissionService.requestCameraPermission();
    if (!hasPermission) {
      setState(() {
        _errorMessage = AppStrings.permissionDenied;
      });
      return;
    }

    try {
      await _cameraService.initializeCamera();
      setState(() {
        _isInitialized = true;
        _errorMessage = '';
      });
      // Start scanning immediately
      _startScanCountdown();
    } catch (e) {
      setState(() {
        _errorMessage = '${AppStrings.cameraError}: $e';
        _isInitialized = false;
      });
    }
  }

  void _startScanCountdown() {
    setState(() {
      _countdown = AppConstants.preparationTime;
      _showTargetText = true;
      _isScanning = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _countdownTimer?.cancel();
          _startScanning();
        }
      });
    });
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _showTargetText = true;
      _allDetections = [];
    });

    // Hide target text after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTargetText = false;
        });
      }
    });

    _scanTimer?.cancel();
    // Set overall scan duration
    _scanTimer = Timer(Duration(seconds: AppConstants.scanDuration), () {
      _stopScanning();
    });

    _frameTimer?.cancel();
    // Process frames every 500ms
    _frameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _processFrame();
    });
  }

  Future<void> _processFrame() async {
    if (_isProcessing || !_isScanning) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      File frameImage = await _cameraService.captureVideoFrame();
      final detectionResponse = await _apiService.processVideoFrame(frameImage);

      // Add new detections to the list
      if (detectionResponse.results.isNotEmpty) {
        setState(() {
          _detectionResponse = detectionResponse;
          _allDetections.addAll(detectionResponse.results);
        });
      }
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _stopScanning() {
    _scanTimer?.cancel();
    _frameTimer?.cancel();

    setState(() {
      _isScanning = false;
      _resultDisplayTime = AppConstants.resultDisplayTime;

      if (_allDetections.isNotEmpty) {
        _detectionResponse = DetectionResponse(
          results: _allDetections,
          message: AppStrings.detectionResults,
        );
      }
    });

    // Start result display countdown
    _resultDisplayTimer?.cancel();
    _resultDisplayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resultDisplayTime > 1) {
          _resultDisplayTime--;
        } else {
          _resultDisplayTimer?.cancel();
        }
      });
    });
  }

  void _retry() {
    _resultDisplayTimer?.cancel();
    _startScanCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _scanTimer?.cancel();
    _frameTimer?.cancel();
    _countdownTimer?.cancel();
    _resultDisplayTimer?.cancel();
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
              Icon(
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
                onPressed: _initializeCamera,
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
              AspectRatio(
                aspectRatio: _cameraService.controller!.value.aspectRatio,
                child: CameraPreview(_cameraService.controller!),
              ),

              // Overlay for scanning
              if (_isScanning)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 4,
                    ),
                  ),
                ),

              // Target text overlay
              if (_showTargetText && _isScanning)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    AppStrings.targetObjectText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Countdown overlay
              if (_countdown > 0 && !_isScanning)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_countdown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Get ready...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              // Loading indicator during processing
              if (_isProcessing)
                const LoadingIndicator(
                  message: AppStrings.processingVideo,
                ),

              // Real-time detection overlay
              if (_isScanning && _detectionResponse != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.detectionResults,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ..._allDetections.take(3).map((detection) => Text(
                          '${detection.objectType} (${(detection.confidence * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            color: _isRecyclable(detection)
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Results area or controls
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.all(16),
          child: _isScanning
              ? _buildScanningControls()
              : _detectionResponse != null
              ? _buildResultsView()
              : _buildInitialControls(),
        ),
      ],
    );
  }

  bool _isRecyclable(DetectionResult detection) {
    // Check if the recyclable category indicates it's recyclable
    // This is a simple implementation - adjust based on your recyclable categories
    return detection.recyclableCategory.toLowerCase() != 'non-recyclable' &&
        detection.recyclableCategory.toLowerCase() != 'unknown';
  }

  Widget _buildScanningControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Scanning...',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        CustomButton(
          text: 'Stop',
          icon: Icons.stop,
          type: ButtonType.warning,
          onPressed: _stopScanning,
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetectionResultDisplay(detectionResponse: _detectionResponse!),
        const SizedBox(height: 12),
        Text(
          '${_allDetections.length} ${AppStrings.itemsDetected}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomButton(
              text: AppStrings.retryButton,
              icon: Icons.refresh,
              onPressed: _retry,
            ),
            CustomButton(
              text: AppStrings.pictureMode,
              icon: Icons.camera_alt,
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
        ),
      ],
    );
  }

  Widget _buildInitialControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          AppStrings.scanModeHelp,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: "Start Scanning",
          icon: Icons.camera,
          onPressed: _startScanCountdown,
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