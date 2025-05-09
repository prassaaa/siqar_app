import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:siqar_app/providers/absensi_provider.dart';
import 'package:siqar_app/utils/constants.dart';
import 'package:siqar_app/widgets/loading_overlay.dart';
import 'package:siqar_app/widgets/custom_button.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  late AnimationController _animationController;
  
  bool _isProcessing = false;
  bool _isQRChecked = false;
  bool _hasLocationPermission = false;
  String _scanType = 'masuk'; // Default scan type
  bool _isTorchOn = false;
  String? _scannedCode; // Store the raw scanned QR code
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _checkLocationPermission();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }
  
  Future<void> _checkLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, show dialog
      await _showLocationServicesDialog();
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are denied'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      await _showAppSettingsDialog(
        'Location permission is required for attendance verification. Please enable it in app settings.',
      );
      return;
    }

    // Permissions are granted
    setState(() {
      _hasLocationPermission = true;
    });
  }
  
  Future<void> _showLocationServicesDialog() async {
    await showDialog(
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _showAppSettingsDialog(String message) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<Position?> _getCurrentLocation() async {
    if (!_hasLocationPermission) {
      await _checkLocationPermission();
      if (!_hasLocationPermission) {
        return null;
      }
    }
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
  
  Future<void> _processScanResult(String code) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _scannedCode = code; // Store the raw QR code
    });
    
    // Check QR Code
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);
    final isValidQR = await absensiProvider.checkQRCode(code);
    
    if (!isValidQR) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(absensiProvider.message),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isQRChecked = true;
      _isProcessing = false;
    });
  }
  
  Future<void> _submitAttendance() async {
    if (_scannedCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('QR Code tidak tersedia. Silakan scan ulang.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    // Get current location
    final position = await _getCurrentLocation();
    if (position == null) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }
    
    // Submit attendance using the raw scanned QR code
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);
    
    final success = await absensiProvider.scanQRCode(
      _scannedCode!,
      position.latitude,
      position.longitude,
      _scanType,
    );
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(absensiProvider.message),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(absensiProvider.message),
            backgroundColor: AppConstants.errorColor,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  Widget _buildPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: AppConstants.textSecondaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Izin Lokasi Dibutuhkan',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Aplikasi membutuhkan izin lokasi untuk verifikasi kehadiran. Silakan berikan izin yang diperlukan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Berikan Izin Lokasi',
              onPressed: _checkLocationPermission,
              icon: Icons.location_on,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQRResultView() {
    final absensiProvider = Provider.of<AbsensiProvider>(context);
    final qrCode = absensiProvider.scannedQRCode;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: AppConstants.successColor,
            ),
            const SizedBox(height: 24),
            Text(
              'QR Code Valid',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (qrCode != null)
              Column(
                children: [
                  Text(
                    qrCode.deskripsi,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tanggal: ${qrCode.tanggal}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (qrCode.waktuMulai != null && qrCode.waktuBerakhir != null)
                    Text(
                      'Waktu: ${qrCode.waktuMulai} - ${qrCode.waktuBerakhir}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (qrCode.lokasi != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Lokasi: ${qrCode.lokasi!.namaLokasi}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 32),
            Text(
              'Pilih Jenis Absensi:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(
                  value: 'masuk',
                  groupValue: _scanType,
                  onChanged: (value) {
                    setState(() {
                      _scanType = value!;
                    });
                  },
                  activeColor: AppConstants.primaryColor,
                ),
                const Text('Absen Masuk'),
                const SizedBox(width: 24),
                Radio<String>(
                  value: 'keluar',
                  groupValue: _scanType,
                  onChanged: (value) {
                    setState(() {
                      _scanType = value!;
                    });
                  },
                  activeColor: AppConstants.primaryColor,
                ),
                const Text('Absen Keluar'),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Lakukan Absensi',
              onPressed: _submitAttendance,
              loading: _isProcessing,
              icon: Icons.check,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isQRChecked = false;
                });
              },
              child: Text(
                'Scan Ulang',
                style: TextStyle(color: AppConstants.primaryColor),
              ),
            ),
            // Debug info
            if (AppConstants.isDebugMode) ...[
              const Divider(),
              Text('Raw QR: $_scannedCode', style: TextStyle(fontSize: 12)),
              if (qrCode?.kode != null)
                Text('QRCode.kode: ${qrCode?.kode}', style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (capture.barcodes.isNotEmpty && mounted && !_isProcessing) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                _processScanResult(barcode.rawValue!);
              }
            }
          },
          // Remove the errorBuilder completely
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppConstants.primaryColor,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.saturation,
                      ),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
              // Scanline animation
              Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 250,
                      height: 3,
                      margin: EdgeInsets.only(
                        top: 250 * _animationController.value,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                      ),
                    );
                  },
                ),
              ),
              // Instructions
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Text(
                  'Arahkan ke kode QR untuk absensi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final absensiProvider = Provider.of<AbsensiProvider>(context);
    
    return LoadingOverlay(
      isLoading: absensiProvider.loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          actions: [
            if (!_isQRChecked)
              IconButton(
                icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
                onPressed: () {
                  setState(() {
                    _isTorchOn = !_isTorchOn;
                    _scannerController.toggleTorch();
                  });
                },
              ),
            if (!_isQRChecked)
              IconButton(
                icon: const Icon(Icons.flip_camera_ios),
                onPressed: () {
                  _scannerController.switchCamera();
                },
              ),
          ],
        ),
        body: _isQRChecked ? 
          _buildQRResultView() : 
          (_hasLocationPermission ? _buildScannerView() : _buildPermissionView()),
      ),
    );
  }
}