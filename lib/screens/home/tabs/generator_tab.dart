import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import '../../../utils/ui_utils.dart';
import '../../../widgets/buttons.dart';

enum CaptionPosition { above, below }

/// The "Generate" tab, allowing users to create QR codes from text/URLs.
/// 
/// Features:
/// - Text Input
/// - Caption Input (with positioning)
/// - Preview
/// - Save (PNG/JPG) & Share
class GeneratorTab extends StatefulWidget {
  const GeneratorTab({super.key});

  @override
  State<GeneratorTab> createState() => _GeneratorTabState();
}

class _GeneratorTabState extends State<GeneratorTab> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  
  String _qrData = "";
  CaptionPosition _captionPosition = CaptionPosition.below;

  @override
  void dispose() {
    _urlController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _generateQR() {
    if (_urlController.text.isNotEmpty) {
      // Dismiss keyboard and update state
      FocusScope.of(context).unfocus();
      setState(() {
        _qrData = _urlController.text;
      });
    } else {
      showToast(context, 'Please enter some text to generate');
    }
  }

  Future<void> _shareQR() async {
    if (_qrData.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    // Sharing raw text for now, could be improved to share generated image
    await Share.share('${l10n.scanQR}: $_qrData');
  }

  Future<void> _showSaveDialog() async {
    if (_qrData.isEmpty) return;
    
    String selectedFormat = 'png';
    final TextEditingController filenameController = TextEditingController(text: 'qr_code');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.save, color: Color(0xFF4CAF50), size: 28),
              SizedBox(width: 12),
              Text('Save QR Code'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filename:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: filenameController,
                decoration: InputDecoration(
                  hintText: 'Enter filename',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Format:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('PNG'),
                      value: 'png',
                      groupValue: selectedFormat,
                      onChanged: (val) => setState(() => selectedFormat = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('JPG'),
                      value: 'jpg',
                      groupValue: selectedFormat,
                      onChanged: (val) => setState(() => selectedFormat = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    
    if (result == true) {
      await _saveQRImage(selectedFormat, filename: filenameController.text);
    }
  }

  Future<void> _saveQRImage(String format, {String filename = 'qr_code'}) async {
    try {
      // 1. Storage Permissions
      var status = await Permission.storage.request();
      
      // On Android 13+, explicit storage perm might differ, but simple request interacts with manifest logic
      // Assuming basic permissions logic for now. 
      if (!status.isGranted && status.isPermanentlyDenied) {
          if (mounted) showToast(context, 'Permission denied. Please enable storage access.');
          return;
      }
      // Note: Android 10+ scoped storage might not need write permission for simplified access,
      // but we requested WRITE_EXTERNAL_STORAGE in manifest.

      // 2. Capture Image from RenderBoundary
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      
      // 3. Convert if needed (JPG)
      List<int> finalBytes = pngBytes;
      if (format.toLowerCase() == 'jpg') {
        final decodedImage = img.decodeImage(pngBytes);
        if (decodedImage != null) {
          finalBytes = img.encodeJpg(decodedImage, quality: 95);
        }
      }

      // 4. Save to filesystem
      final directory = await getExternalStorageDirectory();
      if (directory == null) return;
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFilename = filename.isEmpty ? 'qr_$timestamp' : '${filename}_$timestamp';
      final path = '${directory.path}/$finalFilename.$format';
      final file = File(path);
      await file.writeAsBytes(finalBytes);

      if (mounted) {
        showToast(context, AppLocalizations.of(context)!.savedSuccessfully);
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        showToast(context, 'Error saving: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 1. Inputs
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: l10n.enterUrl,
              prefixIcon: const Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            decoration: InputDecoration(
              labelText: l10n.caption,
              prefixIcon: const Icon(Icons.text_fields),
            ),
          ),
          const SizedBox(height: 12),
          
          // 2. Options
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<CaptionPosition>(
                value: CaptionPosition.above,
                groupValue: _captionPosition,
                onChanged: (val) => setState(() => _captionPosition = val!),
              ),
              Text(l10n.captionAbove),
              const SizedBox(width: 16),
              Radio<CaptionPosition>(
                value: CaptionPosition.below,
                groupValue: _captionPosition,
                onChanged: (val) => setState(() => _captionPosition = val!),
              ),
              Text(l10n.captionBelow),
            ],
          ),
          const SizedBox(height: 24),
          
          // 3. Generate Button
          ProfessionalButton(
            label: l10n.generate,
            icon: Icons.qr_code,
            onPressed: _generateQR,
            gradient: const LinearGradient(colors: [Color(0xFFBB86FC), Color(0xFF9F5FFF)]),
          ),
          
          // 4. Result Preview & Actions
          if (_qrData.isNotEmpty) ...[
            const SizedBox(height: 32),
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_captionPosition == CaptionPosition.above && _captionController.text.isNotEmpty) ...[
                      Text(_captionController.text, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                    ],
                    QrImageView(data: _qrData, version: QrVersions.auto, size: 250),
                    if (_captionPosition == CaptionPosition.below && _captionController.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_captionController.text, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ProfessionalButton(
                    label: l10n.share,
                    icon: Icons.share,
                    onPressed: _shareQR,
                    gradient: const LinearGradient(colors: [Color(0xFFBB86FC), Color(0xFF9F5FFF)]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ProfessionalButton(
                    label: l10n.save,
                    icon: Icons.save,
                    onPressed: _showSaveDialog,
                    gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
