import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Request camera permission
  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  // Request storage permission for accessing photos
  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  // Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  // Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    return await Permission.storage.isGranted;
  }
}