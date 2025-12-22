import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../utils/ui_utils.dart';
import '../../../widgets/buttons.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';

/// Displays the result of a successful scan (Camera or Gallery).
/// 
/// Parses the content type (URL, WiFi, Email, Phone) and displays
/// context-aware action buttons.
class ResultView extends StatefulWidget {
  final String data;
  final VoidCallback onScanAgain;

  const ResultView({
    super.key,
    required this.data,
    required this.onScanAgain,
  });

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Parses RAW WiFi QR string (e.g., WIFI:T:WPA;S:MyNet;P:pass;;) into a map.
  Map<String, String>? _parseWiFiQR(String data) {
    if (!data.toUpperCase().startsWith('WIFI:')) return null;
    
    final Map<String, String> result = {};
    final parts = data.substring(5).split(';');
    
    for (var part in parts) {
      if (part.isEmpty) continue;
      final keyValue = part.split(':');
      if (keyValue.length >= 2) {
        // Handle cases where password might contain colons, simplified here
        final key = keyValue[0];
        final val = keyValue.sublist(1).join(':'); 
        
        switch (key) {
          case 'T': result['type'] = val; break;
          case 'S': result['ssid'] = val; break;
          case 'P': result['password'] = val; break;
          case 'H': result['hidden'] = val; break;
        }
      }
    }
    return result.isNotEmpty ? result : null;
  }

  Future<void> _connectToWiFi(String ssid, String? password, String? security) async {
    // 1. Request Location Permission (Required for WiFi on Android)
    if (await Permission.location.request().isGranted) {
       try {
         if (mounted) showToast(context, 'Connecting to $ssid...');
         
         // 2. Attempt Connection
         // Note: Android 10+ (Q) has severe restrictions. usage of API is limited.
         // forceWifiUsage: true might help on some devices to route traffic.
         final connected = await WiFiForIoTPlugin.connect(
            ssid,
            password: password,
            joinOnce: true, // Attempt to join without saving if possible (API dep)
            security: (security?.toUpperCase() == 'WPA' || security?.toUpperCase() == 'WEP') 
                ? (security?.toUpperCase() == 'WEP' ? NetworkSecurity.WEP : NetworkSecurity.WPA) 
                : NetworkSecurity.WPA, // Defaulting to WPA as it's most common if unspecified, or NONE
            withInternet: true,
         );
         
         if (connected) {
           if (mounted) showToast(context, 'Connected to $ssid ✅');
         } else {
           // Fallback for Android 10+ or failures
           if (mounted) showToast(context, 'Connection failed. Please use Settings.');
           // Use the old fallback logic (Open Settings)
           await Future.delayed(const Duration(seconds: 1));
           // launchUrl... (omitted here, handled by button fallback logic usually)
         }
       } catch (e) {
         if (mounted) showToast(context, 'Error: $e');
       }
    } else {
      if (mounted) showToast(context, 'Location permission required for WiFi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scannedData = widget.data;

    // --- Smart Content Detection ---
    bool isUrl = Uri.tryParse(scannedData)?.hasAbsolutePath ?? false;
    bool isValidUrl = isUrl && (scannedData.startsWith('http://') || scannedData.startsWith('https://'));
    bool isEmail = scannedData.contains('@') && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(scannedData);
    bool isPhone = RegExp(r'^[\+]?[\d\s\-\(\)]{10,}$').hasMatch(scannedData.trim());
    
    Map<String, String>? wifiData = _parseWiFiQR(scannedData);
    bool isWiFi = wifiData != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 1. Result Card
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFBB86FC).withOpacity(0.2), const Color(0xFFBB86FC).withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBB86FC).withOpacity(0.3), width: 2),
              ),
              child: Column(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFBB86FC), Color(0xFF9F5FFF)]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWiFi ? Icons.wifi : (isValidUrl ? Icons.link : (isEmail ? Icons.email : (isPhone ? Icons.phone : Icons.text_fields))),
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    l10n.qrCodeScanned,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFBB86FC)),
                  ),
                  const SizedBox(height: 8),
                  
                  // Category
                  Text(
                    isWiFi ? 'WiFi Network' : (isValidUrl ? 'Web Link' : (isEmail ? 'Email Address' : (isPhone ? 'Phone Number' : 'Text Content'))),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  
                  // Content Display
                  if (isWiFi) 
                    _buildWiFiInfo(wifiData!, l10n) 
                  else 
                    _buildTextInfo(scannedData),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // 2. Smart Action Buttons
          if (isValidUrl) ProfessionalButton(
            label: l10n.openInBrowser,
            icon: Icons.open_in_browser,
            onPressed: () => launchUrl(Uri.parse(scannedData), mode: LaunchMode.externalApplication),
            gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
          ),
          if (isEmail) ...[
            ProfessionalButton(
              label: 'Send Email',
              icon: Icons.email,
              onPressed: () => launchUrl(Uri.parse('mailto:$scannedData')),
              gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
            ),
            const SizedBox(height: 12),
          ],
          if (isPhone) ...[
            ProfessionalButton(
              label: 'Call Number',
              icon: Icons.phone,
              onPressed: () => launchUrl(Uri.parse('tel:$scannedData')),
              gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
            ),
            const SizedBox(height: 12),
           ],
           if (isWiFi && wifiData != null && wifiData.containsKey('password')) ...[
              ProfessionalButton(
                label: 'Copy Password',
                icon: Icons.copy,
                onPressed: () {
                   Clipboard.setData(ClipboardData(text: wifiData['password']!));
                   if (context.mounted) showToast(context, 'Password copied!');
                },
                gradient: const LinearGradient(colors: [Color(0xFFFFA000), Color(0xFFFFC107)]),
              ),
              const SizedBox(height: 12),
              ProfessionalButton(
                label: 'Connect to Network',
                icon: Icons.wifi_lock,
                onPressed: () => _connectToWiFi(
                  wifiData['ssid']!,
                  wifiData['password'],
                  wifiData['type']
                ),
                gradient: const LinearGradient(colors: [Color(0xFF03DAC6), Color(0xFF018786)]),
              ),
              const SizedBox(height: 12),
           ],
           
           if (isValidUrl) const SizedBox(height: 12), // Spacer if URL button was shown

          // 3. Common Actions (Copy & Scan Again)
          Row(
            children: [
              Expanded(
                child: ProfessionalButton(
                  label: 'Copy',
                  icon: Icons.copy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: scannedData));
                    if (context.mounted) showToast(context, 'Copied to clipboard!');
                  },
                  gradient: const LinearGradient(colors: [Color(0xFF757575), Color(0xFF616161)]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProfessionalButton(
                  label: l10n.scanAgain,
                  icon: Icons.qr_code_scanner,
                  onPressed: widget.onScanAgain,
                  gradient: const LinearGradient(colors: [Color(0xFFBB86FC), Color(0xFF9F5FFF)]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWiFiInfo(Map<String, String> data, AppLocalizations l10n) {
    return Column(
      children: [
        _buildInfoRow(Icons.wifi, l10n.networkName, data['ssid'] ?? 'Unknown'),
        _buildInfoRow(Icons.security, l10n.security, data['type'] ?? 'Unknown'),
        if (data['password'] != null) _buildInfoRow(Icons.key, 'Password', data['password']!),
      ],
    );
  }

  Widget _buildTextInfo(String data) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        data,
        style: const TextStyle(fontSize: 16, height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF03DAC6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                SelectableText(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
