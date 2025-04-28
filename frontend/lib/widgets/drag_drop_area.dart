import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/constants/strings.dart';

class DragDropArea extends StatelessWidget {
  final List<File> selectedFiles;
  final Function(List<File>) onFilesSelected;
  final VoidCallback onSelectFilesPressed;
  final VoidCallback onTakePhotoPressed;

  const DragDropArea({
    Key? key,
    required this.selectedFiles,
    required this.onFilesSelected,
    required this.onSelectFilesPressed,
    required this.onTakePhotoPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          dashPattern: const [8, 4],
          strokeWidth: 2,
          color: AppTheme.primaryColor,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 50,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.dragAndDropText,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                if (selectedFiles.isNotEmpty) _buildSelectedFilesList(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onSelectFilesPressed,
                      icon: const Icon(Icons.folder_open),
                      label: const Text(AppStrings.selectFilesButton),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onTakePhotoPressed,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(AppStrings.takePhotoButton),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFilesList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: selectedFiles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    selectedFiles[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      final updatedFiles = List<File>.from(selectedFiles);
                      updatedFiles.removeAt(index);
                      onFilesSelected(updatedFiles);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}