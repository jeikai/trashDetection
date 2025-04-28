import 'package:flutter/material.dart';
import 'package:frontend/models/detection_result.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/constants/strings.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
                '${detectionResponse.results.length} ${AppStrings.itemsDetected}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Processed image if available
        if (detectionResponse.processedImageUrl != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: CachedNetworkImage(
              imageUrl: detectionResponse.processedImageUrl!,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error),
              ),
            ),
          ),

        // Results list
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
        ),
      ],
    );
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