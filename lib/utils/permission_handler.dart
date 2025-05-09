import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class PermissionHandler {
  // Check and request location permission
  static Future<bool> checkLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, show dialog
      return await _showLocationServicesDialog(context);
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are denied'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      return await _showAppSettingsDialog(
        context,
        'Location permission is required for attendance verification. Please enable it in app settings.',
      );
    }

    // Permissions are granted
    return true;
  }

  // Check camera permission without initializing controller
  static Future<bool> checkCameraPermission(BuildContext context) async {
    try {
      // Note: We're not initializing MobileScannerController here
      // Instead, we'll rely on platform-level permission requests
      
      // On Android, camera permission will be requested when the scanner is first shown
      // On iOS, we need to request it here
      
      // For demonstration, we're just returning true for now
      // The actual permission check will happen when the MobileScanner widget is built
      return true;
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing camera: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing camera: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Show dialog to open location services
  static Future<bool> _showLocationServicesDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text(
                  'Location services are disabled. To use attendance features, please enable location services.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    Geolocator.openLocationSettings();
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Show dialog to open app settings
  static Future<bool> _showAppSettingsDialog(
      BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permission Required'),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    Geolocator.openAppSettings();
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }
}