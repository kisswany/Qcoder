import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'; // for kIsWeb

import '../../../utils/ui_utils.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/scanner_overlay.dart';
import '../views/result_view.dart';

/// The "Scan" tab, managing Camera Scanning and Gallery Image picking.
class ScannerTab extends StatefulWidget {
  final String? initialData;
  final Function(bool isScanning) onScanningChanged;

  const ScannerTab({
    super.key, 
    this.initialData,
    required this.onScanningChanged,
  });

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> with WidgetsBindingObserver {
  // Logic
  MobileScannerController? _scannerController;
  bool _isScannerActive = false;
  bool _torchEnabled = false;
  
  // Data
  String _scannedData = "";
  
  // Debounce
  bool _canScan = true;
  Timer? _scanCooldown;

  @override
  void initState() {
    super.initState();
    // Use initial data if provided from a deep link
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _scannedData = widget.initialData!;
    }
  }

  @override
  void dispose() {
    _scanCooldown?.cancel();
    _scannerController?.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _startCameraScanner() {
    if (kIsWeb) {
      showToast(context, AppLocalizations.of(context)!.alignQR);
      return;
    }
    
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    
    setState(() {
      _isScannerActive = true;
      _scannedData = "";
      _torchEnabled = false;
    });
    widget.onScanningChanged(true);
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() {
      _isScannerActive = false;
      _torchEnabled = false;
    });
    widget.onScanningChanged(false);
  }

  Future<void> _toggleTorch() async {
    if (_scannerController == null) return;
    
    if (!_torchEnabled) {
       // Safety: Check battery before enabling flash
       final battery = Battery();
       try {
         final level = await battery.batteryLevel;
         if (level < 20) {
           if (mounted) showToast(context, 'Low Battery - Flash Unavailable');
           return; 
         }
       } catch (e) {
         debugPrint("Error checking battery: $e");
       }
    }
    
    await _scannerController!.toggleTorch();
    setState(() => _torchEnabled = !_torchEnabled);
  }

  Future<void> _pickAndScanImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // Create a temporary controller just for one-off analysis
        final controller = MobileScannerController();
        bool found = false;
        
        // Listen for the first result
        final StreamSubscription subscription = controller.barcodes.listen((capture) {
           if (capture.barcodes.isNotEmpty) {
               final code = capture.barcodes.first.rawValue;
                if (code != null) {
                    found = true;
                    setState(() => _scannedData = code);
                    controller.dispose();
                }
           }
        });
        
        try {
            await controller.analyzeImage(image.path);
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (!found && mounted) {
                showToast(context, AppLocalizations.of(context)!.noQRFound);
            }
        } catch (e) {
            debugPrint("Analysis error: $e");
            if (mounted) showToast(context, AppLocalizations.of(context)!.noQRFound);
        } finally {
            await subscription.cancel();
            controller.dispose();
        }
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
       if (mounted) showToast(context, AppLocalizations.of(context)!.noQRFound);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_canScan) return;
    
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        // Cooldown logic to prevent double-scans
        _canScan = false;
        _scanCooldown?.cancel();
        _scanCooldown = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _canScan = true);
        });
        
        // Success
        _stopScanner();
        setState(() => _scannedData = barcode.rawValue!);
        // onScanningChanged(false) is called inside _stopScanner
        break;
      }
    }
  }

  // --- VIEWS ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 1. If actively scanning, show Camera + Overlay
    if (_isScannerActive) {
      return Stack(
        children: [
          MobileScanner(
            controller: _scannerController!,
            onDetect: _onDetect,
          ),
          ScannerOverlay(
            isTorchEnabled: _torchEnabled,
            onToggleTorch: _toggleTorch,
            onStopScanner: _stopScanner,
          ),
        ],
      );
    } 
    // 2. If we have data, show Result
    else if (_scannedData.isNotEmpty) {
      return ResultView(
        data: _scannedData,
        onScanAgain: () {
          // Reset data to return to Choice Menu
          setState(() {
            _scannedData = "";
          });
        },
      );
    } 
    // 3. Default: Show Choice Menu (Camera / Gallery)
    else {
      return _buildChoiceMenu(l10n);
    }
  }

  Widget _buildChoiceMenu(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic Placeholder
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2C),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF03DAC6)),
          ),
          const SizedBox(height: 32),
          
          Text(
            l10n.scanQR,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          
          // Options
          ProfessionalButton(
            label: l10n.openCamera,
            icon: Icons.camera_alt,
            onPressed: _startCameraScanner,
            gradient: const LinearGradient(colors: [Color(0xFF03DAC6), Color(0xFF00B8A9)]),
          ),
          const SizedBox(height: 16),
          ProfessionalButton(
            label: l10n.pickFromGallery,
            icon: Icons.photo_library,
            onPressed: _pickAndScanImage,
            gradient: const LinearGradient(colors: [Color(0xFFBB86FC), Color(0xFF9F5FFF)]),
          ),
        ],
      ),
    );
  }
}
