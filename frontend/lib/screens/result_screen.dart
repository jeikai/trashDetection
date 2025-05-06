import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend/constants/strings.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/loading_indicator.dart';
import 'package:frontend/models/detection_result.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';

class ResultsScreen extends StatefulWidget {
  final XFile? videoFile;

  const ResultsScreen({Key? key, required this.videoFile}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService _apiService = ApiService();
  VideoPlayerController? _videoController;
  bool _isAnalyzing = false;
  bool _isAnalysisComplete = false;
  String _errorMessage = '';
  DetectionResponse? _detectionResponse;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
    _analyzeVideo();
  }

  Future<void> _initVideoPlayer() async {
    if (widget.videoFile == null) {
      setState(() {
        _errorMessage = 'No video file provided';
      });
      return;
    }

    try {
      _videoController = VideoPlayerController.file(File(widget.videoFile!.path));
      await _videoController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load video: $error';
        });
      }
      print('Video player initialization error: $error');
    }
  }

  Future<void> _analyzeVideo() async {
    if (widget.videoFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = ''; // Clear any previous errors
    });

    try {
      // Send video file to backend for analysis
      final results = await _apiService.analyzeVideo(File(widget.videoFile!.path));

      if (!mounted) return;

      setState(() {
        _detectionResponse = results;
        _isAnalysisComplete = true;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;

      print('Analysis error: $e');
      setState(() {
        _errorMessage = 'Failed to analyze video: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        centerTitle: true,
      ),
      body: _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _buildResultsView(),
    );
  }

  Widget _buildErrorView() {
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
              text: 'Go Back',
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Try Again',
              icon: Icons.refresh,
              onPressed: () => _analyzeVideo(),
              type: ButtonType.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Player
            if (_videoController != null && _videoController!.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoController!),
                    // Play button overlay
                    IconButton(
                      icon: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 50,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            const SizedBox(height: 24),

            // Analysis section
            _isAnalyzing
                ? const LoadingIndicator(message: 'Analyzing video...')
                : _isAnalysisComplete
                ? _buildAnalysisResults()
                : const Text(
              'Waiting for analysis to start...',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Control buttons
            CustomButton(
              text: 'Record Another Video',
              icon: Icons.videocam,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResults() {
    if (_detectionResponse == null) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No analysis data available. The video was processed successfully, but no detailed results were returned.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // If we have image data, display it
    if (_detectionResponse!.imageBase64.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Processed Images',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Display the images from base64 strings
          Container(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _detectionResponse!.imageBase64.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(right: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildBase64Image(_detectionResponse!.imageBase64[index]),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Display results if available, otherwise just show message
          if (_detectionResponse!.results.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Objects',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _detectionResponse!.results.length,
                      itemBuilder: (context, index) {
                        final result = _detectionResponse!.results[index];
                        return ListTile(
                          title: Text(result.objectType),
                          subtitle: Text('Category: ${result.recyclableCategory}'),
                          trailing: Text(
                            '${(result.confidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: _getConfidenceColor(result.confidence),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Analysis Message',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      _detectionResponse!.message,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    } else {
      // If no images but have a message
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analysis Complete',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const Divider(),
              Text(
                _detectionResponse!.message,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBase64Image(String base64String) {
    try {
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        width: 200,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red, size: 40),
            ),
          );
        },
      );
    } catch (e) {
      print('Error decoding base64 image: $e');
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
        ),
      );
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}