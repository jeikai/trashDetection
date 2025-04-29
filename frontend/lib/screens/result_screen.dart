import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend/constants/strings.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/loading_indicator.dart';
import 'package:video_player/video_player.dart';

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
  Map<String, dynamic>? _analysisResults;

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
        _analysisResults = results;
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
    if (_analysisResults == null || _analysisResults!.isEmpty) {
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

    // Handle simple message response from backend
    if (_analysisResults!.containsKey('message') && _analysisResults!.length == 1) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _analysisResults!['message'],
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Handle full results if backend returns detailed analysis
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            // Display results as formatted key-value pairs
            ..._analysisResults!.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      _formatResultValue(entry.value),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }

  String _formatResultValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    } else if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return value.toString();
  }
}