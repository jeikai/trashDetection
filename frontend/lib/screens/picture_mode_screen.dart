import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/constants/strings.dart';
import 'package:frontend/models/detection_result.dart';
import 'package:frontend/screens/help_screen.dart';
import 'package:frontend/screens/scan_mode_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/permission_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/drag_drop_area.dart';
import 'package:frontend/widgets/detection_result_display.dart';
import 'package:frontend/widgets/loading_indicator.dart';
import 'package:frontend/config/theme.dart';

class PictureModeScreen extends StatefulWidget {
  const PictureModeScreen({Key? key}) : super(key: key);

  @override
  State<PictureModeScreen> createState() => _PictureModeScreenState();
}

class _PictureModeScreenState extends State<PictureModeScreen> {
  final ApiService _apiService = ApiService();
  final PermissionService _permissionService = PermissionService();
  final ImagePicker _imagePicker = ImagePicker();

  List<File> _selectedFiles = [];
  bool _isLoading = false;
  bool _isSubmitted = false;
  String _errorMessage = '';
  DetectionResponse? _detectionResponse;

  void _showHelpScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpScreen(
          helpText: AppStrings.pictureModeHelp,
          title: AppStrings.pictureModeTitle,
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final hasPermission = await _permissionService.requestStoragePermission();
    if (!hasPermission) {
      setState(() {
        _errorMessage = AppStrings.permissionDenied;
      });
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      List<File> newFiles = result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();

      if (_selectedFiles.length + newFiles.length > AppConstants.maxImageCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Maximum ${AppConstants.maxImageCount} images allowed. Only adding the first ${AppConstants.maxImageCount - _selectedFiles.length}.',
            ),
          ),
        );
        newFiles = newFiles.take(AppConstants.maxImageCount - _selectedFiles.length).toList();
      }

      setState(() {
        _selectedFiles.addAll(newFiles);
        _errorMessage = '';
      });
    }
  }

  Future<void> _takePhoto() async {
    final hasPermission = await _permissionService.requestCameraPermission();
    if (!hasPermission) {
      setState(() {
        _errorMessage = AppStrings.permissionDenied;
      });
      return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        if (_selectedFiles.length >= AppConstants.maxImageCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum image count reached. Please remove some images first.'),
            ),
          );
          return;
        }

        setState(() {
          _selectedFiles.add(File(photo.path));
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to take photo: $e';
      });
    }
  }

  Future<void> _submitImages() async {
    if (_selectedFiles.isEmpty) {
      setState(() {
        _errorMessage = AppStrings.noImagesSelected;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isSubmitted = false;
    });

    try {
      final detectionResponse = await _apiService.detectFromImages(_selectedFiles);

      setState(() {
        _detectionResponse = detectionResponse;
        _isSubmitted = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetState() {
    setState(() {
      _selectedFiles = [];
      _errorMessage = '';
      _isSubmitted = false;
      _detectionResponse = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.pictureModeTitle),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.pictureModeHelp,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Drag-drop area
            if (!_isSubmitted || _errorMessage.isNotEmpty)
              DragDropArea(
                selectedFiles: _selectedFiles,
                onFilesSelected: (files) {
                  setState(() {
                    _selectedFiles = files;
                  });
                },
                onSelectFilesPressed: _pickImages,
                onTakePhotoPressed: _takePhoto,
              ),

            // Error message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: LoadingIndicator(
                  message: 'Analyzing images...',
                ),
              ),

            // Results section
            if (_isSubmitted && _detectionResponse != null && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: DetectionResultDisplay(
                  detectionResponse: _detectionResponse!,
                ),
              ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!_isSubmitted || _errorMessage.isNotEmpty)
                    Expanded(
                      child: CustomButton(
                        text: AppStrings.submitButton,
                        icon: Icons.send,
                        onPressed: _submitImages,
                        isLoading: _isLoading,
                      ),
                    )
                  else
                    Expanded(
                      child: CustomButton(
                        text: 'New Detection',
                        icon: Icons.refresh,
                        onPressed: _resetState,
                      ),
                    ),
                ],
              ),
            ),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: AppStrings.homeButton,
                    type: ButtonType.secondary,
                    icon: Icons.home,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: AppStrings.scanModeButton,
                    type: ButtonType.secondary,
                    icon: Icons.qr_code_scanner,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanModeScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}