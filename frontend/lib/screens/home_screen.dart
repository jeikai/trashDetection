import 'package:flutter/material.dart';
import 'package:frontend/constants/strings.dart';
import 'package:frontend/screens/picture_mode_screen.dart';
import 'package:frontend/screens/scan_mode_screen.dart';
import 'package:frontend/screens/help_screen.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showHelpDialog() {
    const helpText = "Welcome to the Recyclable Trash Detector!\n\n"
        "This app helps you identify recyclable trash items using your device's camera.\n\n"
        "You can use two modes:\n"
        "1. Picture Mode: Upload or take photos to analyze trash items.\n"
        "2. Scan Mode: Use your camera for real-time detection of trash items.\n\n"
        "Select a mode to get started!";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(AppStrings.helpTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(helpText),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
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
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo or Image
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.recycling,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 40),

              // Title and Subtitle
              Text(
                AppStrings.appName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Identify recyclable items quickly and easily",
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              // Mode Selection Buttons
              CustomButton(
                text: AppStrings.pictureMode,
                icon: Icons.photo_library,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PictureModeScreen(),
                    ),
                  );
                },
                height: 60,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: AppStrings.scanMode,
                icon: Icons.qr_code_scanner,
                type: ButtonType.secondary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScanModeScreen(),
                    ),
                  );
                },
                height: 60,
              ),
            ],
          ),
        ),
      ),
    );
  }
}