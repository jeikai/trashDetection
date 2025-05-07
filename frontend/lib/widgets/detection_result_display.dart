import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/models/detection_result.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/constants/strings.dart';

class DetectionResultDisplay extends StatelessWidget {
  final DetectionResponse detectionResponse;

  const DetectionResultDisplay({
    Key? key,
    required this.detectionResponse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                AppStrings.detectionResults,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${detectionResponse.imageBase64.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Display processed images from base64 data
        if (detectionResponse.imageBase64.isNotEmpty)
          Container(
            height: 250,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: detectionResponse.imageBase64.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildBase64Image(
                    context,
                    detectionResponse.imageBase64[index],
                  ),
                );
              },
            ),
          ),

        // Results list if available
        if (detectionResponse.results.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: detectionResponse.results.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final result = detectionResponse.results[index];
                return ListTile(
                  leading: _buildRecyclableIcon(result.recyclableCategory),
                  title: Text(
                    result.objectType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Category: ${result.recyclableCategory}',
                  ),
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
          )
        else
        // Display message only when no specific results
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  detectionResponse.message,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBase64Image(BuildContext context, String base64String) {
    try {
      // Clean the base64 string - remove any prefixes or whitespace
      String cleanBase64 = base64String.trim();

      // Check if the string starts with data URI prefix
      if (cleanBase64.startsWith('data:image')) {
        // Extract the actual base64 data after the comma
        cleanBase64 = cleanBase64.split(',')[1];
      }

      // Handle possible padding issues
      while (cleanBase64.length % 4 != 0) {
        cleanBase64 += '=';
      }

      return GestureDetector(
        onTap: () {
          // Navigate to full screen image viewer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImageViewer(base64Image: cleanBase64),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(cleanBase64),
                fit: BoxFit.contain,
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  print("Error decoding base64 image: $error");
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Error loading image',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Add a small icon to indicate the image is tappable
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.all(8),
              child: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Exception when processing base64 image: $e");
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, color: Colors.grey, size: 40),
              SizedBox(height: 8),
              Text(
                'Invalid image data',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildRecyclableIcon(String category) {
    IconData iconData;
    Color iconColor;

    switch (category.toLowerCase()) {
      case 'plastic':
        iconData = Icons.local_drink;
        iconColor = Colors.lightBlue;
        break;
      case 'paper':
        iconData = Icons.description;
        iconColor = Colors.amber;
        break;
      case 'glass':
        iconData = Icons.wine_bar;
        iconColor = Colors.cyan;
        break;
      case 'metal':
        iconData = Icons.settings;
        iconColor = Colors.grey;
        break;
      case 'organic':
        iconData = Icons.eco;
        iconColor = Colors.green;
        break;
      case 'electronic':
        iconData = Icons.devices;
        iconColor = Colors.deepPurple;
        break;
      case 'non-recyclable':
        iconData = Icons.delete;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.help_outline;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor),
    );
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

/// Full screen image viewer widget
class FullScreenImageViewer extends StatelessWidget {
  final String base64Image;

  const FullScreenImageViewer({
    Key? key,
    required this.base64Image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Image Viewer',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Add share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality here if needed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality to be implemented')),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.memory(
            base64Decode(base64Image),
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}